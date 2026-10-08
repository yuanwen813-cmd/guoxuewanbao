-- Historical local-Worker queue migration. Do not use for new cloud deployments.
-- The current deployment uses ai_cloud_polling_migration.sql instead.
-- Run after ai_report_jobs.sql, points_migration.sql and
-- ai_report_settlement_guard_migration.sql. Pause workers before migration.
begin;

alter table ai_report_jobs add column if not exists started_at timestamptz;
alter table ai_report_jobs add column if not exists deadline_at timestamptz;
alter table ai_report_orders add column if not exists daily_report_date date;

update ai_report_jobs set started_at = created_at,
  deadline_at = created_at + interval '15 minutes'
where status = 'running' and started_at is null;

-- Keep historical duplicates intact; select one canonical report per day.
with ranked as (
  select id, (created_at at time zone 'Asia/Shanghai')::date as report_date,
    row_number() over (partition by user_id,
      (created_at at time zone 'Asia/Shanghai')::date
      order by (status = 'completed') desc, created_at desc, id desc) as position
  from ai_report_orders
  where product_id = 'daily_hexagram_brief' and status in ('generating', 'completed')
)
update ai_report_orders o set daily_report_date = r.report_date
from ranked r where o.id = r.id and r.position = 1 and o.daily_report_date is null
  and not exists (select 1 from ai_report_orders canonical
    where canonical.user_id = o.user_id and canonical.daily_report_date = r.report_date
      and canonical.status in ('generating', 'completed'));

create unique index if not exists idx_daily_ai_report_once
on ai_report_orders(user_id, daily_report_date)
where daily_report_date is not null and status in ('generating', 'completed');

create or replace function expire_ai_report_jobs(p_user_id uuid)
returns integer language plpgsql security definer set search_path = public, pg_temp
as $$
declare v_job ai_report_jobs%rowtype; v_count integer := 0;
begin
  for v_job in
    select j.* from ai_report_jobs j
    join ai_report_orders o on o.id = j.order_id
    where (p_user_id is null or o.user_id = p_user_id) and o.status = 'generating'
      and ((j.status = 'queued' and j.created_at < now() - interval '30 minutes')
        or (j.status = 'running' and j.deadline_at <= now()))
    order by j.created_at limit 20 for update of j skip locked
  loop
    perform refund_ai_report_order(v_job.order_id,
      case when v_job.status = 'running' then 'AI 解析执行超过15分钟，积分已自动退回'
        else 'AI 解析排队超时，积分已自动退回' end, null);
    update ai_report_jobs set status = 'refunded', claim_token = null,
      lease_until = null, updated_at = now() where order_id = v_job.order_id;
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

create or replace function claim_ai_report_job()
returns jsonb language plpgsql security definer set search_path = public, pg_temp
as $$
declare v_job ai_report_jobs%rowtype;
begin
  perform expire_ai_report_jobs(null);
  insert into ai_report_worker_status(id, last_seen_at) values (true, now())
  on conflict (id) do update set last_seen_at = excluded.last_seen_at;
  select * into v_job from ai_report_jobs
  where status = 'queued'
  order by created_at limit 1 for update skip locked;
  if not found then return null; end if;
  -- An abandoned execution is refunded at its deadline, never re-run with a
  -- fresh 15-minute window or a second provider charge.
  update ai_report_jobs set status = 'running', attempts = attempts + 1,
    started_at = now(), deadline_at = now() + interval '15 minutes',
    claim_token = gen_random_uuid(), lease_until = now() + interval '15 minutes',
    updated_at = now() where order_id = v_job.order_id returning * into v_job;
  return to_jsonb(v_job);
end;
$$;

create or replace function heartbeat_ai_report_job(p_order_id uuid, p_claim_token uuid)
returns boolean language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  update ai_report_jobs set updated_at = now()
  where order_id = p_order_id and claim_token = p_claim_token
    and status = 'running' and deadline_at > now();
  if found then
    insert into ai_report_worker_status(id, last_seen_at) values (true, now())
    on conflict (id) do update set last_seen_at = excluded.last_seen_at;
    return true;
  end if;
  return false;
end;
$$;

create or replace function settle_ai_report_job(
  p_order_id uuid, p_claim_token uuid, p_result_text text, p_error_message text,
  p_model text, p_request_tokens integer, p_response_tokens integer
) returns jsonb language plpgsql security definer set search_path = public, pg_temp
as $$
declare v_job ai_report_jobs%rowtype; v_order ai_report_orders%rowtype; v_result jsonb;
begin
  select * into v_job from ai_report_jobs where order_id = p_order_id for update;
  if not found or v_job.status <> 'running'
      or v_job.claim_token is distinct from p_claim_token then
    return jsonb_build_object('settled', false);
  end if;
  select * into v_order from ai_report_orders where id = p_order_id for update;
  if v_order.status <> 'generating' then return jsonb_build_object('settled', false); end if;
  if v_job.deadline_at is null or v_job.deadline_at <= now() then
    v_result := refund_ai_report_order(p_order_id,
      'AI 解析执行超过15分钟，积分已自动退回', p_model);
    update ai_report_jobs set status = 'refunded', updated_at = now() where order_id = p_order_id;
  elsif nullif(btrim(coalesce(p_result_text, ''), E' \t\n\r'), '') is not null then
    v_result := complete_ai_report_order(p_order_id, p_result_text, p_model,
      p_request_tokens, p_response_tokens);
    update ai_report_jobs set status = 'completed', updated_at = now() where order_id = p_order_id;
  else
    v_result := refund_ai_report_order(p_order_id,
      left(coalesce(p_error_message, 'AI 解析失败，积分已自动退回'), 200), p_model);
    update ai_report_jobs set status = 'refunded', updated_at = now() where order_id = p_order_id;
  end if;
  return v_result || jsonb_build_object('settled', true);
end;
$$;

create or replace function start_ai_report_job_once(
  p_user_id uuid, p_product_id text, p_report_type text, p_price_cents bigint,
  p_input_snapshot_json jsonb, p_bazi_chart_json jsonb, p_question_result_json jsonb,
  p_prompt_snapshot text, p_user_prompt text, p_system_prompt text, p_request_id uuid
) returns jsonb language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_existing ai_report_orders%rowtype;
  v_wallet wallets%rowtype;
  v_started jsonb;
  v_today date := (now() at time zone 'Asia/Shanghai')::date;
begin
  if p_request_id is null then raise exception 'REQUEST_ID_REQUIRED'; end if;
  perform expire_ai_report_jobs(p_user_id);
  if p_product_id = 'daily_hexagram_brief' then
    perform pg_advisory_xact_lock(hashtextextended(p_user_id::text || ':daily:' || v_today::text, 0));
    select * into v_existing from ai_report_orders
    where user_id = p_user_id and daily_report_date = v_today
      and status in ('generating', 'completed');
    if found then
      select * into v_wallet from wallets where user_id = p_user_id;
      return jsonb_build_object('order', to_jsonb(v_existing), 'wallet', to_jsonb(v_wallet), 'already_pending', true);
    end if;
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text || ':' || p_request_id::text, 0));
  select * into v_existing from ai_report_orders where user_id = p_user_id and request_id = p_request_id;
  if found then
    if v_existing.product_id <> p_product_id or v_existing.prompt_snapshot is distinct from p_prompt_snapshot then
      raise exception 'REQUEST_ID_CONFLICT';
    end if;
    select * into v_wallet from wallets where user_id = p_user_id;
    return jsonb_build_object('order', to_jsonb(v_existing), 'wallet', to_jsonb(v_wallet), 'already_pending', true);
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text || ':' || p_product_id || ':' || p_prompt_snapshot, 0));
  select * into v_existing from ai_report_orders
  where user_id = p_user_id and product_id = p_product_id
    and prompt_snapshot is not distinct from p_prompt_snapshot
    and (status = 'generating' or (status = 'completed' and created_at > now() - interval '2 minutes'))
  order by created_at desc limit 1;
  if found then
    select * into v_wallet from wallets where user_id = p_user_id;
    return jsonb_build_object('order', to_jsonb(v_existing), 'wallet', to_jsonb(v_wallet), 'already_pending', true);
  end if;
  v_started := start_ai_report_job(p_user_id, p_product_id, p_report_type, p_price_cents,
    p_input_snapshot_json, p_bazi_chart_json, p_question_result_json,
    p_prompt_snapshot, p_user_prompt, p_system_prompt);
  if coalesce((v_started->>'already_pending')::boolean, false) then return v_started; end if;
  update ai_report_orders set request_id = p_request_id,
    daily_report_date = case when p_product_id = 'daily_hexagram_brief' then v_today else null end
  where id = (v_started->'order'->>'id')::uuid returning * into v_existing;
  return jsonb_build_object('order', to_jsonb(v_existing), 'wallet', v_started->'wallet', 'already_pending', false);
end;
$$;

create or replace function get_today_daily_ai_report(p_user_id uuid)
returns jsonb language plpgsql security definer set search_path = public, pg_temp
as $$
declare v_order ai_report_orders%rowtype;
begin
  perform expire_ai_report_jobs(p_user_id);
  perform expire_stale_inline_ai_reports(p_user_id);
  select * into v_order from ai_report_orders
  where user_id = p_user_id and daily_report_date = (now() at time zone 'Asia/Shanghai')::date
    and status in ('generating', 'completed')
  order by (status = 'completed') desc, created_at desc limit 1;
  if not found then return null; end if;
  return to_jsonb(v_order);
end;
$$;

revoke execute on function get_today_daily_ai_report(uuid) from public, anon, authenticated;
grant execute on function get_today_daily_ai_report(uuid) to service_role;
-- CREATE OR REPLACE preserves existing service-role-only permissions.
commit;

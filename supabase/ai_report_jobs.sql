-- Run after schema.sql. Long reports are charged and queued in one transaction.
begin;

create table if not exists ai_report_jobs (
  order_id uuid primary key references ai_report_orders(id) on delete cascade,
  product_id text not null,
  user_prompt text not null,
  system_prompt text not null default '',
  status text not null default 'queued'
    check (status in ('queued', 'running', 'completed', 'refunded')),
  attempts integer not null default 0,
  claim_token uuid,
  lease_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_ai_report_jobs_claim
  on ai_report_jobs(status, lease_until, created_at);

create table if not exists ai_report_worker_status (
  id boolean primary key default true check (id),
  last_seen_at timestamptz not null
);

alter table ai_report_jobs enable row level security;
alter table ai_report_worker_status enable row level security;
revoke all on table ai_report_jobs from public, anon, authenticated;
revoke all on table ai_report_worker_status from public, anon, authenticated;
grant all on table ai_report_jobs to service_role;
grant all on table ai_report_worker_status to service_role;

create or replace function start_ai_report_job(
  p_user_id uuid,
  p_product_id text,
  p_report_type text,
  p_price_cents bigint,
  p_input_snapshot_json jsonb,
  p_bazi_chart_json jsonb,
  p_question_result_json jsonb,
  p_prompt_snapshot text,
  p_user_prompt text,
  p_system_prompt text
) returns jsonb
language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_existing ai_report_orders%rowtype;
  v_wallet wallets%rowtype;
  v_debit jsonb;
begin
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text || ':' || p_product_id, 0));
  select o.* into v_existing
  from ai_report_orders o
  join ai_report_jobs j on j.order_id = o.id
  where o.user_id = p_user_id and o.product_id = p_product_id
    and o.status = 'generating' and j.status in ('queued', 'running')
  order by o.created_at desc limit 1;
  if found then
    if v_existing.prompt_snapshot is distinct from p_prompt_snapshot then
      raise exception 'AI_REPORT_ALREADY_GENERATING';
    end if;
    select * into v_wallet from wallets where user_id = p_user_id;
    return jsonb_build_object('order', to_jsonb(v_existing),
      'wallet', to_jsonb(v_wallet), 'already_pending', true);
  end if;
  if not exists (
    select 1 from ai_report_worker_status
    where id = true and last_seen_at > now() - interval '90 seconds'
  ) then
    raise exception 'AI_WORKER_UNAVAILABLE';
  end if;

  v_debit := create_ai_report_debit(p_user_id, p_product_id, p_report_type,
    p_price_cents, p_input_snapshot_json, p_bazi_chart_json,
    p_question_result_json, p_prompt_snapshot);
  insert into ai_report_jobs(order_id, product_id, user_prompt, system_prompt)
  values ((v_debit->'order'->>'id')::uuid, p_product_id,
    p_user_prompt, coalesce(p_system_prompt, ''));
  return v_debit || jsonb_build_object('already_pending', false);
end;
$$;

create or replace function expire_ai_report_jobs(p_user_id uuid)
returns integer
language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_job ai_report_jobs%rowtype;
  v_count integer := 0;
begin
  for v_job in
    select j.* from ai_report_jobs j
    join ai_report_orders o on o.id = j.order_id
    where (p_user_id is null or o.user_id = p_user_id)
      and o.status = 'generating'
      and ((j.status = 'queued' and j.created_at < now() - interval '30 minutes')
        or (j.status = 'running' and j.lease_until < now()
          and j.created_at < now() - interval '75 minutes'))
    order by j.created_at limit 20 for update of j skip locked
  loop
    perform refund_ai_report_order(v_job.order_id,
      'AI 解析任务未能完成，费用已自动退回', null);
    update ai_report_jobs set status = 'refunded', claim_token = null,
      lease_until = null, updated_at = now() where order_id = v_job.order_id;
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

create or replace function claim_ai_report_job()
returns jsonb
language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_job ai_report_jobs%rowtype;
begin
  perform expire_ai_report_jobs(null);
  insert into ai_report_worker_status(id, last_seen_at) values (true, now())
  on conflict (id) do update set last_seen_at = excluded.last_seen_at;
  -- A crashed worker gets one fresh lease. A second abandoned run is refunded.
  for v_job in
    select * from ai_report_jobs
    where status = 'running' and lease_until < now() and attempts >= 2
    order by lease_until limit 10 for update skip locked
  loop
    perform refund_ai_report_order(v_job.order_id,
      'AI 解析任务中断，费用已自动退回', null);
    update ai_report_jobs set status = 'refunded', claim_token = null,
      lease_until = null, updated_at = now() where order_id = v_job.order_id;
  end loop;

  select * into v_job from ai_report_jobs
  where status = 'queued'
     or (status = 'running' and lease_until < now() and attempts < 2)
  order by created_at limit 1 for update skip locked;
  if not found then return null; end if;

  update ai_report_jobs set status = 'running', attempts = attempts + 1,
    claim_token = gen_random_uuid(), lease_until = now() + interval '35 minutes',
    updated_at = now()
  where order_id = v_job.order_id returning * into v_job;
  return to_jsonb(v_job);
end;
$$;

create or replace function heartbeat_ai_report_job(
  p_order_id uuid, p_claim_token uuid
) returns boolean
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  update ai_report_jobs set lease_until = now() + interval '35 minutes',
    updated_at = now()
  where order_id = p_order_id and claim_token = p_claim_token
    and status = 'running' and lease_until > now();
  if found then
    insert into ai_report_worker_status(id, last_seen_at) values (true, now())
    on conflict (id) do update set last_seen_at = excluded.last_seen_at;
    return true;
  end if;
  return false;
end;
$$;

create or replace function settle_ai_report_job(
  p_order_id uuid,
  p_claim_token uuid,
  p_result_text text,
  p_error_message text,
  p_model text,
  p_request_tokens integer,
  p_response_tokens integer
) returns jsonb
language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_job ai_report_jobs%rowtype;
  v_order ai_report_orders%rowtype;
  v_result jsonb;
begin
  select * into v_job from ai_report_jobs
  where order_id = p_order_id for update;
  if not found or v_job.status <> 'running'
      or v_job.claim_token is distinct from p_claim_token
      or v_job.lease_until <= now() then
    return jsonb_build_object('settled', false);
  end if;
  select * into v_order from ai_report_orders
  where id = p_order_id for update;
  if v_order.status <> 'generating' then
    return jsonb_build_object('settled', false);
  end if;

  if nullif(trim(coalesce(p_result_text, '')), '') is not null then
    v_result := complete_ai_report_order(p_order_id, p_result_text, p_model,
      p_request_tokens, p_response_tokens);
    update ai_report_jobs set status = 'completed', updated_at = now()
      where order_id = p_order_id;
  else
    v_result := refund_ai_report_order(p_order_id,
      left(coalesce(p_error_message, 'AI 解析失败，费用已自动退回'), 200), p_model);
    update ai_report_jobs set status = 'refunded', updated_at = now()
      where order_id = p_order_id;
  end if;
  return v_result || jsonb_build_object('settled', true);
end;
$$;

create or replace function wipe_ai_report_job_prompt()
returns trigger language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  if exists (
    select 1 from ai_report_jobs
    where order_id = new.id and status in ('queued', 'running')
  ) then
    raise exception 'ACTIVE_AI_REPORT_EXISTS';
  end if;
  delete from ai_report_jobs where order_id = new.id;
  return new;
end;
$$;

drop trigger if exists trg_ai_report_job_account_wipe on ai_report_orders;
create trigger trg_ai_report_job_account_wipe
before update of prompt_snapshot on ai_report_orders
for each row
when (old.prompt_snapshot is not null and new.prompt_snapshot is null)
execute function wipe_ai_report_job_prompt();

revoke execute on function start_ai_report_job(uuid, text, text, bigint, jsonb,
  jsonb, jsonb, text, text, text) from public, anon, authenticated;
revoke execute on function claim_ai_report_job() from public, anon, authenticated;
revoke execute on function expire_ai_report_jobs(uuid) from public, anon, authenticated;
revoke execute on function heartbeat_ai_report_job(uuid, uuid) from public, anon, authenticated;
revoke execute on function settle_ai_report_job(uuid, uuid, text, text, text,
  integer, integer) from public, anon, authenticated;
revoke execute on function wipe_ai_report_job_prompt() from public, anon, authenticated;
grant execute on function start_ai_report_job(uuid, text, text, bigint, jsonb,
  jsonb, jsonb, text, text, text) to service_role;
grant execute on function claim_ai_report_job() to service_role;
grant execute on function expire_ai_report_jobs(uuid) to service_role;
grant execute on function heartbeat_ai_report_job(uuid, uuid) to service_role;
grant execute on function settle_ai_report_job(uuid, uuid, text, text, text,
  integer, integer) to service_role;

commit;

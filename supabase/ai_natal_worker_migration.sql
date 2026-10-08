-- Run after ai_cloud_polling_migration.sql, with no active reports or Workers.
-- Only updates Worker lifecycle functions; cloud debit and daily RPCs stay intact.
begin;

alter table public.ai_report_jobs add column if not exists started_at timestamptz;
alter table public.ai_report_jobs add column if not exists deadline_at timestamptz;
update public.ai_report_jobs set
  started_at = coalesce(started_at, created_at),
  deadline_at = coalesce(deadline_at, coalesce(started_at, created_at) + interval '15 minutes')
where status = 'running' and (started_at is null or deadline_at is null);

create or replace function public.expire_ai_report_jobs(p_user_id uuid)
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

create or replace function public.claim_ai_report_job()
returns jsonb language plpgsql security definer set search_path = public, pg_temp
as $$
declare v_job ai_report_jobs%rowtype;
begin
  perform expire_ai_report_jobs(null);
  insert into ai_report_worker_status(id, last_seen_at) values (true, now())
  on conflict (id) do update set last_seen_at = excluded.last_seen_at;
  select j.* into v_job from ai_report_jobs j
  join ai_report_orders o on o.id = j.order_id
  where j.status = 'queued' and o.status = 'generating'
  order by j.created_at limit 1 for update of j skip locked;
  if not found then return null; end if;
  -- Never re-run an abandoned execution with a new time window.
  update ai_report_jobs set status = 'running', attempts = attempts + 1,
    started_at = now(), deadline_at = now() + interval '15 minutes',
    claim_token = gen_random_uuid(), lease_until = now() + interval '15 minutes',
    updated_at = now() where order_id = v_job.order_id returning * into v_job;
  return to_jsonb(v_job);
end;
$$;

create or replace function public.heartbeat_ai_report_job(p_order_id uuid, p_claim_token uuid)
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

create or replace function public.settle_ai_report_job(
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

revoke execute on function public.claim_ai_report_job() from public, anon, authenticated;
revoke execute on function public.expire_ai_report_jobs(uuid) from public, anon, authenticated;
revoke execute on function public.heartbeat_ai_report_job(uuid,uuid) from public, anon, authenticated;
revoke execute on function public.settle_ai_report_job(uuid,uuid,text,text,text,integer,integer)
from public, anon, authenticated;
grant execute on function public.claim_ai_report_job() to service_role;
grant execute on function public.expire_ai_report_jobs(uuid) to service_role;
grant execute on function public.heartbeat_ai_report_job(uuid,uuid) to service_role;
grant execute on function public.settle_ai_report_job(uuid,uuid,text,text,text,integer,integer) to service_role;
commit;

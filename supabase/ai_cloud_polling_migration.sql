-- Run after points_migration.sql and ai_report_settlement_guard_migration.sql.
-- No active reports should be running while this migration is applied.
-- This retains the existing Vercel debit/order path, not the local Worker queue.
begin;

alter table public.ai_report_orders add column if not exists daily_report_date date;

-- Preserve historical reports; only choose a canonical entry for each day.
with ranked as (
  select id, (created_at at time zone 'Asia/Shanghai')::date as report_date,
    row_number() over (partition by user_id,
      (created_at at time zone 'Asia/Shanghai')::date
      order by (status = 'completed') desc, created_at desc, id desc) as position
  from public.ai_report_orders
  where product_id = 'daily_hexagram_brief' and status in ('generating', 'completed')
)
update public.ai_report_orders o set daily_report_date = r.report_date
from ranked r where o.id = r.id and r.position = 1 and o.daily_report_date is null
  and not exists (select 1 from public.ai_report_orders canonical
    where canonical.user_id = o.user_id and canonical.daily_report_date = r.report_date
      and canonical.status in ('generating', 'completed'));

create unique index if not exists idx_daily_ai_report_once
on public.ai_report_orders(user_id, daily_report_date)
where daily_report_date is not null and status in ('generating', 'completed');

create or replace function public.create_ai_report_debit_once(
  p_user_id uuid, p_product_id text, p_report_type text, p_price_cents bigint,
  p_input_snapshot_json jsonb, p_bazi_chart_json jsonb, p_question_result_json jsonb,
  p_prompt_snapshot text, p_request_id uuid
) returns jsonb language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_existing ai_report_orders%rowtype;
  v_wallet wallets%rowtype;
  v_debit jsonb;
  v_today date := (now() at time zone 'Asia/Shanghai')::date;
begin
  if p_request_id is null then raise exception 'REQUEST_ID_REQUIRED'; end if;
  perform expire_stale_inline_ai_reports(p_user_id);
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text || ':' || p_request_id::text, 0));
  select * into v_existing from ai_report_orders
  where user_id = p_user_id and request_id = p_request_id;
  if found then
    if v_existing.product_id <> p_product_id or v_existing.prompt_snapshot is distinct from p_prompt_snapshot then
      raise exception 'REQUEST_ID_CONFLICT';
    end if;
    select * into v_wallet from wallets where user_id = p_user_id;
    return jsonb_build_object('order', to_jsonb(v_existing), 'wallet', to_jsonb(v_wallet), 'already_pending', true);
  end if;
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
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text || ':' || p_product_id || ':' || p_prompt_snapshot, 0));
  select * into v_existing from ai_report_orders
  where user_id = p_user_id and product_id = p_product_id
    and (p_product_id <> 'daily_hexagram_brief' or daily_report_date = v_today)
    and prompt_snapshot is not distinct from p_prompt_snapshot
    and (status = 'generating' or (status = 'completed' and created_at > now() - interval '2 minutes'))
  order by created_at desc limit 1;
  if found then
    select * into v_wallet from wallets where user_id = p_user_id;
    return jsonb_build_object('order', to_jsonb(v_existing), 'wallet', to_jsonb(v_wallet), 'already_pending', true);
  end if;
  v_debit := create_ai_report_debit(p_user_id, p_product_id, p_report_type, p_price_cents,
    p_input_snapshot_json, p_bazi_chart_json, p_question_result_json, p_prompt_snapshot);
  update ai_report_orders set request_id = p_request_id,
    daily_report_date = case when p_product_id = 'daily_hexagram_brief' then v_today else null end
  where id = (v_debit->'order'->>'id')::uuid returning * into v_existing;
  return jsonb_build_object('order', to_jsonb(v_existing), 'wallet', v_debit->'wallet', 'already_pending', false);
end;
$$;

create or replace function public.get_today_daily_ai_report(p_user_id uuid)
returns jsonb language plpgsql security definer set search_path = public, pg_temp
as $$
declare v_order ai_report_orders%rowtype;
begin
  perform expire_stale_inline_ai_reports(p_user_id);
  select * into v_order from ai_report_orders
  where user_id = p_user_id and daily_report_date = (now() at time zone 'Asia/Shanghai')::date
    and status in ('generating', 'completed')
  order by (status = 'completed') desc, created_at desc limit 1;
  if not found then return null; end if;
  return to_jsonb(v_order);
end;
$$;

revoke execute on function public.create_ai_report_debit_once(uuid,text,text,bigint,jsonb,jsonb,jsonb,text,uuid)
from public, anon, authenticated;
grant execute on function public.create_ai_report_debit_once(uuid,text,text,bigint,jsonb,jsonb,jsonb,text,uuid)
to service_role;
revoke execute on function public.get_today_daily_ai_report(uuid) from public, anon, authenticated;
grant execute on function public.get_today_daily_ai_report(uuid) to service_role;
commit;

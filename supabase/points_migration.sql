-- Apply once in Supabase SQL Editor before deploying the points-aware API.
-- Existing *_cents columns remain the integer source of truth: 100 units = 1 point.
-- This preserves fractional legacy balances (for example, CNY 3.90 = 3.90 points).
begin;

do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'app_users'
      and column_name = 'registration_bonus_eligible'
  ) then
    alter table public.app_users
      add column registration_bonus_eligible boolean not null default true;
    -- Accounts already present at migration time are not newly registered.
    update public.app_users set registration_bonus_eligible = false;
  end if;
end;
$$;

alter table public.app_users
  add column if not exists registration_bonus_claimed_at timestamptz;

update public.app_users u
set registration_bonus_claimed_at = t.created_at
from public.wallet_transactions t
where t.user_id = u.id
  and t.ref_id like 'registration_bonus_before_20260730:%'
  and u.registration_bonus_claimed_at is null;

alter table public.wallets
  add column if not exists points_balance numeric(18,2)
  generated always as (balance_cents::numeric / 100) stored;

alter table public.ai_report_orders
  add column if not exists request_id uuid;
alter table public.ai_report_orders
  add column if not exists charge_unit text not null default 'CNY';
alter table public.ai_report_orders
  alter column charge_unit set default 'POINTS';
alter table public.ai_report_orders
  add column if not exists price_points numeric(18,2)
  generated always as (price_cents::numeric / 100) stored;
create unique index if not exists ai_report_user_request_once
  on public.ai_report_orders(user_id, request_id)
  where request_id is not null;
create index if not exists ai_report_recent_same_prompt
  on public.ai_report_orders(user_id, product_id, status, created_at desc);

create table if not exists public.points_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.app_users(id) on delete restrict,
  wallet_id uuid not null references public.wallets(id) on delete restrict,
  wallet_transaction_id uuid unique references public.wallet_transactions(id) on delete restrict,
  change_amount numeric(18,2) not null,
  balance_before numeric(18,2) not null,
  balance_after numeric(18,2) not null,
  transaction_type text not null check (transaction_type in
    ('REGISTER_BONUS', 'RECHARGE', 'ANALYSIS_COST', 'REFUND', 'ADMIN_ADJUST',
      'MIGRATION_OPENING')),
  source text not null,
  related_order_id text,
  description text,
  created_at timestamptz not null default now(),
  check ((balance_before >= 0 or transaction_type = 'MIGRATION_OPENING')
    and balance_after >= 0),
  check (balance_before + change_amount = balance_after)
);

create unique index if not exists points_registration_bonus_once
  on public.points_transactions(user_id)
  where transaction_type = 'REGISTER_BONUS';
create index if not exists points_transactions_user_created
  on public.points_transactions(user_id, created_at desc);
create unique index if not exists points_legacy_opening_once
  on public.points_transactions(user_id, source)
  where source = 'legacy_balance_reconciliation';

create or replace function public.record_points_transaction()
returns trigger language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_type text;
begin
  v_type := case
    when new.ref_id like 'registration_bonus:%'
      or new.ref_id like 'registration_bonus_before_20260730:%'
      then 'REGISTER_BONUS'
    when new.type = 'recharge' then 'RECHARGE'
    when new.type = 'ai_debit' then 'ANALYSIS_COST'
    when new.type = 'ai_refund' then 'REFUND'
    else 'ADMIN_ADJUST'
  end;
  insert into public.points_transactions(
    user_id, wallet_id, wallet_transaction_id, change_amount,
    balance_before, balance_after, transaction_type, source,
    related_order_id, description, created_at
  ) values (
    new.user_id, new.wallet_id, new.id,
    new.amount_cents::numeric / 100,
    (new.balance_after_cents - new.amount_cents)::numeric / 100,
    new.balance_after_cents::numeric / 100,
    v_type, coalesce(new.ref_type, new.type), new.ref_id, new.note, new.created_at
  ) on conflict (wallet_transaction_id) do nothing;
  return new;
end;
$$;

insert into public.points_transactions(
  user_id, wallet_id, wallet_transaction_id, change_amount,
  balance_before, balance_after, transaction_type, source,
  related_order_id, description, created_at
)
select t.user_id, t.wallet_id, t.id, t.amount_cents::numeric / 100,
  (t.balance_after_cents - t.amount_cents)::numeric / 100,
  t.balance_after_cents::numeric / 100,
  case
    when t.ref_id like 'registration_bonus:%'
      or t.ref_id like 'registration_bonus_before_20260730:%'
      then 'REGISTER_BONUS'
    when t.type = 'recharge' then 'RECHARGE'
    when t.type = 'ai_debit' then 'ANALYSIS_COST'
    when t.type = 'ai_refund' then 'REFUND'
    else 'ADMIN_ADJUST'
  end,
  coalesce(t.ref_type, t.type), t.ref_id, t.note, t.created_at
from public.wallet_transactions t
on conflict (wallet_transaction_id) do nothing;

-- Some historical wallets have an opening balance that predates the old
-- wallet_transactions ledger. Represent the difference without changing the
-- wallet or rewriting any payment order.
insert into public.points_transactions(
  user_id, wallet_id, wallet_transaction_id, change_amount,
  balance_before, balance_after, transaction_type, source,
  related_order_id, description, created_at
)
select w.user_id, w.id, null,
  (w.balance_cents - coalesce(t.ledger_cents, 0))::numeric / 100,
  coalesce(t.ledger_cents, 0)::numeric / 100,
  w.balance_cents::numeric / 100,
  'MIGRATION_OPENING', 'legacy_balance_reconciliation', w.id::text,
  '历史期初余额对账，不是新充值或新赠送', now()
from public.wallets w
left join (
  select wallet_id, sum(amount_cents) as ledger_cents
  from public.wallet_transactions group by wallet_id
) t on t.wallet_id = w.id
where w.balance_cents <> coalesce(t.ledger_cents, 0)
on conflict (user_id, source)
  where source = 'legacy_balance_reconciliation' do nothing;

drop trigger if exists wallet_transaction_points on public.wallet_transactions;
create trigger wallet_transaction_points
after insert on public.wallet_transactions
for each row execute function public.record_points_transaction();

-- New registrations only. Old accounts remain ineligible unless deliberately
-- marked eligible after an explicit audit of their historical bonus state.
create or replace function public.grant_registration_bonus(p_user_id uuid)
returns jsonb language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_user app_users%rowtype;
  v_wallet wallets%rowtype;
  v_transaction wallet_transactions%rowtype;
begin
  select * into v_user from app_users where id = p_user_id for update;
  if not found then raise exception 'USER_NOT_FOUND'; end if;

  select * into v_wallet from wallets where user_id = p_user_id for update;
  if not found then raise exception 'WALLET_NOT_FOUND'; end if;

  if not v_user.registration_bonus_eligible
      or v_user.registration_bonus_claimed_at is not null then
    return jsonb_build_object('eligible', v_user.registration_bonus_eligible,
      'granted', false, 'already_granted',
      v_user.registration_bonus_claimed_at is not null,
      'wallet', to_jsonb(v_wallet));
  end if;

  -- The partial unique index is a second barrier against duplicate grants.
  if exists (select 1 from points_transactions
      where user_id = p_user_id and transaction_type = 'REGISTER_BONUS') then
    update app_users set registration_bonus_claimed_at = now()
    where id = p_user_id;
    return jsonb_build_object('eligible', true, 'granted', false,
      'already_granted', true, 'wallet', to_jsonb(v_wallet));
  end if;

  update wallets set balance_cents = balance_cents + 1000
  where id = v_wallet.id returning * into v_wallet;
  insert into wallet_transactions(user_id, wallet_id, type, amount_cents,
    balance_after_cents, currency, ref_type, ref_id, note)
  values (p_user_id, v_wallet.id, 'manual_adjust', 1000,
    v_wallet.balance_cents, v_wallet.currency, 'admin_adjust',
    'registration_bonus:' || p_user_id::text, '注册赠送 10 积分')
  returning * into v_transaction;
  update app_users set registration_bonus_claimed_at = now() where id = p_user_id;
  return jsonb_build_object('eligible', true, 'granted', true,
    'already_granted', false, 'wallet', to_jsonb(v_wallet),
    'transaction', to_jsonb(v_transaction));
end;
$$;

-- Keep the legacy debit RPC for already deployed clients; new clients use the
-- idempotent wrapper. It still creates the report and debits under one lock.
create or replace function public.create_ai_report_debit_once(
  p_user_id uuid,
  p_product_id text,
  p_report_type text,
  p_price_cents bigint,
  p_input_snapshot_json jsonb,
  p_bazi_chart_json jsonb,
  p_question_result_json jsonb,
  p_prompt_snapshot text,
  p_request_id uuid
) returns jsonb language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_existing ai_report_orders%rowtype;
  v_wallet wallets%rowtype;
  v_debit jsonb;
begin
  if p_request_id is null then raise exception 'REQUEST_ID_REQUIRED'; end if;
  perform pg_advisory_xact_lock(hashtextextended(
    p_user_id::text || ':' || p_request_id::text, 0));
  select * into v_existing from ai_report_orders
  where user_id = p_user_id and request_id = p_request_id;
  if found then
    if v_existing.product_id <> p_product_id
        or v_existing.prompt_snapshot is distinct from p_prompt_snapshot then
      raise exception 'REQUEST_ID_CONFLICT';
    end if;
    select * into v_wallet from wallets where user_id = p_user_id;
    return jsonb_build_object('order', to_jsonb(v_existing),
      'wallet', to_jsonb(v_wallet), 'already_pending', true);
  end if;
  perform pg_advisory_xact_lock(hashtextextended(
    p_user_id::text || ':' || p_product_id || ':' || p_prompt_snapshot, 0));
  select * into v_existing from ai_report_orders
  where user_id = p_user_id and product_id = p_product_id
    and prompt_snapshot is not distinct from p_prompt_snapshot
    and (status = 'generating'
      or (status = 'completed' and created_at > now() - interval '2 minutes'))
  order by created_at desc limit 1;
  if found then
    select * into v_wallet from wallets where user_id = p_user_id;
    return jsonb_build_object('order', to_jsonb(v_existing),
      'wallet', to_jsonb(v_wallet), 'already_pending', true);
  end if;
  v_debit := create_ai_report_debit(p_user_id, p_product_id, p_report_type,
    p_price_cents, p_input_snapshot_json, p_bazi_chart_json,
    p_question_result_json, p_prompt_snapshot);
  update ai_report_orders set request_id = p_request_id
  where id = (v_debit->'order'->>'id')::uuid returning * into v_existing;
  return jsonb_build_object('order', to_jsonb(v_existing),
    'wallet', v_debit->'wallet', 'already_pending', false);
end;
$$;

create or replace function public.start_ai_report_job_once(
  p_user_id uuid,
  p_product_id text,
  p_report_type text,
  p_price_cents bigint,
  p_input_snapshot_json jsonb,
  p_bazi_chart_json jsonb,
  p_question_result_json jsonb,
  p_prompt_snapshot text,
  p_user_prompt text,
  p_system_prompt text,
  p_request_id uuid
) returns jsonb language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_existing ai_report_orders%rowtype;
  v_wallet wallets%rowtype;
  v_started jsonb;
begin
  if p_request_id is null then raise exception 'REQUEST_ID_REQUIRED'; end if;
  perform pg_advisory_xact_lock(hashtextextended(
    p_user_id::text || ':' || p_request_id::text, 0));
  select * into v_existing from ai_report_orders
  where user_id = p_user_id and request_id = p_request_id;
  if found then
    if v_existing.product_id <> p_product_id
        or v_existing.prompt_snapshot is distinct from p_prompt_snapshot then
      raise exception 'REQUEST_ID_CONFLICT';
    end if;
    select * into v_wallet from wallets where user_id = p_user_id;
    return jsonb_build_object('order', to_jsonb(v_existing),
      'wallet', to_jsonb(v_wallet), 'already_pending', true);
  end if;
  perform pg_advisory_xact_lock(hashtextextended(
    p_user_id::text || ':' || p_product_id || ':' || p_prompt_snapshot, 0));
  select * into v_existing from ai_report_orders
  where user_id = p_user_id and product_id = p_product_id
    and prompt_snapshot is not distinct from p_prompt_snapshot
    and (status = 'generating'
      or (status = 'completed' and created_at > now() - interval '2 minutes'))
  order by created_at desc limit 1;
  if found then
    select * into v_wallet from wallets where user_id = p_user_id;
    return jsonb_build_object('order', to_jsonb(v_existing),
      'wallet', to_jsonb(v_wallet), 'already_pending', true);
  end if;
  v_started := start_ai_report_job(p_user_id, p_product_id, p_report_type,
    p_price_cents, p_input_snapshot_json, p_bazi_chart_json,
    p_question_result_json, p_prompt_snapshot, p_user_prompt, p_system_prompt);
  if coalesce((v_started->>'already_pending')::boolean, false) then
    return v_started;
  end if;
  update ai_report_orders set request_id = p_request_id
  where id = (v_started->'order'->>'id')::uuid returning * into v_existing;
  return jsonb_build_object('order', to_jsonb(v_existing),
    'wallet', v_started->'wallet',
    'already_pending', coalesce((v_started->>'already_pending')::boolean, false));
end;
$$;

-- A killed Vercel function cannot run its catch/refund branch. Reconcile its
-- inline report once its maximum execution window has definitely passed.
create or replace function public.expire_stale_inline_ai_reports(p_user_id uuid)
returns integer language plpgsql security definer set search_path = public, pg_temp
as $$
declare
  v_order ai_report_orders%rowtype;
  v_count integer := 0;
begin
  for v_order in
    select o.* from ai_report_orders o
    where (p_user_id is null or o.user_id = p_user_id)
      and o.status = 'generating'
      and o.created_at < now() - interval '15 minutes'
      and not exists (select 1 from ai_report_jobs j where j.order_id = o.id)
    order by o.created_at limit 20 for update of o skip locked
  loop
    perform refund_ai_report_order(v_order.id,
      'AI 解析任务未完成，积分已自动退回', null);
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

alter table public.points_transactions enable row level security;
revoke all on table public.points_transactions from public, anon, authenticated;
grant all on table public.points_transactions to service_role;
revoke execute on function public.record_points_transaction() from public, anon, authenticated;
revoke execute on function public.grant_registration_bonus(uuid) from public, anon, authenticated;
grant execute on function public.grant_registration_bonus(uuid) to service_role;
revoke execute on function public.create_ai_report_debit_once(uuid, text, text, bigint,
  jsonb, jsonb, jsonb, text, uuid) from public, anon, authenticated;
revoke execute on function public.start_ai_report_job_once(uuid, text, text, bigint,
  jsonb, jsonb, jsonb, text, text, text, uuid) from public, anon, authenticated;
grant execute on function public.create_ai_report_debit_once(uuid, text, text, bigint,
  jsonb, jsonb, jsonb, text, uuid) to service_role;
grant execute on function public.start_ai_report_job_once(uuid, text, text, bigint,
  jsonb, jsonb, jsonb, text, text, text, uuid) to service_role;
revoke execute on function public.expire_stale_inline_ai_reports(uuid)
  from public, anon, authenticated;
grant execute on function public.expire_stale_inline_ai_reports(uuid) to service_role;

commit;

-- Read-only checks after commit:
-- select count(*) from points_transactions;
-- select count(*) from wallet_transactions;
-- select id, balance_cents, points_balance from wallets limit 10;

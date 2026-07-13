create extension if not exists pgcrypto;

create table if not exists app_users (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique not null,
  phone text unique,
  nickname text,
  avatar_url text,
  status text not null default 'active' check (status in ('active', 'disabled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references app_users(id) on delete restrict,
  balance_cents bigint not null default 0 check (balance_cents >= 0),
  currency text not null default 'CNY',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists sms_login_codes (
  id uuid primary key default gen_random_uuid(),
  phone text not null,
  code_hash text not null,
  provider text not null default 'aliyun',
  provider_request_id text,
  provider_biz_id text,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  attempts integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists sms_send_attempts (
  id uuid primary key default gen_random_uuid(),
  phone text not null,
  client_ip text,
  user_agent text,
  status text not null default 'pending' check (status in ('pending', 'sent', 'failed', 'blocked')),
  provider_request_id text,
  provider_biz_id text,
  error_message text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references app_users(id) on delete restrict,
  wallet_id uuid not null references wallets(id) on delete restrict,
  type text not null check (type in ('recharge', 'ai_debit', 'ai_refund', 'manual_adjust')),
  amount_cents bigint not null,
  balance_after_cents bigint not null,
  currency text not null default 'CNY',
  ref_type text check (ref_type is null or ref_type in ('recharge_order', 'ai_report_order', 'admin_adjust')),
  ref_id text,
  out_trade_no text,
  note text,
  created_at timestamptz not null default now(),
  unique(ref_type, ref_id, type)
);

create table if not exists recharge_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references app_users(id) on delete restrict,
  out_trade_no text unique not null,
  provider text not null check (provider in ('wechat', 'alipay')),
  trade_type text not null check (trade_type in ('web_native', 'web_pc', 'qr', 'h5', 'app', 'mini_program')),
  amount_cents bigint not null check (amount_cents >= 100),
  currency text not null default 'CNY',
  status text not null default 'pending' check (status in ('pending', 'paid', 'closed', 'failed', 'refunded')),
  provider_trade_no text,
  prepay_id text,
  code_url text,
  pay_url text,
  raw_create_response jsonb,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists ai_report_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references app_users(id) on delete restrict,
  product_id text not null,
  report_type text not null,
  price_cents bigint not null check (price_cents >= 0),
  currency text not null default 'CNY',
  status text not null default 'pending' check (status in ('pending', 'generating', 'completed', 'failed', 'refunded')),
  input_snapshot_json jsonb,
  bazi_chart_json jsonb,
  question_result_json jsonb,
  prompt_snapshot text,
  result_text text,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists payment_notify_logs (
  id uuid primary key default gen_random_uuid(),
  provider text not null check (provider in ('wechat', 'alipay')),
  out_trade_no text,
  provider_trade_no text,
  headers_json jsonb,
  raw_body text,
  parsed_json jsonb,
  verified boolean not null default false,
  handled boolean not null default false,
  error_message text,
  created_at timestamptz not null default now()
);

create table if not exists ai_call_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references app_users(id) on delete set null,
  ai_report_order_id uuid references ai_report_orders(id) on delete set null,
  provider text not null default 'deepseek',
  model text,
  request_tokens integer,
  response_tokens integer,
  success boolean,
  error_message text,
  created_at timestamptz not null default now()
);

create table if not exists admin_users (
  id uuid primary key default gen_random_uuid(),
  phone text unique not null,
  name text,
  role text not null default 'viewer' check (role in ('super_admin', 'finance', 'support', 'content', 'viewer')),
  permissions jsonb not null default '[]'::jsonb,
  status text not null default 'active' check (status in ('active', 'disabled')),
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  admin_user_id uuid references admin_users(id) on delete set null,
  admin_phone text,
  action text not null,
  target_type text,
  target_id text,
  detail_json jsonb not null default '{}'::jsonb,
  client_ip text,
  user_agent text,
  created_at timestamptz not null default now()
);

create index if not exists idx_wallet_transactions_user_time
  on wallet_transactions(user_id, created_at desc);

create index if not exists idx_recharge_orders_user_time
  on recharge_orders(user_id, created_at desc);

create index if not exists idx_ai_report_orders_user_time
  on ai_report_orders(user_id, created_at desc);

create index if not exists idx_sms_login_codes_phone_time
  on sms_login_codes(phone, created_at desc);

create index if not exists idx_sms_login_codes_active
  on sms_login_codes(phone, expires_at desc)
  where consumed_at is null;

create index if not exists idx_sms_send_attempts_phone_time
  on sms_send_attempts(phone, created_at desc);

create index if not exists idx_sms_send_attempts_ip_time
  on sms_send_attempts(client_ip, created_at desc);

create index if not exists idx_sms_send_attempts_time
  on sms_send_attempts(created_at desc);

create index if not exists idx_admin_users_phone
  on admin_users(phone);

create index if not exists idx_admin_audit_logs_time
  on admin_audit_logs(created_at desc);

create index if not exists idx_admin_audit_logs_target
  on admin_audit_logs(target_type, target_id, created_at desc);

create or replace function touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_app_users_touch_updated_at on app_users;
create trigger trg_app_users_touch_updated_at
before update on app_users
for each row execute function touch_updated_at();

drop trigger if exists trg_wallets_touch_updated_at on wallets;
create trigger trg_wallets_touch_updated_at
before update on wallets
for each row execute function touch_updated_at();

drop trigger if exists trg_recharge_orders_touch_updated_at on recharge_orders;
create trigger trg_recharge_orders_touch_updated_at
before update on recharge_orders
for each row execute function touch_updated_at();

drop trigger if exists trg_ai_report_orders_touch_updated_at on ai_report_orders;
create trigger trg_ai_report_orders_touch_updated_at
before update on ai_report_orders
for each row execute function touch_updated_at();

drop trigger if exists trg_admin_users_touch_updated_at on admin_users;
create trigger trg_admin_users_touch_updated_at
before update on admin_users
for each row execute function touch_updated_at();

create or replace function ensure_app_user(
  p_auth_user_id uuid,
  p_phone text
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_user app_users%rowtype;
  v_wallet wallets%rowtype;
begin
  insert into app_users(auth_user_id, phone)
  values (p_auth_user_id, p_phone)
  on conflict (auth_user_id) do update
    set phone = coalesce(excluded.phone, app_users.phone)
  returning * into v_user;

  insert into wallets(user_id)
  values (v_user.id)
  on conflict (user_id) do update
    set updated_at = wallets.updated_at
  returning * into v_wallet;

  return jsonb_build_object(
    'user', to_jsonb(v_user),
    'wallet', to_jsonb(v_wallet)
  );
end;
$$;

create or replace function grant_registration_bonus(
  p_user_id uuid
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_user app_users%rowtype;
  v_wallet wallets%rowtype;
  v_transaction wallet_transactions%rowtype;
  v_amount_cents bigint := 1000;
  v_cutoff_exclusive timestamptz := '2026-07-30 16:00:00+00';
  v_ref_id text;
begin
  select * into v_user
  from app_users
  where id = p_user_id
  for update;

  if not found then
    raise exception 'USER_NOT_FOUND';
  end if;

  insert into wallets(user_id)
  values (v_user.id)
  on conflict (user_id) do update
    set updated_at = wallets.updated_at
  returning * into v_wallet;

  v_ref_id := 'registration_bonus_before_20260730:' || v_user.id::text;

  select * into v_transaction
  from wallet_transactions
  where user_id = v_user.id
    and type = 'manual_adjust'
    and ref_type = 'admin_adjust'
    and ref_id = v_ref_id
  limit 1;

  if found then
    return jsonb_build_object(
      'eligible', v_user.created_at < v_cutoff_exclusive,
      'granted', false,
      'already_granted', true,
      'wallet', to_jsonb(v_wallet),
      'transaction', to_jsonb(v_transaction)
    );
  end if;

  if v_user.created_at >= v_cutoff_exclusive then
    return jsonb_build_object(
      'eligible', false,
      'granted', false,
      'already_granted', false,
      'wallet', to_jsonb(v_wallet)
    );
  end if;

  update wallets
  set balance_cents = balance_cents + v_amount_cents,
      updated_at = now()
  where id = v_wallet.id
  returning * into v_wallet;

  insert into wallet_transactions(
    user_id,
    wallet_id,
    type,
    amount_cents,
    balance_after_cents,
    currency,
    ref_type,
    ref_id,
    note
  )
  values (
    v_user.id,
    v_wallet.id,
    'manual_adjust',
    v_amount_cents,
    v_wallet.balance_cents,
    v_wallet.currency,
    'admin_adjust',
    v_ref_id,
    '2026年7月30日前注册赠送余额'
  )
  returning * into v_transaction;

  return jsonb_build_object(
    'eligible', true,
    'granted', true,
    'already_granted', false,
    'wallet', to_jsonb(v_wallet),
    'transaction', to_jsonb(v_transaction)
  );
end;
$$;

create or replace function create_recharge_order(
  p_user_id uuid,
  p_provider text,
  p_trade_type text,
  p_amount_cents bigint,
  p_out_trade_no text
) returns recharge_orders
language plpgsql
security definer
as $$
declare
  v_order recharge_orders%rowtype;
begin
  insert into recharge_orders(
    user_id,
    provider,
    trade_type,
    amount_cents,
    out_trade_no
  )
  values (
    p_user_id,
    p_provider,
    p_trade_type,
    p_amount_cents,
    p_out_trade_no
  )
  returning * into v_order;
  return v_order;
end;
$$;

create or replace function mark_recharge_paid(
  p_out_trade_no text,
  p_provider_trade_no text,
  p_amount_cents bigint,
  p_notify_log_id uuid,
  p_raw_payload jsonb
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_order recharge_orders%rowtype;
  v_wallet wallets%rowtype;
  v_already_paid boolean := false;
begin
  select * into v_order
  from recharge_orders
  where out_trade_no = p_out_trade_no
  for update;

  if not found then
    raise exception 'RECHARGE_ORDER_NOT_FOUND';
  end if;

  if v_order.amount_cents <> p_amount_cents then
    raise exception 'RECHARGE_AMOUNT_MISMATCH';
  end if;

  if v_order.status = 'paid' then
    v_already_paid := true;
    select * into v_wallet from wallets where user_id = v_order.user_id;
    return jsonb_build_object(
      'order', to_jsonb(v_order),
      'wallet', to_jsonb(v_wallet),
      'already_paid', v_already_paid
    );
  end if;

  select * into v_wallet
  from wallets
  where user_id = v_order.user_id
  for update;

  update recharge_orders
  set status = 'paid',
      provider_trade_no = p_provider_trade_no,
      paid_at = now(),
      updated_at = now()
  where id = v_order.id
  returning * into v_order;

  update wallets
  set balance_cents = balance_cents + v_order.amount_cents,
      updated_at = now()
  where id = v_wallet.id
  returning * into v_wallet;

  insert into wallet_transactions(
    user_id,
    wallet_id,
    type,
    amount_cents,
    balance_after_cents,
    currency,
    ref_type,
    ref_id,
    out_trade_no,
    note
  )
  values (
    v_order.user_id,
    v_wallet.id,
    'recharge',
    v_order.amount_cents,
    v_wallet.balance_cents,
    v_wallet.currency,
    'recharge_order',
    v_order.id::text,
    v_order.out_trade_no,
    '余额充值'
  )
  on conflict (ref_type, ref_id, type) do nothing;

  if p_notify_log_id is not null then
    update payment_notify_logs
    set out_trade_no = v_order.out_trade_no,
        provider_trade_no = p_provider_trade_no,
        parsed_json = coalesce(parsed_json, '{}'::jsonb) || coalesce(p_raw_payload, '{}'::jsonb),
        verified = true,
        handled = true
    where id = p_notify_log_id;
  end if;

  return jsonb_build_object(
    'order', to_jsonb(v_order),
    'wallet', to_jsonb(v_wallet),
    'already_paid', v_already_paid
  );
end;
$$;

create or replace function create_ai_report_debit(
  p_user_id uuid,
  p_product_id text,
  p_report_type text,
  p_price_cents bigint,
  p_input_snapshot_json jsonb,
  p_bazi_chart_json jsonb,
  p_question_result_json jsonb,
  p_prompt_snapshot text
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_wallet wallets%rowtype;
  v_order ai_report_orders%rowtype;
begin
  select * into v_wallet
  from wallets
  where user_id = p_user_id
  for update;

  if not found then
    raise exception 'WALLET_NOT_FOUND';
  end if;

  if v_wallet.balance_cents < p_price_cents then
    raise exception 'INSUFFICIENT_BALANCE';
  end if;

  insert into ai_report_orders(
    user_id,
    product_id,
    report_type,
    price_cents,
    status,
    input_snapshot_json,
    bazi_chart_json,
    question_result_json,
    prompt_snapshot
  )
  values (
    p_user_id,
    p_product_id,
    p_report_type,
    p_price_cents,
    'generating',
    coalesce(p_input_snapshot_json, '{}'::jsonb),
    coalesce(p_bazi_chart_json, '{}'::jsonb),
    coalesce(p_question_result_json, '{}'::jsonb),
    p_prompt_snapshot
  )
  returning * into v_order;

  update wallets
  set balance_cents = balance_cents - p_price_cents,
      updated_at = now()
  where id = v_wallet.id
  returning * into v_wallet;

  insert into wallet_transactions(
    user_id,
    wallet_id,
    type,
    amount_cents,
    balance_after_cents,
    currency,
    ref_type,
    ref_id,
    note
  )
  values (
    p_user_id,
    v_wallet.id,
    'ai_debit',
    -p_price_cents,
    v_wallet.balance_cents,
    v_wallet.currency,
    'ai_report_order',
    v_order.id::text,
    'AI 解析扣费'
  );

  return jsonb_build_object(
    'order', to_jsonb(v_order),
    'wallet', to_jsonb(v_wallet)
  );
end;
$$;

create or replace function complete_ai_report_order(
  p_order_id uuid,
  p_result_text text,
  p_model text,
  p_request_tokens integer,
  p_response_tokens integer
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_order ai_report_orders%rowtype;
  v_wallet wallets%rowtype;
begin
  select * into v_order
  from ai_report_orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'AI_REPORT_ORDER_NOT_FOUND';
  end if;

  update ai_report_orders
  set status = 'completed',
      result_text = p_result_text,
      updated_at = now()
  where id = p_order_id
  returning * into v_order;

  insert into ai_call_logs(
    user_id,
    ai_report_order_id,
    provider,
    model,
    request_tokens,
    response_tokens,
    success
  )
  values (
    v_order.user_id,
    v_order.id,
    'deepseek',
    p_model,
    p_request_tokens,
    p_response_tokens,
    true
  );

  select * into v_wallet from wallets where user_id = v_order.user_id;

  return jsonb_build_object(
    'order', to_jsonb(v_order),
    'wallet', to_jsonb(v_wallet)
  );
end;
$$;

create or replace function refund_ai_report_order(
  p_order_id uuid,
  p_error_message text,
  p_model text
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_order ai_report_orders%rowtype;
  v_wallet wallets%rowtype;
  v_already_refunded boolean := false;
begin
  select * into v_order
  from ai_report_orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'AI_REPORT_ORDER_NOT_FOUND';
  end if;

  if v_order.status in ('failed', 'refunded') then
    v_already_refunded := true;
    select * into v_wallet from wallets where user_id = v_order.user_id;
    return jsonb_build_object(
      'order', to_jsonb(v_order),
      'wallet', to_jsonb(v_wallet),
      'already_refunded', v_already_refunded
    );
  end if;

  select * into v_wallet
  from wallets
  where user_id = v_order.user_id
  for update;

  update wallets
  set balance_cents = balance_cents + v_order.price_cents,
      updated_at = now()
  where id = v_wallet.id
  returning * into v_wallet;

  update ai_report_orders
  set status = 'refunded',
      error_message = p_error_message,
      updated_at = now()
  where id = p_order_id
  returning * into v_order;

  insert into wallet_transactions(
    user_id,
    wallet_id,
    type,
    amount_cents,
    balance_after_cents,
    currency,
    ref_type,
    ref_id,
    note
  )
  values (
    v_order.user_id,
    v_wallet.id,
    'ai_refund',
    v_order.price_cents,
    v_wallet.balance_cents,
    v_wallet.currency,
    'ai_report_order',
    v_order.id::text,
    'AI 解析失败自动退款'
  )
  on conflict (ref_type, ref_id, type) do nothing;

  insert into ai_call_logs(
    user_id,
    ai_report_order_id,
    provider,
    model,
    success,
    error_message
  )
  values (
    v_order.user_id,
    v_order.id,
    'deepseek',
    p_model,
    false,
    p_error_message
  );

  return jsonb_build_object(
    'order', to_jsonb(v_order),
    'wallet', to_jsonb(v_wallet),
    'already_refunded', v_already_refunded
  );
end;
$$;

create or replace function admin_adjust_wallet(
  p_admin_user_id uuid,
  p_admin_phone text,
  p_user_id uuid,
  p_amount_cents bigint,
  p_reason text,
  p_request_id text,
  p_client_ip text,
  p_user_agent text
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_user app_users%rowtype;
  v_wallet wallets%rowtype;
  v_transaction wallet_transactions%rowtype;
  v_ref_id text;
begin
  if p_user_id is null then
    raise exception 'USER_ID_REQUIRED';
  end if;

  if p_amount_cents = 0 then
    raise exception 'ADJUST_AMOUNT_ZERO';
  end if;

  if length(trim(coalesce(p_reason, ''))) < 4 then
    raise exception 'ADJUST_REASON_REQUIRED';
  end if;

  v_ref_id := 'admin_adjust:' || coalesce(nullif(p_request_id, ''), gen_random_uuid()::text);

  select * into v_transaction
  from wallet_transactions
  where ref_type = 'admin_adjust'
    and ref_id = v_ref_id
    and type = 'manual_adjust'
  limit 1;

  if found then
    select * into v_wallet
    from wallets
    where id = v_transaction.wallet_id;

    return jsonb_build_object(
      'wallet', to_jsonb(v_wallet),
      'transaction', to_jsonb(v_transaction),
      'already_applied', true
    );
  end if;

  select * into v_user
  from app_users
  where id = p_user_id
  for update;

  if not found then
    raise exception 'USER_NOT_FOUND';
  end if;

  select * into v_wallet
  from wallets
  where user_id = p_user_id
  for update;

  if not found then
    raise exception 'WALLET_NOT_FOUND';
  end if;

  if v_wallet.balance_cents + p_amount_cents < 0 then
    raise exception 'WALLET_BALANCE_NOT_ENOUGH';
  end if;

  update wallets
  set balance_cents = balance_cents + p_amount_cents,
      updated_at = now()
  where id = v_wallet.id
  returning * into v_wallet;

  insert into wallet_transactions(
    user_id,
    wallet_id,
    type,
    amount_cents,
    balance_after_cents,
    currency,
    ref_type,
    ref_id,
    note
  )
  values (
    p_user_id,
    v_wallet.id,
    'manual_adjust',
    p_amount_cents,
    v_wallet.balance_cents,
    v_wallet.currency,
    'admin_adjust',
    v_ref_id,
    p_reason
  )
  returning * into v_transaction;

  insert into admin_audit_logs(
    admin_user_id,
    admin_phone,
    action,
    target_type,
    target_id,
    detail_json,
    client_ip,
    user_agent
  )
  values (
    p_admin_user_id,
    p_admin_phone,
    'wallet.adjust',
    'app_user',
    p_user_id::text,
    jsonb_build_object(
      'amount_cents', p_amount_cents,
      'reason', p_reason,
      'wallet_transaction_id', v_transaction.id,
      'balance_after_cents', v_wallet.balance_cents,
      'request_id', p_request_id
    ),
    p_client_ip,
    p_user_agent
  );

  return jsonb_build_object(
    'wallet', to_jsonb(v_wallet),
    'transaction', to_jsonb(v_transaction),
    'already_applied', false
  );
end;
$$;

create or replace function admin_dashboard_summary()
returns jsonb
language plpgsql
security definer
as $$
declare
  v_users bigint;
  v_wallet_balance bigint;
  v_paid_recharge_orders bigint;
  v_paid_recharge_cents bigint;
  v_pending_recharge_orders bigint;
  v_completed_ai_reports bigint;
  v_ai_revenue_cents bigint;
  v_failed_or_refunded_ai_reports bigint;
begin
  select count(*) into v_users from app_users;
  select coalesce(sum(balance_cents), 0) into v_wallet_balance from wallets;

  select count(*), coalesce(sum(amount_cents), 0)
    into v_paid_recharge_orders, v_paid_recharge_cents
  from recharge_orders
  where status = 'paid';

  select count(*) into v_pending_recharge_orders
  from recharge_orders
  where status = 'pending';

  select count(*), coalesce(sum(price_cents), 0)
    into v_completed_ai_reports, v_ai_revenue_cents
  from ai_report_orders
  where status = 'completed';

  select count(*) into v_failed_or_refunded_ai_reports
  from ai_report_orders
  where status in ('failed', 'refunded');

  return jsonb_build_object(
    'users', v_users,
    'totalWalletBalanceCents', v_wallet_balance,
    'paidRechargeOrders', v_paid_recharge_orders,
    'paidRechargeCents', v_paid_recharge_cents,
    'pendingRechargeOrders', v_pending_recharge_orders,
    'completedAiReports', v_completed_ai_reports,
    'aiRevenueCents', v_ai_revenue_cents,
    'failedOrRefundedAiReports', v_failed_or_refunded_ai_reports
  );
end;
$$;

-- Security hardening for the public testing deployment.
-- All business data must be accessed through Vercel API routes that use the
-- Supabase service role key. Frontend anon/authenticated roles must not read
-- or mutate wallet, order, SMS, or AI report tables directly.
alter table app_users enable row level security;
alter table wallets enable row level security;
alter table sms_login_codes enable row level security;
alter table sms_send_attempts enable row level security;
alter table wallet_transactions enable row level security;
alter table recharge_orders enable row level security;
alter table ai_report_orders enable row level security;
alter table payment_notify_logs enable row level security;
alter table ai_call_logs enable row level security;
alter table admin_users enable row level security;
alter table admin_audit_logs enable row level security;

revoke all on table app_users from public, anon, authenticated;
revoke all on table wallets from public, anon, authenticated;
revoke all on table sms_login_codes from public, anon, authenticated;
revoke all on table sms_send_attempts from public, anon, authenticated;
revoke all on table wallet_transactions from public, anon, authenticated;
revoke all on table recharge_orders from public, anon, authenticated;
revoke all on table ai_report_orders from public, anon, authenticated;
revoke all on table payment_notify_logs from public, anon, authenticated;
revoke all on table ai_call_logs from public, anon, authenticated;
revoke all on table admin_users from public, anon, authenticated;
revoke all on table admin_audit_logs from public, anon, authenticated;

revoke execute on function ensure_app_user(uuid, text) from public, anon, authenticated;
revoke execute on function grant_registration_bonus(uuid) from public, anon, authenticated;
revoke execute on function create_recharge_order(uuid, text, text, bigint, text) from public, anon, authenticated;
revoke execute on function mark_recharge_paid(text, text, bigint, uuid, jsonb) from public, anon, authenticated;
revoke execute on function create_ai_report_debit(uuid, text, text, bigint, jsonb, jsonb, jsonb, text) from public, anon, authenticated;
revoke execute on function complete_ai_report_order(uuid, text, text, integer, integer) from public, anon, authenticated;
revoke execute on function refund_ai_report_order(uuid, text, text) from public, anon, authenticated;
revoke execute on function admin_adjust_wallet(uuid, text, uuid, bigint, text, text, text, text) from public, anon, authenticated;
revoke execute on function admin_dashboard_summary() from public, anon, authenticated;

grant usage on schema public to service_role;
grant all on table app_users to service_role;
grant all on table wallets to service_role;
grant all on table sms_login_codes to service_role;
grant all on table sms_send_attempts to service_role;
grant all on table wallet_transactions to service_role;
grant all on table recharge_orders to service_role;
grant all on table ai_report_orders to service_role;
grant all on table payment_notify_logs to service_role;
grant all on table ai_call_logs to service_role;
grant all on table admin_users to service_role;
grant all on table admin_audit_logs to service_role;

grant execute on function ensure_app_user(uuid, text) to service_role;
grant execute on function grant_registration_bonus(uuid) to service_role;
grant execute on function create_recharge_order(uuid, text, text, bigint, text) to service_role;
grant execute on function mark_recharge_paid(text, text, bigint, uuid, jsonb) to service_role;
grant execute on function create_ai_report_debit(uuid, text, text, bigint, jsonb, jsonb, jsonb, text) to service_role;
grant execute on function complete_ai_report_order(uuid, text, text, integer, integer) to service_role;
grant execute on function refund_ai_report_order(uuid, text, text) to service_role;
grant execute on function admin_adjust_wallet(uuid, text, uuid, bigint, text, text, text, text) to service_role;
grant execute on function admin_dashboard_summary() to service_role;

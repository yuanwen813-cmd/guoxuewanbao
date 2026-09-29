-- Run after schema.sql and points_migration.sql. Safe to run repeatedly.
-- No prices, existing balances, prompts or historical payment amounts change.
begin;

create or replace function complete_ai_report_order(
  p_order_id uuid,
  p_result_text text,
  p_model text,
  p_request_tokens integer,
  p_response_tokens integer
) returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
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

  if v_order.status in ('completed', 'failed', 'refunded') then
    select * into v_wallet from wallets where user_id = v_order.user_id;
    return jsonb_build_object('order', to_jsonb(v_order), 'wallet', to_jsonb(v_wallet));
  end if;
  if coalesce(btrim(p_result_text, E' \t\n\r'), '') = '' then
    raise exception 'AI_REPORT_EMPTY_RESULT';
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
set search_path = public, pg_temp
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

  -- Preserve valid completed reports, while allowing the legacy empty-result
  -- reconciliation to refund historical reports that never had content.
  if v_order.status = 'completed'
      and coalesce(btrim(v_order.result_text, E' \t\n\r'), '') not in
        ('', 'AI 服务未返回内容。', 'AI 服务未返回内容') then
    select * into v_wallet from wallets where user_id = v_order.user_id;
    return jsonb_build_object('order', to_jsonb(v_order), 'wallet', to_jsonb(v_wallet),
      'already_refunded', false, 'refund_skipped', true);
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

revoke execute on function complete_ai_report_order(uuid, text, text, integer, integer) from public, anon, authenticated;
revoke execute on function refund_ai_report_order(uuid, text, text) from public, anon, authenticated;
grant execute on function complete_ai_report_order(uuid, text, text, integer, integer) to service_role;
grant execute on function refund_ai_report_order(uuid, text, text) to service_role;
commit;

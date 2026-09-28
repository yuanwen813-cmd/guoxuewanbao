-- Run only after points_migration.sql. All test data rolls back.
begin;

do $$
declare
  v_user_id uuid;
  v_wallet_id uuid;
  v_result jsonb;
  v_order_id uuid;
  v_balance bigint;
  v_orders integer;
  v_trade text;
  v_request_id uuid;
  v_job_failed boolean := false;
  v_old_user_id uuid;
  v_short_user_id uuid;
  v_attempt integer;
begin
  insert into app_users(auth_user_id, registration_bonus_eligible)
  values (gen_random_uuid(), false) returning id into v_old_user_id;
  insert into wallets(user_id) values (v_old_user_id);
  v_result := grant_registration_bonus(v_old_user_id);
  if (v_result->>'granted')::boolean is true then
    raise exception 'OLD_USER_BONUS_DUPLICATED';
  end if;

  insert into app_users(auth_user_id, registration_bonus_eligible)
  values (gen_random_uuid(), false) returning id into v_short_user_id;
  insert into wallets(user_id, balance_cents) values (v_short_user_id, 100);
  begin
    perform create_ai_report_debit_once(v_short_user_id, 'question_full_3_9',
      'question_full', 200, '{}'::jsonb, '{}'::jsonb, '{}'::jsonb,
      'one point', gen_random_uuid());
    raise exception 'ONE_POINT_DEBIT_SHOULD_FAIL';
  exception when others then
    if sqlerrm <> 'INSUFFICIENT_BALANCE' then raise; end if;
  end;
  if (select count(*) from ai_report_orders where user_id = v_short_user_id) <> 0 then
    raise exception 'ONE_POINT_ORDER_CREATED';
  end if;

  insert into app_users(auth_user_id, registration_bonus_eligible)
  values (gen_random_uuid(), true) returning id into v_user_id;
  insert into wallets(user_id) values (v_user_id) returning id into v_wallet_id;

  v_result := grant_registration_bonus(v_user_id);
  if (v_result->>'granted')::boolean is not true then
    raise exception 'FIRST_BONUS_FAILED';
  end if;
  v_result := grant_registration_bonus(v_user_id);
  if (v_result->>'granted')::boolean is true then
    raise exception 'BONUS_DUPLICATED';
  end if;
  select balance_cents into v_balance from wallets where id = v_wallet_id;
  if v_balance <> 1000 then raise exception 'BONUS_BALANCE_WRONG'; end if;

  v_request_id := gen_random_uuid();
  v_result := create_ai_report_debit_once(v_user_id, 'question_full_3_9',
    'question_full', 200, '{}'::jsonb, '{}'::jsonb, '{}'::jsonb,
    'first report', v_request_id);
  v_order_id := (v_result->'order'->>'id')::uuid;
  v_result := create_ai_report_debit_once(v_user_id, 'question_full_3_9',
    'question_full', 200, '{}'::jsonb, '{}'::jsonb, '{}'::jsonb,
    'first report', v_request_id);
  if (v_result->'order'->>'id')::uuid <> v_order_id
      or (v_result->>'already_pending')::boolean is not true then
    raise exception 'REQUEST_ID_NOT_IDEMPOTENT';
  end if;
  v_result := create_ai_report_debit_once(v_user_id, 'question_full_3_9',
    'question_full', 200, '{}'::jsonb, '{}'::jsonb, '{}'::jsonb,
    'first report', gen_random_uuid());
  if (v_result->'order'->>'id')::uuid <> v_order_id then
    raise exception 'RAPID_REPEAT_CHARGED_AGAIN';
  end if;
  select balance_cents into v_balance from wallets where id = v_wallet_id;
  if v_balance <> 800 then raise exception 'FIRST_DEBIT_WRONG'; end if;

  for v_attempt in 2..5 loop
    perform create_ai_report_debit_once(v_user_id, 'question_full_3_9',
      'question_full', 200, '{}'::jsonb, '{}'::jsonb, '{}'::jsonb,
      'report ' || v_attempt, gen_random_uuid());
  end loop;
  select balance_cents into v_balance from wallets where id = v_wallet_id;
  if v_balance <> 0 then raise exception 'FIFTH_DEBIT_WRONG'; end if;

  begin
    perform create_ai_report_debit_once(v_user_id, 'question_full_3_9',
      'question_full', 200, '{}'::jsonb, '{}'::jsonb, '{}'::jsonb,
      'sixth report', gen_random_uuid());
    raise exception 'SIXTH_DEBIT_SHOULD_FAIL';
  exception when others then
    if sqlerrm <> 'INSUFFICIENT_BALANCE' then raise; end if;
  end;
  select count(*) into v_orders from ai_report_orders where user_id = v_user_id;
  if v_orders <> 5 then raise exception 'FAILED_DEBIT_CREATED_ORDER'; end if;

  perform refund_ai_report_order(v_order_id, 'test failure', null);
  perform refund_ai_report_order(v_order_id, 'test retry', null);
  select balance_cents into v_balance from wallets where id = v_wallet_id;
  if v_balance <> 200 then raise exception 'REFUND_NOT_IDEMPOTENT'; end if;

  insert into ai_report_worker_status(id, last_seen_at) values (true, now())
  on conflict (id) do update set last_seen_at = now();
  begin
    perform start_ai_report_job_once(v_user_id, 'bazi_basic_3_9',
      'bazi_basic', 200, '{}'::jsonb, '{}'::jsonb, '{}'::jsonb,
      'task creation failure test', null, '', gen_random_uuid());
  exception when not_null_violation then v_job_failed := true;
  end;
  select balance_cents into v_balance from wallets where id = v_wallet_id;
  select count(*) into v_orders from ai_report_orders where user_id = v_user_id;
  if not v_job_failed or v_balance <> 200 or v_orders <> 5 then
    raise exception 'TASK_CREATION_ROLLBACK_FAILED';
  end if;

  v_trade := 'TEST' || replace(gen_random_uuid()::text, '-', '');
  perform create_recharge_order(v_user_id, 'alipay', 'web_pc', 1000, v_trade);
  perform mark_recharge_paid(v_trade, 'provider-test', 1000, null, '{}'::jsonb);
  perform mark_recharge_paid(v_trade, 'provider-test', 1000, null, '{}'::jsonb);
  select balance_cents into v_balance from wallets where id = v_wallet_id;
  if v_balance <> 1200 then raise exception 'DUPLICATE_RECHARGE_CREDIT'; end if;

  v_trade := 'TEST' || replace(gen_random_uuid()::text, '-', '');
  perform create_recharge_order(v_user_id, 'alipay', 'web_pc', 5000, v_trade);
  perform mark_recharge_paid(v_trade, 'provider-test-2', 5000, null, '{}'::jsonb);
  select balance_cents into v_balance from wallets where id = v_wallet_id;
  if v_balance <> 6200 then raise exception 'FIFTY_RECHARGE_WRONG'; end if;

  if (select count(*) from points_transactions
      where user_id = v_user_id and transaction_type = 'REGISTER_BONUS') <> 1 then
    raise exception 'BONUS_LEDGER_DUPLICATED';
  end if;
  if (select points_balance from wallets where id = v_wallet_id) <> 62 then
    raise exception 'POINTS_VIEW_WRONG';
  end if;
  raise notice 'POINTS_SMOKE_TEST_PASSED; all changes will roll back';
end;
$$;

rollback;

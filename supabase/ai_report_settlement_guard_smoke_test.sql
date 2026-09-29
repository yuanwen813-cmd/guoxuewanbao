-- Run after ai_report_settlement_guard_migration.sql and points_migration.sql.
-- All fixtures roll back; no real user/order is changed.
begin;
do $$
declare
  v_user uuid;
  v_order uuid;
  v_result jsonb;
begin
  insert into app_users(auth_user_id, registration_bonus_eligible)
  values (gen_random_uuid(), false) returning id into v_user;
  insert into wallets(user_id, balance_cents) values (v_user, 1000);

  v_result := create_ai_report_debit_once(v_user, 'question_full_3_9',
    'question_full', 200, '{}', '{}', '{}', 'settlement test', gen_random_uuid());
  v_order := (v_result->'order'->>'id')::uuid;
  perform complete_ai_report_order(v_order, 'Valid saved report', 'test', 10, 20);
  perform complete_ai_report_order(v_order, 'Must not replace original report', 'test', 10, 20);
  perform refund_ai_report_order(v_order, 'Lost response', 'test');
  if (select balance_cents from wallets where user_id = v_user) <> 800 then
    raise exception 'COMPLETED_REPORT_REFUNDED';
  end if;
  if (select result_text from ai_report_orders where id = v_order) <> 'Valid saved report'
      or (select status from ai_report_orders where id = v_order) <> 'completed' then
    raise exception 'COMPLETED_REPORT_OVERWRITTEN';
  end if;
  if (select count(*) from ai_call_logs where ai_report_order_id = v_order and success) <> 1 then
    raise exception 'DUPLICATE_COMPLETION_LOG';
  end if;

  v_result := create_ai_report_debit_once(v_user, 'question_full_3_9',
    'question_full', 200, '{}', '{}', '{}', 'failed test', gen_random_uuid());
  v_order := (v_result->'order'->>'id')::uuid;
  perform refund_ai_report_order(v_order, 'AI failed', 'test');
  perform refund_ai_report_order(v_order, 'Duplicate callback', 'test');
  perform complete_ai_report_order(v_order, 'Late response', 'test', 10, 20);
  if (select balance_cents from wallets where user_id = v_user) <> 800
      or (select status from ai_report_orders where id = v_order) <> 'refunded' then
    raise exception 'REFUNDED_REPORT_REOPENED_OR_DOUBLE_REFUND';
  end if;
  if (select count(*) from wallet_transactions where ref_id = v_order::text and type = 'ai_refund') <> 1 then
    raise exception 'REFUND_LEDGER_NOT_IDEMPOTENT';
  end if;

  v_result := create_ai_report_debit_once(v_user, 'question_full_3_9',
    'question_full', 200, '{}', '{}', '{}', 'legacy empty test', gen_random_uuid());
  v_order := (v_result->'order'->>'id')::uuid;
  update ai_report_orders set status = 'completed', result_text = 'AI 服务未返回内容。' where id = v_order;
  perform refund_ai_report_order(v_order, 'Legacy empty result', 'test');
  perform refund_ai_report_order(v_order, 'Legacy repeated reconciliation', 'test');
  if (select balance_cents from wallets where user_id = v_user) <> 800 then
    raise exception 'LEGACY_EMPTY_REFUND_FAILED';
  end if;

  v_result := create_ai_report_debit_once(v_user, 'question_full_3_9',
    'question_full', 200, '{}', '{}', '{}', 'whitespace test', gen_random_uuid());
  v_order := (v_result->'order'->>'id')::uuid;
  begin
    perform complete_ai_report_order(v_order, E' \n\t', 'test', 0, 0);
    raise exception 'WHITESPACE_RESULT_ACCEPTED';
  exception when others then
    if sqlerrm <> 'AI_REPORT_EMPTY_RESULT' then raise; end if;
  end;
  update ai_report_orders set status = 'completed', result_text = E' \n\t' where id = v_order;
  perform refund_ai_report_order(v_order, 'Legacy whitespace result', 'test');
  if (select balance_cents from wallets where user_id = v_user) <> 800 then
    raise exception 'WHITESPACE_REFUND_FAILED';
  end if;
end;
$$;
rollback;
select 'AI_SETTLEMENT_SMOKE_TEST_PASSED' as result;

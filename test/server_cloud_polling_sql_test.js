const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { PGlite } = require(process.env.PGLITE_MODULE_PATH || '@electric-sql/pglite');
const read = (name) => fs.readFileSync(path.join(__dirname, '../supabase', name), 'utf8');

async function main() {
  const db = new PGlite();
  const value = async (sql, args = []) => (await db.query(sql, args)).rows[0].value;
  const uuid = () => value('select gen_random_uuid() as value');
  const start = (user, product, prompt, requestId) => value(
    `select create_ai_report_debit_once($1,$2,$2,200,'{}','{}','{}',$3,$4) as value`,
    [user, product, prompt, requestId]);
  const balance = (user) => value('select balance_cents::integer as value from wallets where user_id=$1', [user]);
  const status = (order) => value('select status as value from ai_report_orders where id=$1', [order]);
  const complete = (order) => value("select complete_ai_report_order($1,'完整解析','test',null,null) as value", [order]);
  const refund = (order) => value("select refund_ai_report_order($1,'test failure','test') as value", [order]);
  try {
    await db.exec('create role anon; create role authenticated; create role service_role;');
    await db.exec(read('schema.sql').replace('create extension if not exists pgcrypto;', ''));
    for (const name of ['ai_report_jobs.sql', 'points_migration.sql',
      'ai_report_settlement_guard_migration.sql']) await db.exec(read(name));
    if (process.argv.includes('--from-legacy')) {
      await db.exec(read('ai_all_async_migration.sql'));
    }
    await db.exec(read('ai_cloud_polling_migration.sql'));
    await db.exec(read('ai_cloud_polling_migration.sql'));
    const user = await value('insert into app_users(auth_user_id) values(gen_random_uuid()) returning id as value');
    const other = await value('insert into app_users(auth_user_id) values(gen_random_uuid()) returning id as value');
    await db.query('insert into wallets(user_id,balance_cents) values($1,1000),($2,100)', [user, other]);
    // No Worker heartbeat, claim, job queue, or local process is required.
    const requestId = await uuid();
    const first = await start(user, 'question_full_3_9', 'question', requestId);
    const repeats = await Promise.all([
      start(user, 'question_full_3_9', 'question', requestId),
      start(user, 'question_full_3_9', 'question', await uuid()),
    ]);
    for (const repeat of repeats) assert.equal(repeat.order.id, first.order.id);
    assert.equal(await balance(user), 800);
    assert.equal(await value('select count(*)::integer as value from ai_report_jobs'), 0);
    assert.equal(await value('select count(*)::integer as value from ai_report_worker_status'), 0);
    await assert.rejects(start(user, 'question_full_3_9', 'changed input', requestId), /REQUEST_ID_CONFLICT/);
    await complete(first.order.id);
    await complete(first.order.id);
    await refund(first.order.id);
    assert.equal(await status(first.order.id), 'completed');
    assert.equal(await balance(user), 800);

    const daily = await start(user, 'daily_hexagram_brief', 'daily A', await uuid());
    const another = await start(user, 'daily_hexagram_brief', 'daily B', await uuid());
    assert.equal(another.order.id, daily.order.id);
    await complete(daily.order.id);
    assert.equal((await start(user, 'daily_hexagram_brief', 'daily C', await uuid())).order.id, daily.order.id);
    assert.equal((await value('select get_today_daily_ai_report($1) as value', [user])).id, daily.order.id);
    assert.equal(await value('select get_today_daily_ai_report($1) as value', [other]), null);
    assert.equal(await balance(user), 600);

    const failed = await start(user, 'ziwei_basic', 'failure', await uuid());
    await refund(failed.order.id);
    await refund(failed.order.id);
    await complete(failed.order.id);
    assert.equal(await status(failed.order.id), 'refunded');
    assert.equal(await balance(user), 600);
    const killed = await start(user, 'bazi_basic_3_9', 'killed function', await uuid());
    await db.query("update ai_report_orders set created_at=now()-interval '16 minutes' where id=$1", [killed.order.id]);
    await db.query('select expire_stale_inline_ai_reports(null)');
    await db.query('select expire_stale_inline_ai_reports(null)');
    await complete(killed.order.id);
    assert.equal(await status(killed.order.id), 'refunded');
    assert.equal(await balance(user), 600);

    // A ledger error after the order insert must roll back the entire debit.
    const before = await value('select count(*)::integer as value from ai_report_orders');
    await db.exec(`create function test_reject_ai_ledger() returns trigger language plpgsql as $$
      begin if new.type='ai_debit' then raise exception 'SIMULATED_LEDGER_FAILURE'; end if; return new; end; $$;
      create trigger test_reject_ai_ledger before insert on wallet_transactions
      for each row execute function test_reject_ai_ledger();`);
    await assert.rejects(start(user, 'tieban_basic', 'rollback', await uuid()), /SIMULATED_LEDGER_FAILURE/);
    assert.equal(await balance(user), 600);
    assert.equal(await value('select count(*)::integer as value from ai_report_orders'), before);
    await db.exec('drop trigger test_reject_ai_ledger on wallet_transactions;');
    await assert.rejects(start(other, 'ziwei_basic', 'insufficient', await uuid()), /INSUFFICIENT_BALANCE/);
    assert.equal(await value('select count(*)::integer as value from ai_report_orders where user_id=$1', [other]), 0);

    await db.query(`insert into ai_report_orders(user_id, product_id, report_type,
      price_cents, status, result_text, created_at) values($1,'daily_hexagram_brief',
      'daily_hexagram_brief',200,'completed','legacy duplicate',
      ((now() at time zone 'Asia/Shanghai')::date + time '23:59:59') at time zone 'Asia/Shanghai')`, [user]);
    await db.exec(read('ai_cloud_polling_migration.sql'));
    assert.equal((await value('select get_today_daily_ai_report($1) as value', [user])).id, daily.order.id);
    await db.query("update ai_report_orders set daily_report_date=(now() at time zone 'Asia/Shanghai')::date-1 where id=$1", [daily.order.id]);
    assert.equal(await value('select get_today_daily_ai_report($1) as value', [user]), null);
    const tomorrow = await start(user, 'daily_hexagram_brief', 'daily A', await uuid());
    assert.notEqual(tomorrow.order.id, daily.order.id);
    assert.equal(await balance(user), 400);
    for (const role of ['anon', 'authenticated']) {
      for (const fn of ['get_today_daily_ai_report(uuid)',
        'create_ai_report_debit_once(uuid,text,text,bigint,jsonb,jsonb,jsonb,text,uuid)']) {
        assert.equal(await value('select has_function_privilege($1,$2,\'execute\') as value', [role, fn]), false);
      }
    }
    assert.equal(await value('select count(*)::integer as value from ai_report_jobs'), 0);
    console.log(`CLOUD_POLLING_SQL_TEST_PASSED (${process.argv.includes('--from-legacy') ? 'legacy upgrade' : 'existing inline upgrade'}): no Worker, atomic debit/order/ledger, retry reuse, daily ownership/day boundary, refund, orphan recovery and permissions`);
  } finally { await db.close(); }
}
main().catch((error) => {console.error(error); process.exitCode = 1;});

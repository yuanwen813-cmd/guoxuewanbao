const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { PGlite } = require(process.env.PGLITE_MODULE_PATH || '@electric-sql/pglite');
const read = (name) => fs.readFileSync(path.join(__dirname, '../supabase', name), 'utf8');

async function main() {
  const db = new PGlite();
  const scalar = async (sql, params = []) => (await db.query(sql, params)).rows[0].value;
  const start = (user, product, prompt, requestId) => scalar(
    `select start_ai_report_job_once($1,$2,$2,200,'{}','{}','{}',$3,$3,'',$4) as value`,
    [user, product, prompt, requestId]);
  const claim = () => scalar('select claim_ai_report_job() as value');
  const balance = (user) => scalar('select balance_cents::integer as value from wallets where user_id=$1', [user]);
  const status = (order) => scalar('select status as value from ai_report_orders where id=$1', [order]);
  const settle = (job, text) => scalar("select settle_ai_report_job($1,$2,$3,'test failure','test',null,null) as value",
    [job.order_id, job.claim_token, text]);
  try {
    await db.exec('create role anon; create role authenticated; create role service_role;');
    await db.exec(read('schema.sql').replace('create extension if not exists pgcrypto;', ''));
    for (const name of ['ai_report_jobs.sql', 'points_migration.sql',
      'ai_report_settlement_guard_migration.sql', 'ai_all_async_migration.sql',
      'ai_all_async_migration.sql']) await db.exec(read(name));
    const user = await scalar('insert into app_users(auth_user_id) values(gen_random_uuid()) returning id as value');
    const other = await scalar('insert into app_users(auth_user_id) values(gen_random_uuid()) returning id as value');
    await db.query('insert into wallets(user_id,balance_cents) values($1,1000),($2,100)', [user, other]);
    await db.exec('insert into ai_report_worker_status values(true,now())');
    const requestId = await scalar('select gen_random_uuid() as value');
    const first = await start(user, 'question_full_3_9', 'same question', requestId);
    const repeats = await Promise.all([start(user, 'question_full_3_9', 'same question', requestId),
      start(user, 'question_full_3_9', 'same question', await scalar('select gen_random_uuid() as value'))]);
    for (const repeat of repeats) assert.equal(repeat.order.id, first.order.id);
    assert.equal(await balance(user), 800);
    assert.equal(await scalar('select count(*)::integer as value from ai_report_jobs'), 1);
    const job = await claim();
    assert.equal(await scalar("select extract(epoch from(deadline_at-started_at))::integer as value from ai_report_jobs where order_id=$1", [job.order_id]), 900);
    await db.query('select heartbeat_ai_report_job($1,$2)', [job.order_id, job.claim_token]);
    assert.equal(await scalar("select deadline_at=started_at+interval '15 minutes' as value from ai_report_jobs where order_id=$1", [job.order_id]), true);
    await settle(job, '完整报告');
    await settle(job, 'duplicate');
    await db.query("select refund_ai_report_order($1,'late refund',null)", [job.order_id]);
    assert.equal(await status(job.order_id), 'completed');
    assert.equal(await balance(user), 800);
    const daily = await start(user, 'daily_hexagram_brief', 'daily A', await scalar('select gen_random_uuid() as value'));
    const again = await start(user, 'daily_hexagram_brief', 'daily B', await scalar('select gen_random_uuid() as value'));
    assert.equal(again.order.id, daily.order.id);
    assert.equal(await balance(user), 600);
    const dailyJob = await claim();
    await settle(dailyJob, '今日完整解析');
    assert.equal((await start(user, 'daily_hexagram_brief', 'daily C', await scalar('select gen_random_uuid() as value'))).order.id, daily.order.id);
    assert.equal((await scalar('select get_today_daily_ai_report($1) as value', [user])).id, daily.order.id);
    assert.equal(await scalar('select get_today_daily_ai_report($1) as value', [other]), null);
    const timed = await start(user, 'ziwei_basic', 'deadline test', await scalar('select gen_random_uuid() as value'));
    // A queue wait does not consume the execution budget.
    await db.query("update ai_report_jobs set created_at=now()-interval '14 minutes' where order_id=$1", [timed.order.id]);
    const timedJob = await claim();
    await db.query("update ai_report_jobs set deadline_at=now()-interval '1 second' where order_id=$1", [timedJob.order_id]);
    await db.query('select expire_ai_report_jobs(null)');
    await db.query('select expire_ai_report_jobs(null)');
    assert.equal((await settle(timedJob, 'late success')).settled, false);
    assert.equal(await status(timed.order.id), 'refunded');
    assert.equal(await balance(user), 600);
    const failed = await start(user, 'tieban_basic', 'failure test', await scalar('select gen_random_uuid() as value'));
    await settle(await claim(), null);
    assert.equal(await status(failed.order.id), 'refunded');
    assert.equal(await balance(user), 600);
    const queueExpired = await start(user, 'bazi_basic_3_9', 'queue timeout', await scalar('select gen_random_uuid() as value'));
    await db.query("update ai_report_jobs set created_at=now()-interval '31 minutes' where order_id=$1", [queueExpired.order.id]);
    await db.query('select expire_ai_report_jobs(null)');
    assert.equal(await status(queueExpired.order.id), 'refunded');
    assert.equal(await balance(user), 600);
    await assert.rejects(start(user, 'ziwei_basic', null, await scalar('select gen_random_uuid() as value')),
      (e) => e.code === '23502');
    assert.equal(await balance(user), 600);
    assert.equal(await scalar("select count(*)::integer as value from ai_report_orders where user_id=$1", [user]), 5);
    await assert.rejects(start(other, 'ziwei_basic', 'insufficient', await scalar('select gen_random_uuid() as value')),
      /INSUFFICIENT_BALANCE/);
    assert.equal(await scalar("select count(*)::integer as value from ai_report_orders where user_id=$1", [other]), 0);
    await db.exec("update ai_report_worker_status set last_seen_at=now()-interval '2 minutes'");
    await assert.rejects(start(user, 'ziwei_basic', 'offline', await scalar('select gen_random_uuid() as value')), /AI_WORKER_UNAVAILABLE/);
    assert.equal(await balance(user), 600);
    for (const role of ['anon', 'authenticated']) assert.equal(await scalar(
      "select has_function_privilege($1,'get_today_daily_ai_report(uuid)','execute') as value", [role]), false);
    await db.query(`insert into ai_report_orders(user_id, product_id, report_type,
      price_cents, status, result_text, created_at) values($1,'daily_hexagram_brief',
      'daily_hexagram_brief',200,'completed','legacy duplicate',
      ((now() at time zone 'Asia/Shanghai')::date + time '23:59:59') at time zone 'Asia/Shanghai')`, [user]);
    await db.exec(read('ai_all_async_migration.sql'));
    assert.equal((await scalar('select get_today_daily_ai_report($1) as value', [user])).id, daily.order.id);
    await db.query("update ai_report_orders set daily_report_date=(now() at time zone 'Asia/Shanghai')::date-1 where id=$1", [daily.order.id]);
    assert.equal(await scalar('select get_today_daily_ai_report($1) as value', [user]), null);
    await db.exec('update ai_report_worker_status set last_seen_at=now()');
    const nextDay = await start(user, 'daily_hexagram_brief', 'next day', await scalar('select gen_random_uuid() as value'));
    assert.notEqual(nextDay.order.id, daily.order.id);
    const lateJob = await claim();
    await db.query("update ai_report_jobs set deadline_at=now()-interval '1 second' where order_id=$1", [lateJob.order_id]);
    await settle(lateJob, 'too late');
    assert.equal(await status(nextDay.order.id), 'refunded');
    assert.equal(await balance(user), 600);
    console.log('ALL_ASYNC_SQL_TEST_PASSED: atomic debit, reuse, daily, success, failure, 15-minute deadline, offline and permissions');
  } finally { await db.close(); }
}
main().catch((error) => { console.error(error); process.exitCode = 1; });

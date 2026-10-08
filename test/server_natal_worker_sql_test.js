const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { PGlite } = require(process.env.PGLITE_MODULE_PATH || '@electric-sql/pglite');
const read = (name) => fs.readFileSync(path.join(__dirname, '../supabase', name), 'utf8');

async function main() {
  const db = new PGlite();
  const value = async (sql, args = []) => (await db.query(sql, args)).rows[0].value;
  const uuid = () => value('select gen_random_uuid() as value');
  const balance = (user) => value('select balance_cents::integer as value from wallets where user_id=$1', [user]);
  const status = (order) => value('select status as value from ai_report_orders where id=$1', [order]);
  const start = (user, product, prompt, requestId) => value(
    `select start_ai_report_job_once($1,$2,$2,200,'{}','{}','{}',$3,$3,'same system',$4) as value`,
    [user, product, prompt, requestId]);
  const cloud = (user, product, prompt, requestId) => value(
    `select create_ai_report_debit_once($1,$2,$2,200,'{}','{}','{}',$3,$4) as value`,
    [user, product, prompt, requestId]);
  const claim = () => value('select claim_ai_report_job() as value');
  const settle = (job, text) => value("select settle_ai_report_job($1,$2,$3,'test failure','test',null,null) as value",
    [job.order_id, job.claim_token, text]);
  try {
    await db.exec('create role anon; create role authenticated; create role service_role;');
    await db.exec(read('schema.sql').replace('create extension if not exists pgcrypto;', ''));
    for (const name of ['ai_report_jobs.sql', 'points_migration.sql',
      'ai_report_settlement_guard_migration.sql']) await db.exec(read(name));
    if (process.argv.includes('--from-legacy')) await db.exec(read('ai_all_async_migration.sql'));
    await db.exec(read('ai_cloud_polling_migration.sql'));
    const functionText = () => value(`select
      pg_get_functiondef('create_ai_report_debit_once(uuid,text,text,bigint,jsonb,jsonb,jsonb,text,uuid)'::regprocedure)
      || pg_get_functiondef('get_today_daily_ai_report(uuid)'::regprocedure) as value`);
    const originalCloud = await functionText();
    await db.exec(read('ai_natal_worker_migration.sql'));
    await db.exec(read('ai_natal_worker_migration.sql'));
    assert.equal(await functionText(), originalCloud);
    const user = await value('insert into app_users(auth_user_id) values(gen_random_uuid()) returning id as value');
    const other = await value('insert into app_users(auth_user_id) values(gen_random_uuid()) returning id as value');
    await db.query('insert into wallets(user_id,balance_cents) values($1,1000),($2,100)', [user, other]);
    await assert.rejects(start(user, 'bazi_basic_3_9', 'offline', await uuid()), /AI_WORKER_UNAVAILABLE/);
    assert.equal(await balance(user), 1000);
    assert.equal(await value('select count(*)::integer as value from ai_report_orders'), 0);
    // Cloud questions and daily reports work without a Worker heartbeat.
    const question = await cloud(user, 'question_full_3_9', 'question', await uuid());
    const daily = await cloud(user, 'daily_hexagram_brief', 'daily', await uuid());
    assert.equal((await cloud(user, 'daily_hexagram_brief', 'changed daily', await uuid())).order.id, daily.order.id);
    assert.equal(await value('select count(*)::integer as value from ai_report_jobs'), 0);
    for (const order of [question.order, daily.order]) {
      await db.query("select complete_ai_report_order($1,'完整报告','test',null,null)", [order.id]);
    }
    assert.equal((await value('select get_today_daily_ai_report($1) as value', [user])).id, daily.order.id);
    assert.equal(await balance(user), 600);

    assert.equal(await claim(), null); // Claim polling publishes the real Worker heartbeat.
    const requestId = await uuid();
    const first = await start(user, 'bazi_basic_3_9', 'same birth chart', requestId);
    assert.equal((await start(user, 'bazi_basic_3_9', 'same birth chart', requestId)).order.id, first.order.id);
    assert.equal((await start(user, 'bazi_basic_3_9', 'same birth chart', await uuid())).order.id, first.order.id);
    assert.equal(await balance(user), 400);
    assert.equal(await value('select count(*)::integer as value from ai_report_jobs'), 1);
    const job = await claim();
    assert.equal(job.user_prompt, 'same birth chart');
    assert.equal(job.system_prompt, 'same system');
    assert.equal(Date.parse(job.deadline_at) - Date.parse(job.started_at), 900000);
    assert.equal(await value('select heartbeat_ai_report_job($1,$2) as value', [job.order_id, job.claim_token]), true);
    assert.equal(await value("select deadline_at=started_at+interval '15 minutes' as value from ai_report_jobs where order_id=$1", [job.order_id]), true);
    // The inline 15-minute recovery must not refund a running Worker order.
    await db.query("update ai_report_orders set created_at=now()-interval '16 minutes' where id=$1", [job.order_id]);
    await db.query('select expire_stale_inline_ai_reports(null)');
    assert.equal(await status(job.order_id), 'generating');
    await db.query("update ai_report_jobs set lease_until=now()-interval '1 second' where order_id=$1", [job.order_id]);
    assert.equal(await claim(), null); // No duplicate AI execution or fresh deadline after a crash.
    assert.equal(await value('select attempts as value from ai_report_jobs where order_id=$1', [job.order_id]), 1);
    await db.query("update ai_report_jobs set deadline_at=now()-interval '1 second' where order_id=$1", [job.order_id]);
    await db.query('select expire_ai_report_jobs(null)');
    await db.query('select expire_ai_report_jobs(null)');
    assert.equal((await settle(job, 'late success')).settled, false);
    assert.equal(await status(job.order_id), 'refunded');
    assert.equal(await balance(user), 600);

    const success = await start(user, 'ziwei_basic', 'success', await uuid());
    const successfulJob = await claim();
    await settle(successfulJob, '完整紫微解析');
    await settle(successfulJob, 'duplicate');
    await db.query("select refund_ai_report_order($1,'late failure','test')", [success.order.id]);
    assert.equal(await status(success.order.id), 'completed');
    assert.equal(await balance(user), 400);
    const failed = await start(user, 'tieban_basic', 'failure', await uuid());
    const failedJob = await claim();
    await settle(failedJob, null);
    await settle(failedJob, null);
    assert.equal(await status(failed.order.id), 'refunded');
    assert.equal(await balance(user), 400);

    const queued = await start(user, 'bazi_basic_3_9', 'queue timeout', await uuid());
    await db.query("update ai_report_jobs set created_at=now()-interval '31 minutes' where order_id=$1", [queued.order.id]);
    await db.query('select expire_ai_report_jobs(null)');
    assert.equal(await status(queued.order.id), 'refunded');
    assert.equal(await balance(user), 400);
    const before = await value('select count(*)::integer as value from ai_report_orders');
    await assert.rejects(start(user, 'ziwei_basic', null, await uuid()), (error) => error.code === '23502');
    assert.equal(await value('select count(*)::integer as value from ai_report_orders'), before);
    assert.equal(await balance(user), 400);
    await assert.rejects(start(other, 'ziwei_basic', 'insufficient', await uuid()), /INSUFFICIENT_BALANCE/);
    assert.equal(await value('select count(*)::integer as value from ai_report_orders where user_id=$1', [other]), 0);
    await db.exec("update ai_report_worker_status set last_seen_at=now()-interval '2 minutes'");
    await assert.rejects(start(user, 'tieban_basic', 'offline again', await uuid()), /AI_WORKER_UNAVAILABLE/);
    const stillCloud = await cloud(user, 'question_full_3_9', 'another question', await uuid());
    assert.equal(await value('select count(*)::integer as value from ai_report_jobs where order_id=$1', [stillCloud.order.id]), 0);
    for (const role of ['anon', 'authenticated']) {
      for (const fn of ['claim_ai_report_job()', 'expire_ai_report_jobs(uuid)',
        'heartbeat_ai_report_job(uuid,uuid)', 'settle_ai_report_job(uuid,uuid,text,text,text,integer,integer)']) {
        assert.equal(await value('select has_function_privilege($1,$2,\'execute\') as value', [role, fn]), false);
      }
    }
    console.log(`NATAL_WORKER_SQL_TEST_PASSED (${process.argv.includes('--from-legacy') ? 'legacy upgrade' : 'cloud upgrade'}): untouched cloud RPCs, offline no debit, atomic queue/reuse, 15-minute deadline, no replay, success/refund and permissions`);
  } finally { await db.close(); }
}
main().catch((error) => { console.error(error); process.exitCode = 1; });

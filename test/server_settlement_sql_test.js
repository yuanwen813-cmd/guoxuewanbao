// Optional offline PostgreSQL test. Set PGLITE_MODULE_PATH to an installed
// @electric-sql/pglite directory; no production credentials are read.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { PGlite } = require(process.env.PGLITE_MODULE_PATH || '@electric-sql/pglite');
const read = (name) => fs.readFileSync(path.join(__dirname, '../supabase', name), 'utf8');

async function main() {
  const db = new PGlite();
  try {
    await db.exec('create role anon; create role authenticated; create role service_role;');
    // PGlite already supplies gen_random_uuid in PostgreSQL core.
    await db.exec(read('schema.sql').replace('create extension if not exists pgcrypto;', ''));
    await db.exec(read('ai_report_jobs.sql'));
    await db.exec(read('points_migration.sql'));
    const migration = read('ai_report_settlement_guard_migration.sql');
    await db.exec(migration);
    await db.exec(migration);
    const results = await db.exec(read('ai_report_settlement_guard_smoke_test.sql'));
    assert.equal(results.at(-1).rows[0].result, 'AI_SETTLEMENT_SMOKE_TEST_PASSED');
    assert.equal((await db.query('select count(*)::integer as total from app_users')).rows[0].total, 0);
    for (const role of ['anon', 'authenticated']) {
      const permission = await db.query(`select has_function_privilege($1,
        'refund_ai_report_order(uuid,text,text)', 'execute') as allowed`, [role]);
      assert.equal(permission.rows[0].allowed, false);
    }
    await db.exec(read('points_smoke_test.sql'));
    console.log('PostgreSQL settlement, repeat migration, permissions and points smoke tests passed');
  } finally {
    await db.close();
  }
}
main().catch((error) => { console.error(error.message); process.exitCode = 1; });

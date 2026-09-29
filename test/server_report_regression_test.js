const assert = require('node:assert/strict');
const { generateAiReport } = require('../server/aiReportService');
const { createAiReportDebit, createQueuedAiReportDebit, listAiReportsForUser } = require('../server/walletService');

function scenario() {
  const calls = { ai: 0, complete: 0, refund: 0 };
  const order = { id: 'report-1', status: 'generating', priceCents: 200 };
  const wallet = { balanceCents: 800 };
  const dependencies = {
    getAiProduct: () => ({ id: 'question_full_3_9', enabled: true, priceCents: 200, pricePoints: 2, reportType: 'question_full' }),
    buildAiReportSystemPrompt: () => '',
    createAiReportDebit: async () => ({ order: { ...order }, wallet }),
    callDoubao: async () => { calls.ai++; return { answer: 'Original AI answer', model: 'test' }; },
    completeAiReport: async ({ resultText }) => {
      calls.complete++;
      Object.assign(order, { status: 'completed', resultText });
      return { order: { ...order }, wallet };
    },
    getAiReportForUser: async () => ({ ...order }),
    getWallet: async () => wallet,
    refundAiReport: async () => { calls.refund++; throw Error('Unexpected refund'); },
    recordServiceEventQuietly: () => {},
  };
  return { calls, order, wallet, dependencies,
    run: () => generateAiReport({ userId: 'user-1', body: {
      productId: 'question_full_3_9', expectedPointsCenti: 200, userPrompt: 'Original prompt',
    }, dependencies }),
  };
}

async function main() {
  const saved = scenario();
  const save = saved.dependencies.completeAiReport;
  saved.dependencies.completeAiReport = async (args) => {
    await save(args);
    throw Error('Committed but HTTP response lost');
  };
  assert.equal((await saved.run()).report.status, 'completed');
  assert.deepEqual(saved.calls, { ai: 1, complete: 1, refund: 0 });

  const retry = scenario();
  const retrySave = retry.dependencies.completeAiReport;
  let attempts = 0;
  retry.dependencies.completeAiReport = async (args) => {
    if (++attempts === 1) throw Error('Database temporarily unavailable');
    return retrySave(args);
  };
  assert.equal((await retry.run()).report.status, 'completed');
  assert.equal(attempts, 2);
  assert.equal(retry.calls.ai, 1);
  assert.equal(retry.calls.refund, 0);

  const uncertain = scenario();
  uncertain.dependencies.completeAiReport = async () => { throw Error('Database unavailable'); };
  uncertain.dependencies.getAiReportForUser = async () => { throw Error('Database unavailable'); };
  const pending = await uncertain.run();
  assert.equal(pending.pending, true);
  assert.equal(pending.report.id, 'report-1');
  assert.equal(pending.answer, '');
  assert.equal(uncertain.calls.refund, 0);

  const expired = scenario();
  expired.dependencies.completeAiReport = async () => ({ order: { ...expired.order, status: 'refunded' }, wallet: { balanceCents: 1000 } });
  await assert.rejects(expired.run, (error) => error.statusCode === 409 && error.details.refunded);
  assert.equal(expired.calls.refund, 0);

  const completedRace = scenario();
  completedRace.dependencies.callDoubao = async () => { throw Error('Late failure'); };
  completedRace.dependencies.refundAiReport = async () => ({
    order: { ...completedRace.order, status: 'completed', resultText: 'Saved content' }, wallet: completedRace.wallet,
  });
  assert.equal((await completedRace.run()).answer, 'Saved content');

  for (const fn of [createAiReportDebit, createQueuedAiReportDebit]) {
    await assert.rejects(() => fn({ userId: 'u', product: { id: 'p' },
      supabaseClient: { rpc: async () => ({ error: { message: 'REQUEST_ID_CONFLICT' } }) },
    }), (error) => error.statusCode === 409);
  }

  const rows = Array.from({ length: 53 }, (_, i) => ({ id: `report-${i}`, price_cents: 200 }));
  const ordering = [];
  const query = {
    select() { return this; },
    eq(name, userId) { assert.equal(name, 'user_id'); assert.equal(userId, 'owner'); return this; },
    order(name) { ordering.push(name); return this; },
    async range(from, to) { return { data: rows.slice(from, to + 1) }; },
  };
  const supabaseClient = {
    from(name) { assert.equal(name, 'ai_report_orders'); return query; },
    rpc: async () => ({ error: null }),
  };
  assert.equal((await listAiReportsForUser('owner', { supabaseClient })).length, 50);
  const second = await listAiReportsForUser('owner', { page: 2, supabaseClient });
  assert.deepEqual(second.map((row) => row.id), ['report-50', 'report-51', 'report-52']);
  assert.deepEqual(ordering, ['created_at', 'id', 'created_at', 'id']);
  for (const page of [-1, 'abc', 1.5, Infinity]) {
    await assert.rejects(() => listAiReportsForUser('owner', { page, supabaseClient }), (error) => error.statusCode === 400);
  }
  console.log('Report settlement, retry conflict and pagination regressions passed');
}
main().catch((error) => { console.error(error); process.exitCode = 1; });

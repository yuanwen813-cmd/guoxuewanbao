const assert = require('node:assert/strict');
const { generateAiReport } = require('../server/aiReportService');
const { getTodayDailyReport } = require('../server/walletService');
const { processJob } = require('../server/aiReportWorker');

async function main() {
  delete process.env.AI_CLOUD_POLLING_ENABLED;
  delete process.env.AI_NATAL_WORKER_ENABLED;
  process.env.AI_ASYNC_REPORTS_ENABLED = 'true';
  process.env.AI_LONG_REPORTS_ENABLED = 'true';
  for (const productId of ['question_full_3_9', 'daily_hexagram_brief']) {
    let debits = 0;
    const tasks = [];
    let finish;
    const modelResult = new Promise((resolve) => { finish = resolve; });
    const order = {id: 'order', status: 'generating'};
    const result = await generateAiReport({userId: 'owner', body: {
      productId, expectedPointsCenti: 200, userPrompt: 'unchanged prompt',
      requestId: '7a2f6146-4e47-4b42-9d23-e23d85a15cb2',
    }, dependencies: {
      callDoubao: async ({userPrompt}) => {
        assert.equal(userPrompt, 'unchanged prompt');
        return modelResult;
      },
      waitUntil: (task) => tasks.push(task),
      createQueuedAiReportDebit: () => { throw new Error('Worker must not be required'); },
      createAiReportDebit: async (args) => {
        debits += 1;
        assert.equal(args.product.priceCents, 200);
        assert.match(args.promptSnapshot, /unchanged prompt/);
        assert.equal(args.requestId, '7a2f6146-4e47-4b42-9d23-e23d85a15cb2');
        return {order: {...order}, wallet: {}, alreadyPending: false};
      },
      completeAiReport: async ({resultText}) => {
        Object.assign(order, {status: 'completed', resultText});
        return {order: {...order}, wallet: {}};
      },
      recordServiceEventQuietly: () => {},
    }});
    assert.equal(result.pending, true);
    assert.equal(result.report.id, 'order');
    assert.equal(debits, 1);
    assert.equal(tasks.length, 1);
    assert.equal(order.status, 'generating');
    finish({answer: '完整报告', model: 'test'});
    await tasks[0];
    assert.equal(order.status, 'completed');
  }
  let requests = 0;
  await processJob({order_id: 'order', claim_token: 'claim', product_id: 'ziwei_basic',
    deadline_at: new Date(Date.now() - 1000).toISOString()}, {
    config: {model: 'test'}, requestAi: () => { requests += 1; },
    supabase: {rpc: async (name, args) => {
      assert.equal(name, 'settle_ai_report_job');
      assert.equal(args.p_result_text, null);
      assert.match(args.p_error_message, /15分钟/);
      return {data: {settled: true}, error: null};
    }},
  });
  assert.equal(requests, 0);
  await processJob({order_id: 'order', claim_token: 'claim', product_id: 'ziwei_basic',
    deadline_at: new Date(Date.now() + 60000).toISOString()}, {
    config: {model: 'test'}, requestAi: async ({config}) => {
      assert.ok(config.timeoutMs > 59000 && config.timeoutMs <= 60000);
      return {answer: '完整解析', model: 'test'};
    }, supabase: {rpc: async () => ({data: {settled: true}, error: null})},
  });
  const report = await getTodayDailyReport('current-owner', {supabaseClient: {
    rpc: async (name, args) => {
      assert.equal(name, 'get_today_daily_ai_report');
      assert.deepEqual(args, {p_user_id: 'current-owner'});
      return {error: null, data: {id: 'daily', status: 'completed', result_text: '今日报告',
        product_id: 'daily_hexagram_brief', price_cents: 200,
        question_result_json: {featureId: 'daily_hexagram'}}};
    },
  }});
  assert.equal(report.resultText, '今日报告');
  assert.equal(report.source.featureId, 'daily_hexagram');
  console.log('question/daily cloud polling, Worker deadline and daily ownership checks passed');
}
main().catch((error) => { console.error(error); process.exitCode = 1; });

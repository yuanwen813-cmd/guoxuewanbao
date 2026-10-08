const assert = require('node:assert/strict');
const { generateAiReport } = require('../server/aiReportService');
const { getAiProduct } = require('../server/productCatalog');
const { processJob } = require('../server/aiReportWorker');
const { HttpError } = require('../server/response');

async function main() {
  delete process.env.AI_NATAL_WORKER_ENABLED;
  delete process.env.AI_CLOUD_POLLING_ENABLED;
  delete process.env.ARK_API_KEY;
  const requestId = '19c1888c-96c4-4b3d-843f-1b69f1ebbd67';
  for (const productId of ['bazi_brief_1', 'bazi_basic_3_9', 'bazi_deep_6_9',
    'ziwei_brief', 'ziwei_basic', 'ziwei_deep', 'tieban_basic', 'tieban_deep',
    'bazi_brief', 'bazi_basic', 'bazi_deep']) {
    const body = {productId, title: '2 积分 AI 解析', expectedPointsCenti: 200,
      userPrompt: '原始出生资料，请解读。', systemPrompt: '', requestId,
      inputSnapshotJson: {birth: '1984-08-13 07:00'}};
    let queuedArgs;
    let order;
    let debits = 0;
    let modelCalls = 0;
    let balance = 1000;
    const dependencies = {
      buildAiReportSystemPrompt: () => 'unchanged system',
      createQueuedAiReportDebit: async (args) => {
        queuedArgs = args;
        const existing = Boolean(order);
        if (!existing) {
          debits++;
          balance -= 200;
          order = {id: 'natal-order', status: 'generating'};
        }
        return {order: {...order}, wallet: {balanceCents: balance}, alreadyPending: existing};
      },
      createAiReportDebit: () => { throw Error('Natal must not use the cloud debit path'); },
      callDoubao: () => { throw Error('Vercel must not generate a natal report'); },
      waitUntil: () => { throw Error('Natal must not register a Vercel task'); },
    };
    const run = () => generateAiReport({userId: 'owner', body, dependencies});
    const first = await run();
    assert.equal(first.pending, true);
    assert.equal(first.report.id, 'natal-order');
    assert.equal(queuedArgs.product.id, getAiProduct(productId).id);
    assert.equal(queuedArgs.product.priceCents, 200);
    assert.equal(queuedArgs.systemPrompt, 'unchanged system');
    assert.equal(queuedArgs.userPrompt, body.userPrompt);
    assert.equal(queuedArgs.promptSnapshot, `${body.title}\n\nunchanged system\n\n${body.userPrompt}`);
    assert.deepEqual(queuedArgs.inputSnapshotJson, body.inputSnapshotJson);
    assert.equal(queuedArgs.requestId, requestId);
    for (let i = 0; i < 3; i++) assert.equal((await run()).report.id, first.report.id);
    assert.equal(debits, 1);

    await processJob({order_id: first.report.id, claim_token: 'claim',
      product_id: queuedArgs.product.id, system_prompt: queuedArgs.systemPrompt,
      user_prompt: queuedArgs.userPrompt,
      deadline_at: new Date(Date.now() + 900000).toISOString()}, {
      config: {model: 'unchanged-model', timeoutMs: 270000},
      requestAi: async ({config, userPrompt, systemPrompt}) => {
        modelCalls++;
        assert.equal(config.model, 'unchanged-model');
        assert.ok(config.timeoutMs > 899000 && config.timeoutMs <= 900000);
        assert.equal(userPrompt, body.userPrompt);
        assert.equal(systemPrompt, 'unchanged system');
        return {answer: '完整命盘解析', model: config.model};
      },
      supabase: {rpc: async (name, args) => {
        assert.equal(name, 'settle_ai_report_job');
        assert.equal(args.p_order_id, first.report.id);
        assert.match(args.p_result_text, /完整命盘解析/);
        Object.assign(order, {status: 'completed', resultText: args.p_result_text});
        return {data: {settled: true}, error: null};
      }},
    });
    const reopened = await run();
    assert.equal(reopened.pending, false);
    assert.match(reopened.answer, /完整命盘解析/);
    assert.equal(debits, 1);
    assert.equal(modelCalls, 1);
    assert.equal(balance, 800);
    process.env.AI_CLOUD_POLLING_ENABLED = 'false';
    assert.equal((await run()).pending, false);
    delete process.env.AI_CLOUD_POLLING_ENABLED;
    order.status = 'refunded';
    await assert.rejects(run, (error) => error.statusCode === 409);
  }
  for (const statusCode of [402, 503]) {
    await assert.rejects(() => generateAiReport({userId: 'owner', body: {
      productId: 'ziwei_basic', expectedPointsCenti: 200, userPrompt: '原始命盘', requestId,
    }, dependencies: {
      buildAiReportSystemPrompt: () => '',
      createQueuedAiReportDebit: () => { throw new HttpError(statusCode, '本次未扣积分'); },
      createAiReportDebit: () => { throw Error('No silent cloud fallback'); },
      callDoubao: () => { throw Error('Must not call model'); },
      waitUntil: () => { throw Error('Must not schedule'); },
    }}), (error) => error.statusCode === statusCode);
  }
  console.log('NATAL_WORKER_TEST_PASSED: all natal products/aliases queued, same prompts/price, no Vercel model call, one debit, 15-minute Worker budget and offline/insufficient protection');
}
main().catch((error) => { console.error(error); process.exitCode = 1; });

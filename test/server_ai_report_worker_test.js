const assert = require('node:assert/strict');
const { ReadableStream } = require('node:stream/web');
const { generateAiReport } = require('../server/aiReportService');
const { processJob } = require('../server/aiReportWorker');
const { callDoubaoStream } = require('../server/doubaoClient');
const { createQueuedAiReportDebit } = require('../server/walletService');
const { getAiProduct } = require('../server/productCatalog');

const job = {
  order_id: 'order-1', claim_token: 'token-1', product_id: 'ziwei_basic',
  system_prompt: '', user_prompt: '请解读命盘',
};
const config = {
  apiKey: 'fake-key', baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
  model: 'test-model', timeoutMs: 10000,
};

function streamEvents(events) {
  const encoder = new TextEncoder();
  const content = events.map((event) => `data: ${JSON.stringify(event)}\n\n`).join('');
  const halfway = Math.floor(content.length / 2);
  return new ReadableStream({
    start(controller) {
      controller.enqueue(encoder.encode(content.slice(0, halfway)));
      controller.enqueue(encoder.encode(content.slice(halfway)));
      controller.close();
    },
  });
}

function fakeSupabase() {
  const calls = [];
  return {
    calls,
    rpc: async (name, args) => {
      calls.push({ name, args });
      return { data: { settled: true }, error: null };
    },
  };
}

async function run() {
  const oldFlag = process.env.AI_LONG_REPORTS_ENABLED;
  const oldFetch = global.fetch;
  try {
    process.env.AI_LONG_REPORTS_ENABLED = 'true';
    let charged = 0;
    let providerCalls = 0;
    const queued = await generateAiReport({
      userId: 'user-1',
      body: { productId: 'ziwei_basic', expectedPriceCents: 500, userPrompt: '命盘' },
      dependencies: {
        callDoubao: async () => { providerCalls += 1; },
        createQueuedAiReportDebit: async () => {
          charged += 1;
          return {
            order: { id: job.order_id, status: 'generating' },
            wallet: { balanceCents: 0 }, alreadyPending: false,
          };
        },
      },
    });
    assert.equal(queued.pending, true);
    assert.equal(queued.report.id, job.order_id);
    assert.equal(charged, 1);
    assert.equal(providerCalls, 0);

    await assert.rejects(() => createQueuedAiReportDebit({
      userId: 'user-1', product: getAiProduct('ziwei_basic'),
      userPrompt: '命盘',
      supabaseClient: {
        rpc: async () => ({ data: null, error: { message: 'AI_WORKER_UNAVAILABLE' } }),
      },
    }), (error) => error.statusCode === 503 && error.message.includes('未扣费'));

    const existing = await createQueuedAiReportDebit({
      userId: 'user-1', product: getAiProduct('ziwei_basic'),
      userPrompt: '命盘',
      supabaseClient: {
        rpc: async () => ({
          data: {
            order: { id: job.order_id, status: 'generating', price_cents: 500 },
            wallet: { balance_cents: 0 }, already_pending: true,
          }, error: null,
        }),
      },
    });
    assert.equal(existing.alreadyPending, true);
    assert.equal(existing.order.id, job.order_id);

    const db = fakeSupabase();
    await processJob(job, {
      supabase: db, config,
      requestAi: async () => ({ answer: '完整命盘解读', model: 'test-model', usage: {} }),
    });
    assert.equal(db.calls.length, 1);
    assert.equal(db.calls[0].name, 'settle_ai_report_job');
    assert.match(db.calls[0].args.p_result_text, /完整命盘解读/);
    assert.equal(db.calls[0].args.p_claim_token, job.claim_token);

    const failedDb = fakeSupabase();
    const savedWarn = console.warn;
    console.warn = () => {};
    try {
      await processJob(job, {
        supabase: failedDb, config,
        requestAi: async () => { throw new Error('AI 解析超时，请稍后重试'); },
      });
    } finally {
      console.warn = savedWarn;
    }
    assert.equal(failedDb.calls[0].args.p_result_text, null);
    assert.match(failedDb.calls[0].args.p_error_message, /超时/);

    global.fetch = async (_url, options) => {
      const body = JSON.parse(options.body);
      assert.equal(body.stream, true);
      assert.equal(body.store, false);
      return {
        ok: true,
        body: streamEvents([
          { type: 'response.output_text.delta', delta: '完整' },
          { type: 'response.output_text.delta', delta: '命盘解读' },
          { type: 'response.completed', response: {
            status: 'completed', model: 'test-model', output: [{
              type: 'message', role: 'assistant', status: 'completed',
              content: [{ type: 'output_text', text: '完整命盘解读' }],
            }], usage: { input_tokens: 2, output_tokens: 5 },
          } },
        ]),
      };
    };
    const streamed = await callDoubaoStream({ userPrompt: '命盘', config });
    assert.equal(streamed.answer, '完整命盘解读');
    assert.equal(streamed.usage.completion_tokens, 5);

    global.fetch = async () => ({
      ok: true,
      body: streamEvents([
        { type: 'response.output_text.delta', delta: '不完整内容' },
        { type: 'response.incomplete', response: { status: 'incomplete' } },
      ]),
    });
    await assert.rejects(() => callDoubaoStream({ userPrompt: '命盘', config }),
      (error) => error.statusCode === 424);
    global.fetch = async () => ({
      ok: true,
      body: streamEvents([{ type: 'response.output_text.delta', delta: '无完成事件' }]),
    });
    await assert.rejects(() => callDoubaoStream({ userPrompt: '命盘', config }),
      (error) => error.statusCode === 424);
  } finally {
    global.fetch = oldFetch;
    if (oldFlag === undefined) delete process.env.AI_LONG_REPORTS_ENABLED;
    else process.env.AI_LONG_REPORTS_ENABLED = oldFlag;
  }
  console.log('async AI report worker checks passed');
}

run().catch((error) => { console.error(error); process.exitCode = 1; });

const assert = require('node:assert/strict');
const { callDoubao, getDoubaoConfig } = require('../server/doubaoClient');
const { getAiProduct } = require('../server/productCatalog');
const { generateAiReport } = require('../server/aiReportService');
const { buildAiReportSystemPrompt } = require('../server/promptLoader');
const { HttpError } = require('../server/response');

async function run() {
  const originalFetch = global.fetch;
  const keys = ['ARK_API_KEY', 'ARK_BASE_URL', 'ARK_MODEL_ID', 'ARK_TIMEOUT_MS', 'AI_REPORT_SYSTEM_PROMPT'];
  const saved = Object.fromEntries(keys.map((key) => [key, process.env[key]]));
  try {
    for (const key of keys) delete process.env[key];
    process.env.ARK_API_KEY = 'fake-key-for-unit-tests';
    const productIds = [
      'question_brief_1', 'question_full_3_9', 'daily_hexagram_brief',
      'bazi_brief_1', 'bazi_basic_3_9', 'bazi_deep_6_9',
      'ziwei_brief', 'ziwei_basic', 'ziwei_deep', 'tieban_basic', 'tieban_deep',
      ...['coin_hexagram', 'xiaoliuren', 'meihua_yishu', 'gaodao_yiduan']
        .flatMap((id) => [`${id}_question_brief`, `${id}_question_full`]),
      'bazi_brief', 'bazi_basic', 'bazi_deep',
    ];
    for (const id of productIds) {
      assert.equal(getAiProduct(id).priceCents, 500);
      assert.equal(getAiProduct(id).model, 'doubao-seed-2-1-pro-260915');
    }
    process.env.ARK_MODEL_ID = 'ep-test-only';
    assert.equal(getAiProduct('bazi_basic').model, 'ep-test-only');
    delete process.env.ARK_MODEL_ID;
    const product = getAiProduct('question_full_3_9');
    const config = getDoubaoConfig();
    assert.equal(config.baseUrl, 'https://ark.cn-beijing.volces.com/api/v3');
    assert.equal(config.timeoutMs, 270000);
    const prompt = buildAiReportSystemPrompt('must not become a system rule');
    assert.ok(!prompt.includes('must not become a system rule'));
    assert.ok(prompt.includes('先给结论'));

    let calls = 0;
    const answer = '## 判断\n按卦理倾向不成。\n\n| 依据 | 内容 |\n| --- | --- |\n| 动爻 | 说明 |';
    const message = (text) => ({
      type: 'message', role: 'assistant', status: 'completed',
      content: [{ type: 'output_text', text }],
    });
    const successfulResponse = {
      status: 'completed', model: config.model,
      output: [{ type: 'reasoning', summary: [{ type: 'summary_text', text: 'internal reasoning' }] }, message(answer)],
      usage: { input_tokens: 30, output_tokens: 50, total_tokens: 80 },
    };
    global.fetch = async (url, options) => {
      calls += 1;
      assert.equal(url, `${config.baseUrl}/responses`);
      assert.equal(options.headers.Authorization, 'Bearer fake-key-for-unit-tests');
      const body = JSON.parse(options.body);
      assert.equal(body.model, 'doubao-seed-2-1-pro-260915');
      assert.equal(body.store, false);
      assert.deepEqual(body.input, [
        { role: 'system', content: [{ type: 'input_text', text: 'system' }] },
        { role: 'user', content: [{ type: 'input_text', text: 'user' }] },
      ]);
      assert.equal(body.messages, undefined);
      assert.equal(body.max_tokens, undefined);
      assert.equal(body.temperature, undefined);
      assert.equal(body.thinking, undefined);
      return {
        ok: true,
        json: async () => successfulResponse,
      };
    };
    const result = await callDoubao({ product, systemPrompt: 'system', userPrompt: 'user' });
    assert.equal(result.answer, answer);
    assert.equal(result.model, config.model);
    assert.deepEqual(result.usage, { prompt_tokens: 30, completion_tokens: 50, total_tokens: 80 });
    assert.equal(calls, 1);

    global.fetch = async () => ({ ok: true, json: async () => ({
      status: 'completed',
      output: [
        { ...message('first'), content: [{ type: 'output_text', text: 'first' }, { type: 'output_text', text: 'second' }] },
        message('third'),
        { ...message('not assistant text'), role: 'user' },
      ],
    }) });
    const multipleParts = await callDoubao({ product });
    assert.equal(multipleParts.answer, 'first\n\nsecond\n\nthird');
    assert.deepEqual(multipleParts.usage, { prompt_tokens: null, completion_tokens: null, total_tokens: null });

    const invalidResponses = [
      { status: 'completed', output: [message('  ')] },
      { status: 'completed', output: [{ type: 'reasoning', content: 'reasoning is not a report' }] },
      { status: 'completed', output: [null, { ...message(''), content: null }] },
      { status: 'completed', output: [message(42)] },
      { status: 'completed', output: {} },
      { status: 'completed', output: [{ ...message('partial'), status: 'incomplete' }] },
      { status: 'incomplete', incomplete_details: { reason: 'max_output_tokens' }, output: [message('partial')] },
      { status: 'incomplete', incomplete_details: { reason: 'content_filter' }, output: [message('filtered')] },
      { status: 'completed', output: [{ ...message(''), content: [{ type: 'refusal', refusal: 'no' }] }] },
      ...['in_progress', 'queued', 'failed', 'cancelled', undefined].map((status) => ({ status, output: [message('partial')] })),
      {}, null,
    ];
    for (const data of invalidResponses) {
      global.fetch = async () => ({ ok: true, json: async () => data });
      await assert.rejects(() => callDoubao({ product }), (error) => error.statusCode === 424);
    }
    global.fetch = async () => ({ ok: true, json: async () => ({ error: { message: 'secret provider details' } }) });
    await assert.rejects(() => callDoubao({ product }), (error) =>
      error.statusCode === 502 && !error.message.includes('secret provider details'));
    global.fetch = async () => ({ ok: false, json: async () => ({ error: { message: 'secret provider details' } }) });
    await assert.rejects(() => callDoubao({ product }), (error) =>
      error.statusCode === 502 && !error.message.includes('secret provider details'));
    global.fetch = (_, { signal }) => new Promise((resolve, reject) => {
      signal.addEventListener('abort', () => reject(new Error('aborted')), { once: true });
    });
    await assert.rejects(
      () => callDoubao({ product, config: { ...config, timeoutMs: 1 } }),
      (error) => error.statusCode === 504,
    );

    let debits = 0;
    let refunds = 0;
    let providerCalls = 0;
    let savedText;
    const dependencies = {
      createAiReportDebit: async ({ product: chargedProduct }) => {
        assert.equal(chargedProduct.priceCents, 500);
        debits += 1;
        return { order: { id: 'test-order' } };
      },
      callDoubao: async () => { providerCalls += 1; return { answer, model: product.model }; },
      completeAiReport: async ({ resultText }) => {
        savedText = resultText;
        return { order: { id: 'test-order' }, wallet: { balanceCents: 500 } };
      },
      refundAiReport: async () => { refunds += 1; return { order: {}, wallet: {} }; },
      recordServiceEventQuietly: () => {},
    };
    const body = { productId: product.id, expectedPriceCents: 500, userPrompt: '测试问题' };
    const generated = await generateAiReport({ userId: 'test-user', body, dependencies });
    assert.equal(savedText, generated.answer);
    assert.ok(generated.answer.startsWith('解卦为传统民俗文化内容，不能当作将发生的事实，仅作娱乐参考。'));
    assert.ok(generated.answer.endsWith(answer));
    assert.equal(debits, 1);
    assert.equal(refunds, 0);
    const natal = await generateAiReport({ userId: 'test-user', body: { ...body, productId: 'bazi_basic' }, dependencies });
    assert.ok(natal.answer.startsWith('命理解读为传统民俗文化内容'));

    const before = debits;
    for (const expectedPriceCents of [undefined, 100, 390, 690, '500', -500]) {
      await assert.rejects(
        () => generateAiReport({ userId: 'test-user', body: { ...body, expectedPriceCents }, dependencies }),
        (error) => error.statusCode === 409,
      );
    }
    assert.equal(debits, before);
    const beforeCalls = providerCalls;
    await assert.rejects(() => generateAiReport({
      userId: 'test-user', body,
      dependencies: { ...dependencies, createAiReportDebit: async () => { throw new HttpError(402, '余额不足'); } },
    }), (error) => error.statusCode === 402);
    assert.equal(providerCalls, beforeCalls);

    await assert.rejects(() => generateAiReport({
      userId: 'test-user', body,
      dependencies: { ...dependencies, callDoubao: async () => ({ answer: '' }) },
    }), /本次扣费已自动退回/);
    assert.equal(refunds, 1);

    // Exercise the actual Responses parser through the debit/refund service.
    const beforeInvalidDebits = debits;
    const beforeInvalidRefunds = refunds;
    let completions = 0;
    for (const data of invalidResponses) {
      global.fetch = async () => ({ ok: true, json: async () => data });
      await assert.rejects(() => generateAiReport({
        userId: 'test-user', body,
        dependencies: { ...dependencies, callDoubao, completeAiReport: async () => { completions += 1; } },
      }), /本次扣费已自动退回/);
    }
    assert.equal(debits - beforeInvalidDebits, invalidResponses.length);
    assert.equal(refunds - beforeInvalidRefunds, invalidResponses.length);
    assert.equal(completions, 0);

    global.fetch = async () => ({ ok: true, json: async () => successfulResponse });
    await generateAiReport({
      userId: 'test-user', body,
      dependencies: {
        ...dependencies, callDoubao,
        completeAiReport: async (args) => {
          assert.deepEqual(args.usage, { prompt_tokens: 30, completion_tokens: 50, total_tokens: 80 });
          completions += 1;
          return dependencies.completeAiReport(args);
        },
      },
    });
    assert.equal(completions, 1);
    assert.equal(savedText.endsWith(answer), true);
    delete process.env.ARK_API_KEY;
    const beforeConfigFailure = debits;
    await assert.rejects(() => generateAiReport({
      userId: 'test-user', body, dependencies: { ...dependencies, callDoubao: undefined },
    }), (error) => error.statusCode === 503);
    assert.equal(debits, beforeConfigFailure);
    process.env.ARK_API_KEY = 'fake-key-for-unit-tests';
    process.env.ARK_BASE_URL = 'https://example.invalid';
    assert.throws(() => getDoubaoConfig(), (error) => error.statusCode === 503);
  } finally {
    global.fetch = originalFetch;
    for (const key of keys) {
      if (saved[key] === undefined) delete process.env[key];
      else process.env[key] = saved[key];
    }
  }
}

run().then(() => console.log('Doubao provider and five-yuan pricing checks passed'))
  .catch((error) => { console.error(error); process.exitCode = 1; });

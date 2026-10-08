const assert = require('node:assert/strict');
const { generateAiReport } = require('../server/aiReportService');
const { HttpError, handleApi, sendJson } = require('../server/response');

const body = {
  productId: 'daily_hexagram_brief', expectedPointsCenti: 200,
  title: '2 积分 AI 解析', userPrompt: '每日一卦：乾为天，请解读。',
  requestId: '19c1888c-96c4-4b3d-843f-1b69f1ebbd67',
};

function scenario() {
  let release;
  const model = new Promise((resolve) => { release = resolve; });
  let order;
  const wallet = {balanceCents: 1000};
  const calls = {debit: 0, ai: 0, refund: 0, complete: 0};
  const dependencies = {
    getAiProduct: () => ({id: body.productId, reportType: 'daily_hexagram_brief',
      priceCents: 200, pricePoints: 2, enabled: true, model: 'test'}),
    buildAiReportSystemPrompt: () => '',
    createAiReportDebit: async (args) => {
      assert.equal(args.requestId, body.requestId);
      const existing = Boolean(order);
      if (!existing) {
        calls.debit++;
        wallet.balanceCents -= 200;
        order = {id: 'daily-order', status: 'generating', priceCents: 200};
      }
      return {order: {...order}, wallet: {...wallet}, alreadyPending: existing};
    },
    createQueuedAiReportDebit: () => { throw Error('Unexpected local Worker queue'); },
    callDoubao: async ({userPrompt}) => {
      assert.equal(userPrompt, body.userPrompt);
      calls.ai++;
      return model;
    },
    completeAiReport: async ({resultText}) => {
      calls.complete++;
      Object.assign(order, {status: 'completed', resultText});
      return {order: {...order}, wallet: {...wallet}};
    },
    refundAiReport: async ({errorMessage}) => {
      calls.refund++;
      if (order.status === 'generating') wallet.balanceCents += 200;
      Object.assign(order, {status: 'refunded', errorMessage});
      return {order: {...order}, wallet: {...wallet}};
    },
    recordServiceEventQuietly: () => {},
  };
  return {
    calls, wallet, dependencies, release,
    order: () => ({...order}),
    run: () => generateAiReport({userId: 'owner', body, dependencies}),
  };
}

async function main() {
  delete process.env.AI_CLOUD_POLLING_ENABLED;
  process.env.AI_LONG_REPORTS_ENABLED = 'true';
  process.env.AI_ASYNC_REPORTS_ENABLED = 'true';
  const symbol = Symbol.for('@vercel/request-context');
  const previousContext = globalThis[symbol];
  const tasks = [];
  // Exercise the installed Vercel SDK itself, not only an injected mock.
  globalThis[symbol] = {get: () => ({waitUntil: (task) => tasks.push(task)})};
  try {
    const cloud = scenario();
    let response;
    const res = {setHeader() {}, status(code) {this.code = code; return this;},
      json(data) {response = data;}};
    await handleApi(['POST'], async (_, reply) => {
      const result = await cloud.run();
      sendJson(reply, result.pending ? 202 : 200, {ok: true, ...result});
    })({method: 'POST', headers: {}}, res);
    assert.equal(res.code, 202);
    assert.equal(response.pending, true);
    assert.equal(response.report.id, 'daily-order');
    assert.equal(response.answer, '');
    assert.equal(cloud.order().status, 'generating');
    assert.equal(tasks.length, 1);
    for (let i = 0; i < 3; i++) {
      const retry = await cloud.run();
      assert.equal(retry.pending, true);
      assert.equal(retry.alreadyPending, true);
      assert.equal(retry.report.id, response.report.id);
    }
    assert.deepEqual(cloud.calls, {debit: 1, ai: 1, refund: 0, complete: 0});
    assert.equal(tasks.length, 1);
    cloud.release({answer: '本卦乾为天，卦辞强调自强不息，宜有计划地行动。', model: 'test'});
    await tasks[0];
    assert.equal(cloud.order().status, 'completed');
    assert.match(cloud.order().resultText, /自强不息/);
    assert.equal((await cloud.run()).pending, false);
    assert.equal(cloud.wallet.balanceCents, 800);
    assert.deepEqual(cloud.calls, {debit: 1, ai: 1, refund: 0, complete: 1});

    for (const failure of [
      new HttpError(504, 'AI 解析超时，请稍后重试'),
      new HttpError(502, 'AI 服务连接失败'),
      null,
    ]) {
      const failed = scenario();
      const owned = [];
      failed.dependencies.waitUntil = (task) => owned.push(task);
      failed.dependencies.callDoubao = async () => {
        failed.calls.ai++;
        if (failure) throw failure;
        return {answer: '很抱歉，不能为你解读卦象。', model: 'test'};
      };
      const pending = await failed.run();
      assert.equal(pending.pending, true);
      await owned[0];
      assert.equal(failed.order().status, 'refunded');
      assert.equal(failed.wallet.balanceCents, 1000);
      assert.equal(failed.calls.refund, 1);
      await assert.rejects(failed.run, (error) => error.statusCode === 409);
      assert.equal(failed.calls.ai, 1);
    }
    const notRegistered = scenario();
    notRegistered.dependencies.waitUntil = () => { throw Error('Registration failed'); };
    await assert.rejects(notRegistered.run,
      (error) => error.statusCode === 503 && error.details.refunded);
    assert.equal(notRegistered.calls.ai, 0);
    assert.equal(notRegistered.wallet.balanceCents, 1000);

    const insufficient = scenario();
    insufficient.dependencies.createAiReportDebit = async () => { throw new HttpError(402, '积分不足'); };
    insufficient.dependencies.waitUntil = () => { throw Error('Must not schedule'); };
    await assert.rejects(insufficient.run, (error) => error.statusCode === 402);
    assert.equal(insufficient.calls.ai, 0);

    const uncertain = scenario();
    const uncertainTasks = [];
    uncertain.dependencies.waitUntil = (task) => uncertainTasks.push(task);
    uncertain.dependencies.completeAiReport = async () => { throw Error('DB unavailable'); };
    uncertain.dependencies.getAiReportForUser = async () => { throw Error('DB unavailable'); };
    await uncertain.run();
    uncertain.release({answer: '完整解析', model: 'test'});
    await uncertainTasks[0];
    assert.equal(uncertain.calls.ai, 1);
    assert.equal(uncertain.calls.refund, 0);
    assert.equal(uncertain.order().status, 'generating');

    console.log('CLOUD_POLLING_TEST_PASSED: immediate response, Vercel lifecycle, same-order retries, success, failure/refusal refund, launch failure and uncertain settlement');
  } finally {
    if (previousContext === undefined) delete globalThis[symbol];
    else globalThis[symbol] = previousContext;
  }
}
main().catch((error) => { console.error(error); process.exitCode = 1; });

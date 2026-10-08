const assert = require('node:assert/strict');
process.env.AI_CLOUD_POLLING_ENABLED = 'false';
const { assessAiReport } = require('../server/aiReportQuality');
const { normalizeReportUserPrompt } = require('../server/aiReportInput');
const { generateAiReport } = require('../server/aiReportService');
const { processJob } = require('../server/aiReportWorker');
const { handleApi } = require('../server/response');

const refused = '占卜属于封建迷信，其结果并没有科学依据，不能据此预判假期是否顺利，因此很抱歉不能为你解读卦象。\n建议提前做好出行攻略、关注交通和天气信息。';
async function run() {
  for (const text of [refused, refused + '祝你旅途愉快。'.repeat(100),
    '很抱歉，我无法提供命理解读。建议通过努力改善生活。',
    "I cannot interpret your hexagram. Please plan your trip.", '']) {
    assert.equal(assessAiReport(text).accepted, false, text);
  }
  for (const text of ['泰卦提示由顺转变，九三强调守正。', '倾向不成。',
    '没有科学依据，仅供娱乐参考。泰卦提示顺境中也要准备变化。',
    '不是不能解卦，只能作为传统文化参考。',
    '有人说“不能为你解读卦象”，这里提供文化解释。',
    '不能通过解卦判断身体是否患病。动爻提示适度休息，症状应就医。',
    '不能提供命理解读的事实保证。日主偏弱，财星旺，传统上强调扶助日主。',
    '我无法为你解卦预测事实。九三爻辞强调居安思危。']) {
    assert.equal(assessAiReport(text).accepted, true, text);
  }
  const source = { featureName: '高岛易断', summary: '泰之临',
    userQuestion: '这个假期我的手臂会出问题吗？', castTimeUtc: '2026-09-29T01:34:06.952Z',
    primaryHexagram: { name: '地天泰', judgment: '小往大来，吉亨。' },
    movingYao: { lineName: '九三', text: '无平不陂，无往不复。' },
    changedHexagram: { name: '地泽临' }, flags: { isMedical: true },
    featureId: 'internal-id', aiReports: [{ secret: 'old report' }] };
  const original = `问事\n原始起卦时间：2026-09-29T09:34:06.952+08:00\n原始资料：\n${JSON.stringify(source)}\n请解读。`;
  const formatted = normalizeReportUserPrompt(original);
  for (const value of [source.userQuestion, source.castTimeUtc, '09:34:06.952+08:00', '地天泰', '九三', '无平不陂', '地泽临']) assert.ok(formatted.includes(value));
  for (const value of ['isMedical', 'internal-id', 'old report', '"primaryHexagram"']) assert.ok(!formatted.includes(value));
  for (const raw of ['出生资料：1984-08-13 07:00 男', 'broken {', '{"other":true}']) {
    const prompt = `命盘\n原始资料：\n${raw}\n请解读。`;
    assert.equal(normalizeReportUserPrompt(prompt), prompt);
  }
  const generic = `问事\n原始资料：\n${JSON.stringify({featureName: '小六壬', summary: '大安', chartSections: [{title: '落宫', rows: [{label: '性质', value: '大安'}]}]})}\n请解读。`;
  assert.match(normalizeReportUserPrompt(generic), /性质：大安/);

  let aiCalls = 0;
  let refunds = 0;
  let completions = 0;
  const order = { id: 'test-order', status: 'generating', priceCents: 200 };
  const dependencies = {
    createAiReportDebit: async () => ({order}),
    callDoubao: async ({systemPrompt, userPrompt}) => {
      aiCalls += 1;
      assert.match(systemPrompt, /传统文化体系/);
      assert.equal(userPrompt, formatted);
      return {answer: refused};
    },
    completeAiReport: async () => { completions += 1; },
    refundAiReport: async () => { refunds += 1; return {order: {...order, status: 'refunded'}, wallet: {balanceCents: 1000}}; },
    recordServiceEventQuietly: () => {},
  };
  const body = {productId: 'question_full_3_9', expectedPointsCenti: 200, userPrompt: original};
  let response;
  const res = {setHeader() {}, status(code) {this.code = code; return this;}, json(data) {response = data;}};
  await handleApi(['POST'], async () => generateAiReport({userId: 'test-user', body, dependencies}))({method: 'POST', headers: {}}, res);
  assert.equal(res.code, 424);
  assert.match(response.error, /2 积分已退回/);
  assert.equal(response.report.status, 'refunded');
  assert.equal(response.wallet.balanceCents, 1000);
  assert.equal(aiCalls, 1);
  assert.equal(refunds, 1);
  assert.equal(completions, 0);
  await assert.rejects(() => generateAiReport({userId: 'test-user', body, dependencies: {
    ...dependencies, createAiReportDebit: async () => ({order: {...order, status: 'refunded'}, alreadyPending: true}),
  }}), (error) => error.statusCode === 409);
  assert.equal(aiCalls, 1);
  assert.equal(refunds, 1);

  let settlement;
  const warn = console.warn;
  console.warn = () => {};
  try {
    await processJob({order_id: 'queued-order', claim_token: 'claim', product_id: 'ziwei_basic', system_prompt: '', user_prompt: '命盘'}, {
      supabase: {rpc: async (name, args) => {assert.equal(name, 'settle_ai_report_job'); settlement = args; return {data: {settled: true}, error: null};}},
      config: {}, requestAi: async () => ({answer: '很抱歉，无法提供命理解读。'}),
    });
  } finally { console.warn = warn; }
  assert.equal(settlement.p_result_text, null);
  assert.match(settlement.p_error_message, /未提供实质解析/);
}
run().then(() => console.log('AI delivery, readable input, refusal refund and worker checks passed'))
  .catch((error) => {console.error(error); process.exitCode = 1;});

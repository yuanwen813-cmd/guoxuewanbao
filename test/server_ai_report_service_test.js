const assert = require('node:assert/strict');

const { ensureAiAnswer } = require('../server/aiReportService');
const { isInvalidAiReportText } = require('../server/walletService');

assert.equal(ensureAiAnswer('  有效的 AI 报告  '), '有效的 AI 报告');
assert.throws(
  () => ensureAiAnswer('   '),
  (error) => error.statusCode === 424 && error.message === 'AI 服务未返回有效内容',
);
assert.equal(isInvalidAiReportText(''), true);
assert.equal(isInvalidAiReportText('AI 服务未返回内容。'), true);
assert.equal(isInvalidAiReportText('有效的 AI 报告'), false);

console.log('server ai report empty-response checks passed');

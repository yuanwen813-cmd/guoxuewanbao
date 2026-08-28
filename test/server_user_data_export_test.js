const assert = require('node:assert/strict');

const { buildAccountExportData } = require('../server/userDataService');

const exported = buildAccountExportData({
  account: {
    id: 'internal-user-id',
    auth_user_id: 'internal-auth-id',
    phone: '13800000000',
    nickname: '测试用户',
    status: 'active',
    created_at: '2026-08-28T12:00:00Z',
  },
  wallet: {
    id: 'internal-wallet-id',
    balance_cents: 390,
    currency: 'CNY',
  },
  walletTransactions: [
    {
      id: 'transaction-id',
      type: 'recharge',
      amount_cents: 390,
      balance_after_cents: 390,
      ref_id: 'private-reference',
      out_trade_no: 'PRIVATE_ORDER_ID',
      created_at: '2026-08-28T12:00:00Z',
    },
  ],
  rechargeOrders: [
    {
      id: 'recharge-id',
      out_trade_no: 'PRIVATE_ORDER_ID',
      provider_trade_no: 'PRIVATE_PROVIDER_TRADE',
      provider: 'alipay',
      trade_type: 'web_pc',
      amount_cents: 100,
      status: 'paid',
      pay_url: 'https://payment.example/private-link',
      raw_create_response: { signature: 'private-signature' },
    },
  ],
  aiReports: [
    {
      id: 'report-id',
      product_id: 'question_full_3_9',
      report_type: 'question_full',
      price_cents: 390,
      status: 'completed',
      prompt_snapshot: 'internal prompt',
      input_snapshot_json: { internal: true },
      question_result_json: { internal: true },
      result_text: '用户可查看的 AI 报告。',
    },
  ],
  histories: [
    {
      id: 'history-id',
      featureName: '金钱卦',
      question: '这次合作是否顺利？',
      summary: '结果摘要',
      resultJson: '{"internal":true}',
      createdAt: '2026-08-28T12:00:00Z',
    },
  ],
  birthProfiles: [
    {
      id: 'profile-id',
      ownerUserId: 'internal-owner-id',
      displayName: '本人',
      relationship: 'self',
      gender: 'female',
      gregorianBirthDateTime: '1990-06-12T08:30:00Z',
    },
  ],
});

const serialized = JSON.stringify(exported);
for (const forbidden of [
  'internal-user-id',
  'internal-auth-id',
  'internal-wallet-id',
  'transaction-id',
  'recharge-id',
  'report-id',
  'history-id',
  'profile-id',
  'PRIVATE_ORDER_ID',
  'PRIVATE_PROVIDER_TRADE',
  'payment.example/private-link',
  'private-signature',
  'internal prompt',
  'internal-owner-id',
  'resultJson',
]) {
  assert.equal(serialized.includes(forbidden), false, `must not export ${forbidden}`);
}
assert.equal(exported.wallet.balanceCents, 390);
assert.equal(exported.aiReports[0].resultText, '用户可查看的 AI 报告。');
assert.equal(exported.histories[0].question, '这次合作是否顺利？');

console.log('server account export redaction checks passed');

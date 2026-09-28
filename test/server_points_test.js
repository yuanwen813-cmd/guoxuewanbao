const assert = require('node:assert/strict');
const { getAiProduct, validateRechargeAmount } = require('../server/productCatalog');
const { generateAiReport } = require('../server/aiReportService');
const {
  createAiReportDebit,
  createQueuedAiReportDebit,
  grantRegistrationBonusIfEligible,
  markRechargePaid,
} = require('../server/walletService');

const requestId = '7a2f6146-4e47-4b42-9d23-e23d85a15cb2';

async function run() {
  assert.equal(getAiProduct('question_full_3_9').pricePoints, 2);
  assert.equal(getAiProduct('bazi_basic_3_9').priceCents, 200);
  assert.equal(getAiProduct('analysis_all_2_coin_hexagram'), null);
  assert.equal(getAiProduct('analysis_all_2_unknown'), null);
  assert.equal(getAiProduct(null), null);
  assert.equal(getAiProduct('constructor'), null);
  for (const amount of [1000, 2000, 5000, 10000]) {
    assert.equal(validateRechargeAmount(amount).ok, true);
  }
  for (const amount of [-100, 0, 390, 99901, 10.5]) {
    assert.equal(validateRechargeAmount(amount).ok, false);
  }

  const bonusCalls = [];
  const bonusClient = {
    rpc: async (name, args) => {
      bonusCalls.push({ name, args });
      return { data: { eligible: true, granted: false, already_granted: true,
        wallet: { balance_cents: 1000, points_balance: 10 } }, error: null };
    },
  };
  const bonus = await grantRegistrationBonusIfEligible('user-1', { supabaseClient: bonusClient });
  assert.equal(bonusCalls[0].name, 'grant_registration_bonus');
  assert.equal(bonus.granted, false);
  assert.equal(bonus.alreadyGranted, true);
  assert.equal(bonus.wallet.pointsBalance, 10);

  const debitCalls = [];
  const debit = await createAiReportDebit({
    userId: 'user-1', product: getAiProduct('question_full_3_9'), requestId,
    promptSnapshot: 'same request',
    supabaseClient: { rpc: async (name, args) => {
      debitCalls.push({ name, args });
      return { data: {
        order: { id: 'report-1', product_id: 'question_full_3_9',
          price_cents: 200, status: 'generating', charge_unit: 'POINTS' },
        wallet: { balance_cents: 800, points_balance: 8 },
        already_pending: false,
      }, error: null };
    } },
  });
  assert.equal(debitCalls[0].name, 'create_ai_report_debit_once');
  assert.equal(debitCalls[0].args.p_request_id, requestId);
  assert.equal(debitCalls[0].args.p_price_cents, 200);
  assert.equal(debit.wallet.pointsBalance, 8);
  assert.equal(debit.order.pricePoints, 2);
  assert.equal(debit.order.chargeUnit, 'POINTS');

  const queuedCalls = [];
  await createQueuedAiReportDebit({
    userId: 'user-1', product: getAiProduct('ziwei_basic'), requestId,
    userPrompt: 'chart',
    supabaseClient: { rpc: async (name, args) => {
      queuedCalls.push({ name, args });
      return { data: {
        order: { id: 'report-2', price_cents: 200, status: 'generating' },
        wallet: { balance_cents: 800 }, already_pending: false,
      }, error: null };
    } },
  });
  assert.equal(queuedCalls[0].name, 'start_ai_report_job_once');
  assert.equal(queuedCalls[0].args.p_request_id, requestId);

  let providerCalls = 0;
  const report = await generateAiReport({
    userId: 'user-1',
    body: { productId: 'question_full_3_9', expectedPointsCenti: 200,
      requestId, userPrompt: 'question' },
    dependencies: {
      buildAiReportSystemPrompt: () => '',
      createAiReportDebit: async () => ({
        alreadyPending: true,
        order: { id: 'report-1', status: 'completed', resultText: 'saved report' },
        wallet: { balanceCents: 800 },
      }),
      callDoubao: async () => { providerCalls += 1; },
    },
  });
  assert.equal(report.answer, 'saved report');
  assert.equal(providerCalls, 0);

  let rejectedDebitCalls = 0;
  for (const body of [
    { productId: 'question_full_3_9', expectedPointsCenti: 500 },
    { productId: 'analysis_all_2_coin_hexagram', expectedPointsCenti: 200 },
  ]) {
    await assert.rejects(() => generateAiReport({
      userId: 'user-1', body: { ...body, userPrompt: 'question' },
      dependencies: { createAiReportDebit: async () => { rejectedDebitCalls += 1; } },
    }), (error) => error.statusCode === 409 || error.statusCode === 400);
  }
  assert.equal(rejectedDebitCalls, 0);

  await assert.rejects(() => generateAiReport({
    userId: 'user-1',
    body: { productId: 'question_full_3_9', expectedPriceCents: 500,
      requestId, userPrompt: 'old client' },
    dependencies: {
      createAiReportDebit: async () => { throw new Error('old client was charged'); },
    },
  }), (error) => error.statusCode === 409 && error.message.includes('更新应用'));

  const paid = await markRechargePaid({
    outTradeNo: 'ALI-test', providerTradeNo: 'provider-1',
    amountCents: 5000,
    supabaseClient: { rpc: async (name, args) => {
      assert.equal(name, 'mark_recharge_paid');
      assert.equal(args.p_amount_cents, 5000);
      return { data: {
        order: { id: 'recharge-1', amount_cents: 5000, status: 'paid' },
        wallet: { balance_cents: 5000, points_balance: 50 },
        already_paid: true,
      }, error: null };
    } },
  });
  assert.equal(paid.wallet.pointsBalance, 50);
  assert.equal(paid.order.pointsGranted, 50);
  assert.equal(paid.alreadyPaid, true);
}

run().then(() => console.log('points service contracts passed')).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

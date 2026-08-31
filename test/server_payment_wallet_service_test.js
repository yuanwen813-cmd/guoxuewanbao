const assert = require('node:assert/strict');

const { HttpError } = require('../server/response');
const { generateAiReport } = require('../server/aiReportService');
const {
  completeAiReport,
  createAiReportDebit,
  markRechargePaid,
  refundAiReport,
} = require('../server/walletService');
const { handleAlipayNotify } = require('../server/paymentService');

function walletRow(balance = 500) {
  return {
    balance_cents: balance,
    currency: 'CNY',
    updated_at: '2026-08-31T00:00:00Z',
  };
}

function reportRow(status = 'generating') {
  return {
    id: 'report-1',
    product_id: 'question_full_3_9',
    report_type: 'question_full',
    price_cents: 390,
    currency: 'CNY',
    status,
    created_at: '2026-08-31T00:00:00Z',
    updated_at: '2026-08-31T00:00:00Z',
  };
}

async function run() {
  const rpcCalls = [];
  const paid = await markRechargePaid({
    outTradeNo: 'ALI_TEST_001',
    providerTradeNo: 'provider-001',
    amountCents: 390,
    notifyLogId: 'notify-1',
    rawPayload: { trade_status: 'TRADE_SUCCESS' },
    supabaseClient: {
      rpc: async (name, payload) => {
        rpcCalls.push({ name, payload });
        return {
          data: {
            order: {
              id: 'order-1',
              out_trade_no: 'ALI_TEST_001',
              provider: 'alipay',
              trade_type: 'web_pc',
              amount_cents: 390,
              status: 'paid',
            },
            wallet: walletRow(890),
            already_paid: true,
          },
          error: null,
        };
      },
    },
  });
  assert.equal(paid.alreadyPaid, true);
  assert.equal(paid.wallet.balanceCents, 890);
  assert.equal(rpcCalls[0].name, 'mark_recharge_paid');
  assert.equal(rpcCalls[0].payload.p_amount_cents, 390);

  await assert.rejects(
    () =>
      markRechargePaid({
        outTradeNo: 'ALI_TEST_002',
        amountCents: 100,
        supabaseClient: {
          rpc: async () => ({
            data: null,
            error: { message: 'RECHARGE_AMOUNT_MISMATCH' },
          }),
        },
      }),
    (error) => error instanceof HttpError && error.statusCode === 400,
  );

  await assert.rejects(
    () =>
      createAiReportDebit({
        userId: 'user-1',
        product: {
          id: 'question_full_3_9',
          reportType: 'question_full',
          priceCents: 390,
        },
        supabaseClient: {
          rpc: async () => ({
            data: null,
            error: { message: 'INSUFFICIENT_BALANCE' },
          }),
        },
      }),
    (error) => error instanceof HttpError && error.statusCode === 402,
  );

  await assert.rejects(
    () => completeAiReport({ orderId: 'report-1', resultText: '   ' }),
    (error) => error instanceof HttpError && error.statusCode === 424,
  );

  const refunded = await refundAiReport({
    orderId: 'report-1',
    errorMessage: 'timeout',
    supabaseClient: {
      rpc: async (name) => {
        assert.equal(name, 'refund_ai_report_order');
        return {
          data: { order: reportRow('refunded'), wallet: walletRow(500), already_refunded: true },
          error: null,
        };
      },
    },
  });
  assert.equal(refunded.alreadyRefunded, true);
  assert.equal(refunded.order.status, 'refunded');

  const notifyUpdates = [];
  const notifyResult = await handleAlipayNotify({
    headers: { 'x-test': '1' },
    rawBody: 'out_trade_no=ALI_TEST_003&trade_no=provider-003',
    dependencies: {
      insertPaymentNotifyLog: async (payload) => {
        assert.equal(payload.provider, 'alipay');
        assert.equal(payload.outTradeNo, 'ALI_TEST_003');
        return { id: 'notify-3' };
      },
      parseAlipayNotify: () => ({
        outTradeNo: 'ALI_TEST_003',
        providerTradeNo: 'provider-003',
        amountCents: 100,
        parsed: { trade_status: 'TRADE_SUCCESS' },
      }),
      markRechargePaid: async (payload) => {
        assert.equal(payload.amountCents, 100);
        assert.equal(payload.notifyLogId, 'notify-3');
        return { alreadyPaid: true };
      },
      markPaymentNotifyLog: async (id, patch) => notifyUpdates.push({ id, patch }),
      recordServiceEventQuietly: () => {},
    },
  });
  assert.equal(notifyResult.alreadyPaid, true);
  assert.deepEqual(notifyUpdates, [
    { id: 'notify-3', patch: { verified: true, handled: true } },
  ]);

  const failedNotifyUpdates = [];
  await assert.rejects(
    () =>
      handleAlipayNotify({
        headers: {},
        rawBody: 'out_trade_no=ALI_TEST_004',
        dependencies: {
          insertPaymentNotifyLog: async () => ({ id: 'notify-4' }),
          parseAlipayNotify: () => {
            throw new Error('signature invalid');
          },
          markPaymentNotifyLog: async (id, patch) =>
            failedNotifyUpdates.push({ id, patch }),
          recordServiceEventQuietly: () => {},
        },
      }),
    /signature invalid/,
  );
  assert.equal(failedNotifyUpdates[0].patch.verified, false);
  assert.equal(failedNotifyUpdates[0].patch.handled, false);

  let debitCalls = 0;
  let refundCalls = 0;
  await assert.rejects(
    () =>
      generateAiReport({
        userId: 'user-1',
        body: { productId: 'question_full_3_9', userPrompt: '测试问题' },
        dependencies: {
          getAiProduct: () => ({
            id: 'question_full_3_9',
            reportType: 'question_full',
            priceCents: 390,
            model: 'deepseek-v4-pro',
            maxTokens: 100,
            enabled: true,
          }),
          buildAiReportSystemPrompt: () => 'system prompt',
          createAiReportDebit: async () => {
            debitCalls += 1;
            return { order: reportRow(), wallet: walletRow(110) };
          },
          callDeepSeek: async () => {
            throw new HttpError(503, 'AI 服务暂时不可用');
          },
          refundAiReport: async () => {
            refundCalls += 1;
            return { order: reportRow('refunded'), wallet: walletRow(500) };
          },
          recordServiceEventQuietly: () => {},
        },
      }),
    (error) =>
      error instanceof HttpError &&
      error.statusCode === 500 &&
      error.message.includes('本次扣费已自动退回'),
  );
  assert.equal(debitCalls, 1);
  assert.equal(refundCalls, 1);
}

run()
  .then(() => console.log('server payment, wallet, and refund checks passed'))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });

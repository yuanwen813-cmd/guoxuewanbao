const assert = require('assert');
const {
  recordServiceEvent,
  sanitizeContext,
} = require('../server/monitoringService');

async function run() {
  const sanitized = sanitizeContext({
    productId: 'question_brief_1',
    orderId: 'order-1',
    phone: '13800000000',
    token: 'should-not-be-stored',
    prompt: 'should-not-be-stored',
    retry: true,
  });
  assert.deepStrictEqual(sanitized, {
    productId: 'question_brief_1',
    orderId: 'order-1',
    retry: true,
  });

  let inserted;
  const insertedOk = await recordServiceEvent(
    {
      category: 'payment',
      eventType: 'payment_notify_failed',
      severity: 'error',
      message: '支付回调处理失败',
      context: {
        provider: 'alipay',
        outTradeNo: 'ALI-1',
        rawBody: 'private',
        phone: '13800000000',
      },
    },
    {
      supabaseClient: {
        from(table) {
          assert.strictEqual(table, 'service_event_logs');
          return {
            async insert(payload) {
              inserted = payload;
              return { error: null };
            },
          };
        },
      },
    },
  );
  assert.strictEqual(insertedOk, true);
  assert.deepStrictEqual(inserted.context_json, {
    provider: 'alipay',
    outTradeNo: 'ALI-1',
  });

  const unavailable = await recordServiceEvent(
    { category: 'api', eventType: 'unavailable', message: 'x' },
    {
      supabaseClient: {
        from() {
          return {
            async insert() {
              return { error: { code: '42P01', message: 'service_event_logs missing' } };
            },
          };
        },
      },
    },
  );
  assert.strictEqual(unavailable, false);
  console.log('server monitoring redaction checks passed');
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

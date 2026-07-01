const { HttpError } = require('./response');
const { validateRechargeAmount } = require('./productCatalog');
const {
  createRechargeOrder,
  insertPaymentNotifyLog,
  markPaymentNotifyLog,
  markRechargePaid,
  updateRechargeOrderPayment,
} = require('./walletService');
const { createWechatPayment, parseWechatNotify } = require('./wechatPay');
const { createAlipayPayment, parseAlipayNotify } = require('./alipay');

const providers = new Set(['wechat', 'alipay']);
const tradeTypes = new Set([
  'web_native',
  'web_pc',
  'qr',
  'h5',
  'app',
  'mini_program',
]);

function normalizeProvider(provider) {
  const value = String(provider || '').trim();
  if (!providers.has(value)) throw new HttpError(400, '充值渠道不支持');
  return value;
}

function normalizeTradeType(tradeType) {
  const value = String(tradeType || 'web_native').trim();
  if (!tradeTypes.has(value)) throw new HttpError(400, '支付场景不支持');
  return value;
}

async function createRecharge({ userId, provider, tradeType, amountCents }) {
  const checked = validateRechargeAmount(amountCents);
  if (!checked.ok) throw new HttpError(400, checked.message);

  const normalizedProvider = normalizeProvider(provider);
  const normalizedTradeType = normalizeTradeType(tradeType);
  const order = await createRechargeOrder({
    userId,
    provider: normalizedProvider,
    tradeType: normalizedTradeType,
    amountCents: checked.amountCents,
  });

  const payment =
    normalizedProvider === 'wechat'
      ? await createWechatPayment(order)
      : await createAlipayPayment(order);

  const updatedOrder = await updateRechargeOrderPayment(order.id, {
    prepayId: payment.prepayId,
    codeUrl: payment.codeUrl,
    payUrl: payment.payUrl,
    rawCreateResponse: payment.rawCreateResponse,
  });

  return {
    order: updatedOrder,
    payment: {
      provider: normalizedProvider,
      tradeType: normalizedTradeType,
      paymentReady: Boolean(payment.paymentReady),
      codeUrl: payment.codeUrl || null,
      payUrl: payment.payUrl || null,
      prepayId: payment.prepayId || null,
      message:
        payment.rawCreateResponse?.message ||
        (payment.paymentReady ? '支付订单已创建' : '支付能力已预留'),
    },
  };
}

async function handleWechatNotify({ headers, rawBody }) {
  let log;
  try {
    let rawParsed = {};
    try {
      rawParsed = JSON.parse(rawBody || '{}');
    } catch (_) {
      rawParsed = { parseError: true };
    }
    log = await insertPaymentNotifyLog({
      provider: 'wechat',
      headersJson: headers,
      rawBody,
      parsedJson: rawParsed,
    });
    const parsed = parseWechatNotify(headers, rawBody);
    const result = await markRechargePaid({
      outTradeNo: parsed.outTradeNo,
      providerTradeNo: parsed.providerTradeNo,
      amountCents: parsed.amountCents,
      notifyLogId: log.id,
      rawPayload: parsed.decrypted,
    });
    await markPaymentNotifyLog(log.id, { verified: true, handled: true });
    return result;
  } catch (error) {
    if (log?.id) {
      await markPaymentNotifyLog(log.id, {
        verified: false,
        handled: false,
        errorMessage: error.message,
      });
    }
    throw error;
  }
}

async function handleAlipayNotify({ headers, rawBody }) {
  let log;
  try {
    const parsed = Object.fromEntries(new URLSearchParams(rawBody || '').entries());
    log = await insertPaymentNotifyLog({
      provider: 'alipay',
      headersJson: headers,
      rawBody,
      parsedJson: parsed,
      outTradeNo: parsed.out_trade_no,
      providerTradeNo: parsed.trade_no,
    });
    const verified = parseAlipayNotify(rawBody);
    const result = await markRechargePaid({
      outTradeNo: verified.outTradeNo,
      providerTradeNo: verified.providerTradeNo,
      amountCents: verified.amountCents,
      notifyLogId: log.id,
      rawPayload: verified.parsed,
    });
    await markPaymentNotifyLog(log.id, { verified: true, handled: true });
    return result;
  } catch (error) {
    if (log?.id) {
      await markPaymentNotifyLog(log.id, {
        verified: false,
        handled: false,
        errorMessage: error.message,
      });
    }
    throw error;
  }
}

module.exports = {
  createRecharge,
  handleAlipayNotify,
  handleWechatNotify,
};

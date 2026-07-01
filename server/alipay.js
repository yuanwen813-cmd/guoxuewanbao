const crypto = require('crypto');
const { HttpError } = require('./response');

function getAlipayConfig() {
  return {
    appId: process.env.ALIPAY_APP_ID,
    privateKey: process.env.ALIPAY_PRIVATE_KEY,
    publicKey: process.env.ALIPAY_PUBLIC_KEY,
    notifyUrl: process.env.ALIPAY_NOTIFY_URL,
    gateway: process.env.ALIPAY_GATEWAY || 'https://openapi.alipay.com/gateway.do',
  };
}

function isAlipayConfigured() {
  const config = getAlipayConfig();
  return Boolean(config.appId && config.privateKey && config.publicKey && config.notifyUrl);
}

function normalizeKey(raw) {
  return String(raw || '').replace(/\\n/g, '\n');
}

function centsToYuanString(cents) {
  const value = Number(cents);
  const major = Math.floor(value / 100);
  const minor = value % 100;
  return `${major}.${String(minor).padStart(2, '0')}`;
}

function yuanStringToCents(value) {
  const text = String(value || '0').trim();
  const match = text.match(/^(\d+)(?:\.(\d{1,2}))?$/);
  if (!match) return 0;
  return Number(match[1]) * 100 + Number((match[2] || '').padEnd(2, '0'));
}

function canonicalQuery(params) {
  return Object.keys(params)
    .filter((key) => params[key] !== undefined && params[key] !== null && params[key] !== '')
    .sort()
    .map((key) => `${key}=${params[key]}`)
    .join('&');
}

function signAlipay(params) {
  return crypto
    .createSign('RSA-SHA256')
    .update(canonicalQuery(params), 'utf8')
    .sign(normalizeKey(getAlipayConfig().privateKey), 'base64');
}

async function createAlipayPayment(order) {
  if (!isAlipayConfigured()) {
    if (process.env.NODE_ENV === 'production') {
      throw new HttpError(503, '支付宝支付尚未配置完整');
    }
    return {
      paymentReady: false,
      payUrl: `${getAlipayConfig().gateway}?mock_out_trade_no=${order.outTradeNo}`,
      rawCreateResponse: {
        mock: true,
        message: '开发环境未配置支付宝密钥，返回占位支付链接。',
      },
    };
  }

  if (!['web_native', 'web_pc', 'qr'].includes(order.tradeType)) {
    return {
      paymentReady: false,
      payUrl: null,
      rawCreateResponse: {
        reserved: true,
        message: `${order.tradeType} 已预留，第一版优先支持 Web 支付链接。`,
      },
    };
  }

  const bizContent = JSON.stringify({
    out_trade_no: order.outTradeNo,
    total_amount: centsToYuanString(order.amountCents),
    subject: '国学万宝匣余额充值',
    product_code: 'FAST_INSTANT_TRADE_PAY',
  });
  const params = {
    app_id: getAlipayConfig().appId,
    method: 'alipay.trade.page.pay',
    charset: 'utf-8',
    sign_type: 'RSA2',
    timestamp: new Date().toISOString().slice(0, 19).replace('T', ' '),
    version: '1.0',
    notify_url: getAlipayConfig().notifyUrl,
    biz_content: bizContent,
  };
  const signedParams = { ...params, sign: signAlipay(params) };
  const query = Object.keys(signedParams)
    .sort()
    .map((key) => `${encodeURIComponent(key)}=${encodeURIComponent(signedParams[key])}`)
    .join('&');
  return {
    paymentReady: true,
    payUrl: `${getAlipayConfig().gateway}?${query}`,
    rawCreateResponse: { gateway: getAlipayConfig().gateway, method: params.method },
  };
}

function parseFormBody(rawBody) {
  const params = new URLSearchParams(rawBody || '');
  const result = {};
  for (const [key, value] of params.entries()) result[key] = value;
  return result;
}

function verifyAlipayNotify(parsed) {
  if (!isAlipayConfigured()) throw new HttpError(400, '支付宝支付未配置完整，无法验签');
  const sign = parsed.sign;
  if (!sign) throw new HttpError(400, '支付宝回调缺少签名');
  const params = { ...parsed };
  delete params.sign;
  delete params.sign_type;
  const ok = crypto
    .createVerify('RSA-SHA256')
    .update(canonicalQuery(params), 'utf8')
    .verify(normalizeKey(getAlipayConfig().publicKey), sign, 'base64');
  if (!ok) throw new HttpError(400, '支付宝回调验签失败');
}

function parseAlipayNotify(rawBody) {
  const parsed = parseFormBody(rawBody);
  verifyAlipayNotify(parsed);
  if (!['TRADE_SUCCESS', 'TRADE_FINISHED'].includes(parsed.trade_status)) {
    throw new HttpError(400, '支付宝交易尚未成功');
  }
  return {
    outTradeNo: parsed.out_trade_no,
    providerTradeNo: parsed.trade_no,
    amountCents: yuanStringToCents(parsed.total_amount),
    parsed,
  };
}

module.exports = {
  createAlipayPayment,
  parseAlipayNotify,
};

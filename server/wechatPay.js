const crypto = require('crypto');
const { HttpError } = require('./response');

const WECHAT_GATEWAY = 'https://api.mch.weixin.qq.com';

function getWechatConfig() {
  return {
    mchId: process.env.WECHAT_PAY_MCH_ID,
    appId: process.env.WECHAT_PAY_APP_ID,
    miniAppId: process.env.WECHAT_PAY_MINI_APP_ID,
    apiV3Key: process.env.WECHAT_PAY_API_V3_KEY,
    certSerialNo: process.env.WECHAT_PAY_CERT_SERIAL_NO,
    privateKey: process.env.WECHAT_PAY_PRIVATE_KEY,
    platformCert: process.env.WECHAT_PAY_PLATFORM_CERT,
    notifyUrl: process.env.WECHAT_PAY_NOTIFY_URL,
  };
}

function isWechatConfigured() {
  const config = getWechatConfig();
  return Boolean(
    config.mchId &&
      config.appId &&
      config.apiV3Key &&
      config.certSerialNo &&
      config.privateKey &&
      config.notifyUrl,
  );
}

function formatPrivateKey(raw) {
  return String(raw || '').replace(/\\n/g, '\n');
}

function signWechat(method, urlPath, body) {
  const config = getWechatConfig();
  const timestamp = Math.floor(Date.now() / 1000).toString();
  const nonce = crypto.randomBytes(16).toString('hex');
  const message = `${method}\n${urlPath}\n${timestamp}\n${nonce}\n${body}\n`;
  const signature = crypto
    .createSign('RSA-SHA256')
    .update(message)
    .sign(formatPrivateKey(config.privateKey), 'base64');
  return `WECHATPAY2-SHA256-RSA2048 mchid="${config.mchId}",nonce_str="${nonce}",timestamp="${timestamp}",serial_no="${config.certSerialNo}",signature="${signature}"`;
}

async function createWechatPayment(order) {
  if (!isWechatConfigured()) {
    if (process.env.NODE_ENV === 'production') {
      throw new HttpError(503, '微信支付尚未配置完整');
    }
    return {
      paymentReady: false,
      prepayId: null,
      codeUrl: `weixin://wxpay/mock/${order.outTradeNo}`,
      payUrl: null,
      rawCreateResponse: {
        mock: true,
        message: '开发环境未配置微信支付密钥，返回占位二维码链接。',
      },
    };
  }

  if (order.tradeType === 'mini_program') {
    return {
      paymentReady: false,
      prepayId: null,
      codeUrl: null,
      payUrl: null,
      rawCreateResponse: {
        reserved: true,
        message: '小程序支付需要 openid，当前 API 已预留 tradeType，待小程序端传入 openid 后启用。',
      },
    };
  }

  if (order.tradeType !== 'web_native') {
    return {
      paymentReady: false,
      prepayId: null,
      codeUrl: null,
      payUrl: null,
      rawCreateResponse: {
        reserved: true,
        message: `${order.tradeType} 已预留，第一版优先支持 web_native。`,
      },
    };
  }

  const path = '/v3/pay/transactions/native';
  const body = JSON.stringify({
    appid: getWechatConfig().appId,
    mchid: getWechatConfig().mchId,
    description: '国学万宝匣余额充值',
    out_trade_no: order.outTradeNo,
    notify_url: getWechatConfig().notifyUrl,
    amount: {
      total: order.amountCents,
      currency: order.currency || 'CNY',
    },
  });
  const response = await fetch(`${WECHAT_GATEWAY}${path}`, {
    method: 'POST',
    headers: {
      Authorization: signWechat('POST', path, body),
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body,
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new HttpError(502, '微信支付下单失败', data);
  }
  return {
    paymentReady: true,
    prepayId: data.prepay_id || null,
    codeUrl: data.code_url || null,
    payUrl: data.code_url || null,
    rawCreateResponse: data,
  };
}

function verifyWechatSignature(headers, rawBody) {
  const config = getWechatConfig();
  if (!config.platformCert) {
    throw new HttpError(400, '微信支付平台证书未配置，无法验签');
  }
  const timestamp = headers['wechatpay-timestamp'];
  const nonce = headers['wechatpay-nonce'];
  const signature = headers['wechatpay-signature'];
  if (!timestamp || !nonce || !signature) {
    throw new HttpError(400, '微信回调缺少签名头');
  }
  const message = `${timestamp}\n${nonce}\n${rawBody}\n`;
  const ok = crypto
    .createVerify('RSA-SHA256')
    .update(message)
    .verify(formatPrivateKey(config.platformCert), signature, 'base64');
  if (!ok) throw new HttpError(400, '微信支付回调验签失败');
}

function decryptWechatResource(resource) {
  const config = getWechatConfig();
  if (!config.apiV3Key) throw new HttpError(400, '微信 API v3 Key 未配置');
  const decipher = crypto.createDecipheriv(
    'aes-256-gcm',
    Buffer.from(config.apiV3Key, 'utf8'),
    Buffer.from(resource.nonce, 'utf8'),
  );
  decipher.setAuthTag(Buffer.from(resource.ciphertext, 'base64').subarray(-16));
  decipher.setAAD(Buffer.from(resource.associated_data || '', 'utf8'));
  const ciphertext = Buffer.from(resource.ciphertext, 'base64').subarray(0, -16);
  const decrypted = Buffer.concat([decipher.update(ciphertext), decipher.final()]);
  return JSON.parse(decrypted.toString('utf8'));
}

function parseWechatNotify(headers, rawBody) {
  const parsed = JSON.parse(rawBody || '{}');
  verifyWechatSignature(headers, rawBody);
  const decrypted = decryptWechatResource(parsed.resource || {});
  if (decrypted.trade_state !== 'SUCCESS') {
    throw new HttpError(400, '微信支付尚未成功');
  }
  return {
    outTradeNo: decrypted.out_trade_no,
    providerTradeNo: decrypted.transaction_id,
    amountCents: Number(decrypted.amount?.total || 0),
    parsed,
    decrypted,
  };
}

module.exports = {
  createWechatPayment,
  parseWechatNotify,
};

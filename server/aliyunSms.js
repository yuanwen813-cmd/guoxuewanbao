const Dysmsapi20170525 = require('@alicloud/dysmsapi20170525');
const OpenApi = require('@alicloud/openapi-client');
const { HttpError } = require('./response');

function getAliyunSmsConfig() {
  return {
    accessKeyId: process.env.ALIYUN_ACCESS_KEY_ID,
    accessKeySecret: process.env.ALIYUN_ACCESS_KEY_SECRET,
    signName: process.env.ALIYUN_SMS_SIGN_NAME,
    templateCode: process.env.ALIYUN_SMS_TEMPLATE_CODE,
    endpoint: process.env.ALIYUN_SMS_ENDPOINT || 'dysmsapi.aliyuncs.com',
  };
}

function isAliyunSmsConfigured() {
  const config = getAliyunSmsConfig();
  return Boolean(
    config.accessKeyId &&
      config.accessKeySecret &&
      config.signName &&
      config.templateCode,
  );
}

function getAliyunSmsStatus() {
  const config = getAliyunSmsConfig();
  return {
    aliyunSmsConfigured: isAliyunSmsConfigured(),
    hasAliyunAccessKeyId: Boolean(config.accessKeyId),
    hasAliyunAccessKeySecret: Boolean(config.accessKeySecret),
    hasAliyunSmsSignName: Boolean(config.signName),
    hasAliyunSmsTemplateCode: Boolean(config.templateCode),
    aliyunSmsEndpoint: config.endpoint,
  };
}

function createAliyunSmsClient() {
  const config = getAliyunSmsConfig();
  if (!isAliyunSmsConfigured()) {
    throw new HttpError(503, '阿里云短信服务尚未配置完整');
  }
  return new Dysmsapi20170525.default(
    new OpenApi.Config({
      accessKeyId: config.accessKeyId,
      accessKeySecret: config.accessKeySecret,
      endpoint: config.endpoint,
    }),
  );
}

async function sendAliyunSmsCode({ phone, code }) {
  const config = getAliyunSmsConfig();
  const client = createAliyunSmsClient();
  const request = new Dysmsapi20170525.SendSmsRequest({
    phoneNumbers: phone,
    signName: config.signName,
    templateCode: config.templateCode,
    templateParam: JSON.stringify({ code }),
  });
  const response = await client.sendSms(request);
  const body = response.body || {};
  if (body.code !== 'OK') {
    throw new HttpError(502, '短信验证码发送失败，请稍后再试', {
      provider: 'aliyun',
      code: body.code,
      message: body.message,
      requestId: body.requestId,
    });
  }
  return {
    requestId: body.requestId || null,
    bizId: body.bizId || null,
  };
}

module.exports = {
  getAliyunSmsStatus,
  sendAliyunSmsCode,
};

const { handleWechatNotify } = require('../server/paymentService');
const { handleApi, sendJson } = require('../server/response');
const { readRawBody } = require('../server/rawBody');

module.exports = handleApi(['POST'], async (req, res) => {
  const rawBody = await readRawBody(req);
  await handleWechatNotify({ headers: req.headers || {}, rawBody });
  sendJson(res, 200, { code: 'SUCCESS', message: '成功' });
});

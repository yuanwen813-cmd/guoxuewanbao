const { handleAlipayNotify } = require('../server/paymentService');
const { handleApi, sendText } = require('../server/response');
const { readRawBody } = require('../server/rawBody');

module.exports = handleApi(['POST'], async (req, res) => {
  const rawBody = await readRawBody(req);
  await handleAlipayNotify({ headers: req.headers || {}, rawBody });
  sendText(res, 200, 'success');
});

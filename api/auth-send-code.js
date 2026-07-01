const { sendPhoneCode } = require('../server/auth');
const { handleApi, readJson, sendJson } = require('../server/response');

module.exports = handleApi(['POST'], async (req, res) => {
  const body = await readJson(req);
  await sendPhoneCode(body.phone);
  sendJson(res, 200, { ok: true });
});

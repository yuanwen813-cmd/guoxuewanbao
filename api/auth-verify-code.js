const { verifyPhoneCode } = require('../server/auth');
const { handleApi, readJson, sendJson } = require('../server/response');

module.exports = handleApi(['POST'], async (req, res) => {
  const body = await readJson(req);
  const result = await verifyPhoneCode(body.phone, body.code);
  sendJson(res, 200, {
    ok: true,
    token: result.token,
    user: result.user,
  });
});

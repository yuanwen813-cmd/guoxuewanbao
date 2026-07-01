const { requireUser } = require('../server/auth');
const { handleApi, sendJson } = require('../server/response');

module.exports = handleApi(['GET'], async (req, res) => {
  const current = await requireUser(req);
  sendJson(res, 200, {
    ok: true,
    user: current.appUser,
  });
});

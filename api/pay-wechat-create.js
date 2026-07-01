const { requireUser } = require('../server/auth');
const { createRecharge } = require('../server/paymentService');
const { handleApi, readJson, sendJson } = require('../server/response');

module.exports = handleApi(['POST'], async (req, res) => {
  const current = await requireUser(req);
  const body = await readJson(req);
  const result = await createRecharge({
    userId: current.appUser.id,
    provider: 'wechat',
    tradeType: body.tradeType || 'web_native',
    amountCents: body.amountCents,
  });
  sendJson(res, 200, {
    ok: true,
    order: result.order,
    payment: result.payment,
  });
});

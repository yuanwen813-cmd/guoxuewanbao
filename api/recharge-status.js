const { requireUser } = require('../server/auth');
const { handleApi, parseUrl, sendJson } = require('../server/response');
const { getRechargeOrderForUser } = require('../server/walletService');

module.exports = handleApi(['GET'], async (req, res) => {
  const current = await requireUser(req);
  const url = parseUrl(req);
  const order = await getRechargeOrderForUser({
    userId: current.appUser.id,
    orderId: url.searchParams.get('orderId'),
    outTradeNo: url.searchParams.get('outTradeNo'),
  });
  sendJson(res, 200, {
    ok: true,
    order,
  });
});

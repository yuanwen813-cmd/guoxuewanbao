const { requireUser } = require('../server/auth');
const { createRecharge } = require('../server/paymentService');
const { handleApi, readJson, sendJson } = require('../server/response');
const { getWallet, listWalletTransactions } = require('../server/walletService');

module.exports = handleApi(['POST'], async (req, res) => {
  const current = await requireUser(req);
  const body = await readJson(req);
  const result = await createRecharge({
    userId: current.appUser.id,
    provider: body.provider,
    tradeType: body.tradeType,
    amountCents: body.amountCents,
  });
  const wallet = await getWallet(current.appUser.id);
  const transactions = await listWalletTransactions(current.appUser.id, {
    page: 1,
    pageSize: 20,
  });
  sendJson(res, 200, {
    ok: true,
    order: result.order,
    payment: result.payment,
    wallet: {
      ...wallet,
      transactions,
    },
  });
});

const { requireUser } = require('../server/auth');
const { handleApi, sendJson } = require('../server/response');
const { getWallet, listWalletTransactions } = require('../server/walletService');

module.exports = handleApi(['GET'], async (req, res) => {
  const current = await requireUser(req);
  const wallet = await getWallet(current.appUser.id);
  const transactions = await listWalletTransactions(current.appUser.id, {
    page: 1,
    pageSize: 20,
  });
  sendJson(res, 200, {
    ok: true,
    wallet: {
      ...wallet,
      transactions,
    },
  });
});

const { requireUser } = require('../server/auth');
const { handleApi, parseUrl, sendJson } = require('../server/response');
const { listWalletTransactions } = require('../server/walletService');

module.exports = handleApi(['GET'], async (req, res) => {
  const current = await requireUser(req);
  const url = parseUrl(req);
  const page = Number(url.searchParams.get('page') || 1);
  const pageSize = Number(url.searchParams.get('pageSize') || 30);
  const transactions = await listWalletTransactions(current.appUser.id, {
    page,
    pageSize,
  });
  sendJson(res, 200, {
    ok: true,
    transactions,
    page,
    pageSize,
  });
});

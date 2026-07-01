const { requireUser } = require('../server/auth');
const { getAiReportDetail } = require('../server/aiReportService');
const { handleApi, parseUrl, sendJson } = require('../server/response');

module.exports = handleApi(['GET'], async (req, res) => {
  const current = await requireUser(req);
  const url = parseUrl(req);
  const report = await getAiReportDetail({
    userId: current.appUser.id,
    orderId: url.searchParams.get('orderId'),
  });
  sendJson(res, 200, {
    ok: true,
    report,
  });
});

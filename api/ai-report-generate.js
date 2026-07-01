const { requireUser } = require('../server/auth');
const { generateAiReport } = require('../server/aiReportService');
const { handleApi, readJson, sendJson } = require('../server/response');

module.exports = handleApi(['POST'], async (req, res) => {
  const current = await requireUser(req);
  const body = await readJson(req);
  const result = await generateAiReport({
    userId: current.appUser.id,
    body,
  });
  sendJson(res, 200, {
    ok: true,
    answer: result.answer,
    model: result.model,
    report: result.report,
    wallet: result.wallet,
  });
});

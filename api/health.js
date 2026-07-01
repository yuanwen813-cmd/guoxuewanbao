const { handleApi, sendJson } = require('../server/response');

module.exports = handleApi(['GET'], async (_req, res) => {
  sendJson(res, 200, {
    ok: true,
    service: 'guoxueapp-api',
    runtime: 'vercel',
    wallet: 'supabase',
    time: new Date().toISOString(),
  });
});

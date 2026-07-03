const { generateAiReport, getAiReportDetail } = require('../server/aiReportService');
const { getAlipayRuntimeStatus } = require('../server/alipay');
const {
  getAuthRuntimeStatus,
  requireUser,
  sendPhoneCode,
  verifyPhoneCode,
} = require('../server/auth');
const { createRecharge, handleAlipayNotify, handleWechatNotify } = require('../server/paymentService');
const {
  handleApi,
  parseUrl,
  readJson,
  sendJson,
  sendText,
} = require('../server/response');
const { readRawBody } = require('../server/rawBody');
const {
  getRechargeOrderForUser,
  getWallet,
  listWalletTransactions,
} = require('../server/walletService');

function requestPath(req) {
  const url = parseUrl(req);
  const queryPath = url.searchParams.get('path');
  const rawPath = queryPath || url.pathname.replace(/^\/api\/?/, '');
  return String(rawPath || 'health').replace(/^\/+|\/+$/g, '');
}

const routes = {
  health: handleApi(['GET'], async (_req, res) => {
    sendJson(res, 200, {
      ok: true,
      service: 'guoxueapp-api',
      runtime: 'vercel',
      wallet: 'supabase',
      time: new Date().toISOString(),
    });
  }),

  'auth-send-code': handleApi(['POST'], async (req, res) => {
    const body = await readJson(req);
    await sendPhoneCode(body.phone);
    sendJson(res, 200, { ok: true });
  }),

  'auth-verify-code': handleApi(['POST'], async (req, res) => {
    const body = await readJson(req);
    const result = await verifyPhoneCode(body.phone, body.code);
    sendJson(res, 200, {
      ok: true,
      token: result.token,
      user: result.user,
    });
  }),

  'auth-debug': handleApi(['GET'], async (_req, res) => {
    sendJson(res, 200, {
      ok: true,
      auth: getAuthRuntimeStatus(),
    });
  }),

  'payment-debug': handleApi(['GET'], async (_req, res) => {
    sendJson(res, 200, {
      ok: true,
      alipay: getAlipayRuntimeStatus(),
    });
  }),

  'auth-me': handleApi(['GET'], async (req, res) => {
    const current = await requireUser(req);
    sendJson(res, 200, {
      ok: true,
      user: current.appUser,
    });
  }),

  wallet: handleApi(['GET'], async (req, res) => {
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
  }),

  'wallet-transactions': handleApi(['GET'], async (req, res) => {
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
  }),

  'recharge-create': handleApi(['POST'], async (req, res) => {
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
  }),

  'recharge-status': handleApi(['GET'], async (req, res) => {
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
  }),

  'pay-wechat-create': handleApi(['POST'], async (req, res) => {
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
  }),

  'pay-wechat-notify': handleApi(['POST'], async (req, res) => {
    const rawBody = await readRawBody(req);
    try {
      await handleWechatNotify({ headers: req.headers || {}, rawBody });
      sendJson(res, 200, { code: 'SUCCESS', message: '成功' });
    } catch (error) {
      sendJson(res, 500, {
        code: 'FAIL',
        message: error.message || '支付通知处理失败',
      });
    }
  }),

  'pay-alipay-create': handleApi(['POST'], async (req, res) => {
    const current = await requireUser(req);
    const body = await readJson(req);
    const result = await createRecharge({
      userId: current.appUser.id,
      provider: 'alipay',
      tradeType: body.tradeType || 'web_pc',
      amountCents: body.amountCents,
    });
    sendJson(res, 200, {
      ok: true,
      order: result.order,
      payment: result.payment,
    });
  }),

  'pay-alipay-notify': handleApi(['POST'], async (req, res) => {
    const rawBody = await readRawBody(req);
    try {
      await handleAlipayNotify({ headers: req.headers || {}, rawBody });
      sendText(res, 200, 'success');
    } catch (_) {
      sendText(res, 200, 'failure');
    }
  }),

  'ai-report-generate': handleApi(['POST'], async (req, res) => {
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
  }),

  'ai-report-detail': handleApi(['GET'], async (req, res) => {
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
  }),
};

module.exports = async function unifiedApi(req, res) {
  const route = routes[requestPath(req)];
  if (!route) {
    return sendJson(res, 404, {
      ok: false,
      error: '接口不存在',
    });
  }
  return route(req, res);
};

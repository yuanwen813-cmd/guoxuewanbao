const { allowedCorsOrigin, isProductionRuntime } = require('./security');

class HttpError extends Error {
  constructor(statusCode, message, details) {
    super(message);
    this.name = 'HttpError';
    this.statusCode = statusCode;
    this.details = details;
  }
}

function setCors(res, req) {
  if (typeof res.setHeader === 'function') {
    const origin =
      req?.headers?.origin ||
      req?.headers?.Origin ||
      res.req?.headers?.origin ||
      res.req?.headers?.Origin ||
      '';
    const allowedOrigin = allowedCorsOrigin(origin);
    if (allowedOrigin) {
      res.setHeader('Access-Control-Allow-Origin', allowedOrigin);
      res.setHeader('Vary', 'Origin');
    } else if (!isProductionRuntime()) {
      res.setHeader('Access-Control-Allow-Origin', '*');
    }
    res.setHeader(
      'Access-Control-Allow-Headers',
      'Authorization, Content-Type, X-Requested-With',
    );
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  }
}

function sendJson(res, statusCode, body) {
  setCors(res);
  if (typeof res.status === 'function') {
    return res.status(statusCode).json(body);
  }
  res.writeHead(statusCode, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
}

function sendText(res, statusCode, text) {
  setCors(res);
  if (typeof res.status === 'function') {
    return res.status(statusCode).send(text);
  }
  res.writeHead(statusCode, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end(text);
}

function parseUrl(req) {
  return new URL(req.url || '/', 'https://guoxueapp.local');
}

async function readJson(req, { maxBytes = 128 * 1024 } = {}) {
  if (req.body && typeof req.body === 'object') return req.body;
  const chunks = [];
  let total = 0;
  for await (const chunk of req) {
    const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
    total += buffer.length;
    if (total > maxBytes) {
      throw new HttpError(413, '请求内容过大');
    }
    chunks.push(buffer);
  }
  const raw = Buffer.concat(chunks).toString('utf8');
  if (!raw.trim()) return {};
  try {
    return JSON.parse(raw);
  } catch (_) {
    throw new HttpError(400, '请求体不是有效 JSON');
  }
}

function handleApi(allowedMethods, handler) {
  return async function apiHandler(req, res) {
    setCors(res, req);
    if (req.method === 'OPTIONS') {
      if (typeof res.status === 'function') return res.status(204).end();
      res.writeHead(204);
      res.end();
      return;
    }
    if (!allowedMethods.includes(req.method)) {
      return sendJson(res, 405, { ok: false, error: '请求方法不支持' });
    }
    try {
      await handler(req, res);
    } catch (error) {
      const statusCode = error.statusCode || 500;
      const message =
        statusCode >= 500 ? '服务端处理失败，请稍后再试' : error.message;
      const body = {
        ok: false,
        error: message,
      };
      if (error.details?.wallet) body.wallet = error.details.wallet;
      if (error.details?.report) body.report = error.details.report;
      if (!isProductionRuntime() && error.details) {
        body.details = error.details;
      }
      return sendJson(res, statusCode, body);
    }
  };
}

module.exports = {
  HttpError,
  handleApi,
  parseUrl,
  readJson,
  sendJson,
  sendText,
};

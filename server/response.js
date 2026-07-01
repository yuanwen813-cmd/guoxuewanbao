class HttpError extends Error {
  constructor(statusCode, message, details) {
    super(message);
    this.name = 'HttpError';
    this.statusCode = statusCode;
    this.details = details;
  }
}

function setCors(res) {
  if (typeof res.setHeader === 'function') {
    res.setHeader('Access-Control-Allow-Origin', '*');
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

async function readJson(req) {
  if (req.body && typeof req.body === 'object') return req.body;
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
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
    setCors(res);
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
      if (process.env.NODE_ENV !== 'production' && error.details) {
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

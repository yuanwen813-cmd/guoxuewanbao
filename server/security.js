const crypto = require('crypto');

const memoryBuckets = new Map();

function isProductionRuntime() {
  return (
    String(process.env.NODE_ENV || '').toLowerCase() === 'production' ||
    String(process.env.VERCEL_ENV || '').toLowerCase() === 'production'
  );
}

function getClientIp(req) {
  const headers = req.headers || {};
  const forwarded = headers['x-forwarded-for'] || headers['X-Forwarded-For'];
  const realIp =
    headers['x-real-ip'] ||
    headers['X-Real-IP'] ||
    headers['cf-connecting-ip'] ||
    headers['CF-Connecting-IP'];
  const value = Array.isArray(forwarded) ? forwarded[0] : forwarded || realIp;
  return String(value || req.socket?.remoteAddress || 'unknown')
    .split(',')[0]
    .trim();
}

function configuredOrigins() {
  const raw = [
    process.env.CORS_ALLOWED_ORIGINS || '',
    process.env.PUBLIC_WEB_URL || '',
  ]
    .join(',')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
  if (isProductionRuntime()) raw.push('https://guoxuewanbao.cn');
  return [...new Set(raw)];
}

function allowedCorsOrigin(origin) {
  if (!origin) return '';
  if (!isProductionRuntime()) return origin;
  return configuredOrigins().includes(origin) ? origin : '';
}

function createHttpError(statusCode, message) {
  const error = new Error(message);
  error.name = 'HttpError';
  error.statusCode = statusCode;
  return error;
}

function timingSafeEqualText(left, right) {
  const a = Buffer.from(String(left || ''));
  const b = Buffer.from(String(right || ''));
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

function requireDebugAccess(req) {
  if (!isProductionRuntime()) return;
  const expected = process.env.ADMIN_DEBUG_TOKEN;
  if (!expected) throw createHttpError(404, '接口不存在');
  const url = new URL(req.url || '/', 'https://guoxueapp.local');
  const provided =
    req.headers?.['x-admin-debug-token'] ||
    req.headers?.['X-Admin-Debug-Token'] ||
    url.searchParams.get('debugToken') ||
    '';
  if (!timingSafeEqualText(provided, expected)) {
    throw createHttpError(404, '接口不存在');
  }
}

function assertMemoryRateLimit({
  key,
  windowMs,
  max,
  message = '请求过于频繁，请稍后再试',
}) {
  const now = Date.now();
  const bucket = memoryBuckets.get(key) || [];
  const recent = bucket.filter((ts) => now - ts < windowMs);
  if (recent.length >= max) {
    memoryBuckets.set(key, recent);
    throw createHttpError(429, message);
  }
  recent.push(now);
  memoryBuckets.set(key, recent);

  if (memoryBuckets.size > 10000) {
    for (const [bucketKey, values] of memoryBuckets.entries()) {
      if (values.every((ts) => now - ts >= windowMs)) {
        memoryBuckets.delete(bucketKey);
      }
    }
  }
}

function assertRequestRateLimit(req, options) {
  const ip = getClientIp(req);
  assertMemoryRateLimit({
    key: `${options.name}:${ip}`,
    windowMs: options.windowMs,
    max: options.max,
    message: options.message,
  });
}

function truncateForLog(value, maxLength = 20000) {
  const text = typeof value === 'string' ? value : JSON.stringify(value || '');
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength)}...[truncated:${text.length}]`;
}

module.exports = {
  allowedCorsOrigin,
  assertMemoryRateLimit,
  assertRequestRateLimit,
  getClientIp,
  isProductionRuntime,
  requireDebugAccess,
  truncateForLog,
};

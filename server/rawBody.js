class RawBodyTooLargeError extends Error {
  constructor() {
    super('请求内容过大');
    this.name = 'HttpError';
    this.statusCode = 413;
  }
}

function assertSize(buffer, maxBytes) {
  if (Buffer.byteLength(buffer) > maxBytes) throw new RawBodyTooLargeError();
}

async function readRawBody(req, { maxBytes = 128 * 1024 } = {}) {
  if (typeof req.body === 'string') {
    assertSize(req.body, maxBytes);
    return req.body;
  }
  if (Buffer.isBuffer(req.body)) {
    assertSize(req.body, maxBytes);
    return req.body.toString('utf8');
  }
  const chunks = [];
  let total = 0;
  for await (const chunk of req) {
    const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
    total += buffer.length;
    if (total > maxBytes) throw new RawBodyTooLargeError();
    chunks.push(buffer);
  }
  return Buffer.concat(chunks).toString('utf8');
}

module.exports = { readRawBody };

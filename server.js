const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = Number(process.env.PORT || 8080);
const STATIC_DIR = path.join(__dirname, 'build', 'web');
const DATA_DIR = path.join(__dirname, 'server_data');
const WALLET_DB_FILE = path.join(DATA_DIR, 'wallets.json');
const DEFAULT_USER_ID = 'local_user_001';
const DEEPSEEK_BASE_URL =
  process.env.DEEPSEEK_BASE_URL || 'https://api.deepseek.com';
const DEEPSEEK_API_KEY = process.env.DEEPSEEK_API_KEY || '';

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.wasm': 'application/wasm',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
};

const PRODUCTS = {
  daily_hexagram_brief: {
    priceCents: 100,
    model: 'deepseek-v4-flash',
    maxTokens: 1800,
  },
  gaodao_yiduan_question_brief: {
    priceCents: 100,
    model: 'deepseek-v4-flash',
    maxTokens: 1800,
  },
  gaodao_yiduan_question_full: {
    priceCents: 390,
    model: 'deepseek-v4-pro',
    maxTokens: 6000,
  },
  coin_hexagram_question_brief: {
    priceCents: 100,
    model: 'deepseek-v4-flash',
    maxTokens: 1800,
  },
  coin_hexagram_question_full: {
    priceCents: 390,
    model: 'deepseek-v4-pro',
    maxTokens: 6000,
  },
  xiaoliuren_question_brief: {
    priceCents: 100,
    model: 'deepseek-v4-flash',
    maxTokens: 1800,
  },
  xiaoliuren_question_full: {
    priceCents: 390,
    model: 'deepseek-v4-pro',
    maxTokens: 3200,
  },
  meihua_yishu_question_brief: {
    priceCents: 100,
    model: 'deepseek-v4-flash',
    maxTokens: 1800,
  },
  meihua_yishu_question_full: {
    priceCents: 390,
    model: 'deepseek-v4-pro',
    maxTokens: 6000,
  },
  bazi_brief: {
    priceCents: 100,
    model: 'deepseek-v4-flash',
    maxTokens: 3200,
  },
  bazi_basic: {
    priceCents: 390,
    model: 'deepseek-v4-pro',
    maxTokens: 6000,
  },
  bazi_deep: {
    priceCents: 690,
    model: 'deepseek-v4-pro',
    maxTokens: 8192,
  },
  ziwei_brief: {
    priceCents: 100,
    model: 'deepseek-v4-flash',
    maxTokens: 3200,
  },
  ziwei_basic: {
    priceCents: 390,
    model: 'deepseek-v4-pro',
    maxTokens: 6000,
  },
  ziwei_deep: {
    priceCents: 690,
    model: 'deepseek-v4-pro',
    maxTokens: 8192,
  },
  tieban_basic: {
    priceCents: 390,
    model: 'deepseek-v4-pro',
    maxTokens: 6000,
  },
  tieban_deep: {
    priceCents: 690,
    model: 'deepseek-v4-pro',
    maxTokens: 8192,
  },
};

function ensureDataDir() {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }
}

function loadWalletDb() {
  ensureDataDir();
  if (!fs.existsSync(WALLET_DB_FILE)) {
    return { wallets: {} };
  }
  try {
    return JSON.parse(fs.readFileSync(WALLET_DB_FILE, 'utf8'));
  } catch (_) {
    return { wallets: {} };
  }
}

function saveWalletDb(db) {
  ensureDataDir();
  fs.writeFileSync(WALLET_DB_FILE, JSON.stringify(db, null, 2), 'utf8');
}

function getWallet(db, userId) {
  const id = userId || DEFAULT_USER_ID;
  if (!db.wallets[id]) {
    db.wallets[id] = { balanceCents: 0, transactions: [] };
  }
  return db.wallets[id];
}

function toPublicWallet(wallet) {
  return {
    balanceCents: wallet.balanceCents || 0,
    transactions: wallet.transactions || [],
  };
}

function newId(prefix) {
  return `${prefix}-${Date.now()}-${Math.floor(Math.random() * 100000)}`;
}

function appendTransaction(wallet, transaction) {
  wallet.balanceCents = (wallet.balanceCents || 0) + transaction.amountCents;
  wallet.transactions = [transaction, ...(wallet.transactions || [])].slice(0, 200);
}

function createTransaction({
  type,
  amountCents,
  title,
  featureKey,
  productId,
  relatedTransactionId,
}) {
  return {
    id: newId(type),
    type,
    amountCents,
    title,
    featureKey: featureKey || null,
    productId: productId || null,
    relatedTransactionId: relatedTransactionId || null,
    createdAt: new Date().toISOString(),
  };
}

function sendJson(res, status, body) {
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
  });
  res.end(JSON.stringify(body));
}

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => {
      raw += chunk;
      if (raw.length > 1024 * 1024) {
        reject(new Error('request body too large'));
        req.destroy();
      }
    });
    req.on('end', () => {
      if (!raw) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch (_) {
        reject(new Error('invalid json'));
      }
    });
    req.on('error', reject);
  });
}

function userIdFromUrl(req) {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  return url.searchParams.get('userId') || DEFAULT_USER_ID;
}

async function callDeepSeek({ product, systemPrompt, userPrompt, temperature }) {
  if (!DEEPSEEK_API_KEY) {
    const error = new Error('服务端未配置 DeepSeek API Key');
    error.statusCode = 503;
    throw error;
  }

  const response = await fetch(`${DEEPSEEK_BASE_URL}/v1/chat/completions`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${DEEPSEEK_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: product.model,
      messages: [
        { role: 'system', content: systemPrompt || '' },
        { role: 'user', content: userPrompt || '' },
      ],
      temperature: typeof temperature === 'number' ? temperature : 0.45,
      max_tokens: product.maxTokens,
    }),
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message =
      data.error?.message || data.message || `AI 服务暂时不可用：${response.status}`;
    const error = new Error(message);
    error.statusCode = response.status;
    throw error;
  }
  return data.choices?.[0]?.message?.content || '';
}

async function handleWalletGet(req, res) {
  const db = loadWalletDb();
  const wallet = getWallet(db, userIdFromUrl(req));
  saveWalletDb(db);
  sendJson(res, 200, { wallet: toPublicWallet(wallet) });
}

async function handleRecharge(req, res) {
  const body = await readJsonBody(req);
  const userId = body.userId || DEFAULT_USER_ID;
  const amountCents = Number(body.amountCents);
  if (!Number.isInteger(amountCents) || amountCents < 100) {
    sendJson(res, 400, { error: '充值金额必须是不低于 1 元的整数' });
    return;
  }

  const db = loadWalletDb();
  const wallet = getWallet(db, userId);
  appendTransaction(
    wallet,
    createTransaction({
      type: 'recharge',
      amountCents,
      title: '服务端充值',
    }),
  );
  saveWalletDb(db);
  sendJson(res, 200, { wallet: toPublicWallet(wallet) });
}

async function handleAiReport(req, res) {
  const body = await readJsonBody(req);
  const userId = body.userId || DEFAULT_USER_ID;
  const product = PRODUCTS[body.productId];
  if (!product) {
    sendJson(res, 400, { error: 'AI 解析档位不存在或已下架' });
    return;
  }
  if (!body.userPrompt || !body.systemPrompt) {
    sendJson(res, 400, { error: 'AI 解析缺少必要内容' });
    return;
  }

  const db = loadWalletDb();
  const wallet = getWallet(db, userId);
  if ((wallet.balanceCents || 0) < product.priceCents) {
    sendJson(res, 402, {
      error: '余额不足，请先充值后再生成',
      wallet: toPublicWallet(wallet),
    });
    return;
  }

  const charge = createTransaction({
    type: 'charge',
    amountCents: -product.priceCents,
    title: body.title || 'AI 解析',
    featureKey: body.featureKey,
    productId: body.productId,
  });
  appendTransaction(wallet, charge);
  saveWalletDb(db);

  try {
    const answer = await callDeepSeek({
      product,
      systemPrompt: body.systemPrompt,
      userPrompt: body.userPrompt,
      temperature: body.temperature,
    });
    const latestDb = loadWalletDb();
    const latestWallet = getWallet(latestDb, userId);
    sendJson(res, 200, {
      answer,
      model: product.model,
      chargeTransactionId: charge.id,
      wallet: toPublicWallet(latestWallet),
    });
  } catch (error) {
    const refundDb = loadWalletDb();
    const refundWallet = getWallet(refundDb, userId);
    appendTransaction(
      refundWallet,
      createTransaction({
        type: 'refund',
        amountCents: product.priceCents,
        title: 'AI 解析失败退款',
        productId: body.productId,
        featureKey: body.featureKey,
        relatedTransactionId: charge.id,
      }),
    );
    saveWalletDb(refundDb);
    sendJson(res, error.statusCode || 500, {
      error: error.message || 'AI 解析失败，已退回本次扣费',
      wallet: toPublicWallet(refundWallet),
    });
  }
}

function serveStatic(req, res) {
  let filePath = path.join(
    STATIC_DIR,
    req.url === '/' ? 'index.html' : req.url.split('?')[0],
  );
  const ext = path.extname(filePath);
  if (!ext || !MIME[ext]) {
    filePath = path.join(STATIC_DIR, 'index.html');
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not Found');
      return;
    }
    const contentType = MIME[path.extname(filePath)] || MIME['.html'];
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === 'OPTIONS') {
      res.writeHead(204, {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      });
      res.end();
      return;
    }

    const url = new URL(req.url, `http://localhost:${PORT}`);
    if (url.pathname === '/api/wallet' && req.method === 'GET') {
      await handleWalletGet(req, res);
      return;
    }
    if (url.pathname === '/api/wallet/recharge' && req.method === 'POST') {
      await handleRecharge(req, res);
      return;
    }
    if (url.pathname === '/api/ai/report' && req.method === 'POST') {
      await handleAiReport(req, res);
      return;
    }

    serveStatic(req, res);
  } catch (error) {
    sendJson(res, 500, { error: error.message || '服务端处理失败' });
  }
});

server.listen(PORT, () => {
  console.log(`Guoxueapp preview and wallet server: http://127.0.0.1:${PORT}`);
  console.log('Wallet ledger: server_data/wallets.json');
  console.log(
    DEEPSEEK_API_KEY
      ? 'DeepSeek server-side AI proxy enabled.'
      : 'DeepSeek server-side AI proxy waiting for DEEPSEEK_API_KEY.',
  );
});

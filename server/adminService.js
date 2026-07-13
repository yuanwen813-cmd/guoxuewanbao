const crypto = require('crypto');
const { verifyPhoneCode, sendPhoneCode, normalizePhone } = require('./auth');
const { HttpError } = require('./response');
const { getSupabaseServiceClient } = require('./supabaseClient');
const { getClientIp } = require('./security');

const adminRoles = new Set(['super_admin', 'finance', 'support', 'content', 'viewer']);

const rolePermissions = {
  super_admin: ['admin:read', 'wallet:adjust', 'audit:read'],
  finance: ['admin:read', 'wallet:adjust', 'audit:read'],
  support: ['admin:read', 'audit:read'],
  content: ['admin:read'],
  viewer: ['admin:read'],
};

function adminSecret() {
  const secret = process.env.ADMIN_JWT_SECRET || process.env.JWT_SECRET;
  if (!secret) throw new HttpError(500, 'ADMIN_JWT_SECRET or JWT_SECRET is missing');
  return secret;
}

function adminSessionTtlSeconds() {
  return Math.max(3600, Number(process.env.ADMIN_SESSION_TTL_SECONDS || 12 * 60 * 60));
}

function configuredAdminPhones() {
  return String(process.env.ADMIN_ALLOWED_PHONES || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean)
    .map((item) => normalizePhone(item));
}

function isAllowedByEnv(phone) {
  return configuredAdminPhones().includes(normalizePhone(phone));
}

function base64UrlEncode(value) {
  return Buffer.from(value)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function base64UrlDecode(value) {
  const normalized = String(value || '').replace(/-/g, '+').replace(/_/g, '/');
  return Buffer.from(normalized, 'base64').toString('utf8');
}

function signToken(encoded) {
  return crypto
    .createHmac('sha256', adminSecret())
    .update(encoded)
    .digest('base64url');
}

function createAdminToken(admin) {
  const role = admin.role || 'viewer';
  const permissions = rolePermissions[role] || rolePermissions.viewer;
  const payload = {
    typ: 'admin_login',
    sub: admin.id || `env:${admin.phone}`,
    phone: admin.phone,
    role,
    permissions,
    exp: Math.floor(Date.now() / 1000) + adminSessionTtlSeconds(),
  };
  const encoded = base64UrlEncode(JSON.stringify(payload));
  return `admin:${encoded}.${signToken(encoded)}`;
}

function readAdminToken(token) {
  if (!String(token || '').startsWith('admin:')) return null;
  try {
    const raw = String(token).slice(6);
    const [encoded, signature] = raw.split('.');
    if (!encoded || !signature) return null;
    const expected = signToken(encoded);
    const actualBuffer = Buffer.from(signature);
    const expectedBuffer = Buffer.from(expected);
    if (
      actualBuffer.length !== expectedBuffer.length ||
      !crypto.timingSafeEqual(actualBuffer, expectedBuffer)
    ) {
      return null;
    }
    const payload = JSON.parse(base64UrlDecode(encoded));
    if (payload.typ !== 'admin_login' || !payload.phone || !payload.role) return null;
    if (Number(payload.exp || 0) < Math.floor(Date.now() / 1000)) return null;
    return {
      id: payload.sub,
      phone: normalizePhone(payload.phone),
      role: payload.role,
      permissions: Array.isArray(payload.permissions) ? payload.permissions : [],
    };
  } catch (_) {
    return null;
  }
}

function getBearerToken(req) {
  const raw = req.headers?.authorization || req.headers?.Authorization || '';
  const match = String(raw).match(/^Bearer\s+(.+)$/i);
  if (!match) throw new HttpError(401, 'Please sign in to the admin console');
  return match[1].trim();
}

function isMissingAdminTable(error) {
  const message = String(error?.message || '');
  return error?.code === '42P01' || error?.code === 'PGRST205' || message.includes('admin_users');
}

function isMissingAuditTable(error) {
  const message = String(error?.message || '');
  return error?.code === '42P01' || error?.code === 'PGRST205' || message.includes('admin_audit_logs');
}

function mapAdmin(row, fallbackPhone) {
  if (!row) {
    return {
      id: null,
      phone: normalizePhone(fallbackPhone),
      name: 'Env Admin',
      role: 'super_admin',
      permissions: rolePermissions.super_admin,
      status: 'active',
    };
  }
  const role = adminRoles.has(row.role) ? row.role : 'viewer';
  return {
    id: row.id,
    phone: normalizePhone(row.phone),
    name: row.name || '',
    role,
    permissions: Array.isArray(row.permissions)
      ? row.permissions
      : rolePermissions[role] || rolePermissions.viewer,
    status: row.status || 'active',
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    lastLoginAt: row.last_login_at,
  };
}

function mapUser(row) {
  const wallet = Array.isArray(row.wallets) ? row.wallets[0] : row.wallets;
  return {
    id: row.id,
    phone: row.phone,
    nickname: row.nickname,
    avatarUrl: row.avatar_url,
    status: row.status,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    wallet: wallet
      ? {
          balanceCents: Number(wallet.balance_cents || 0),
          currency: wallet.currency || 'CNY',
          updatedAt: wallet.updated_at,
        }
      : null,
  };
}

function mapTransaction(row) {
  return {
    id: row.id,
    userId: row.user_id,
    walletId: row.wallet_id,
    type: row.type,
    amountCents: Number(row.amount_cents || 0),
    balanceAfterCents: Number(row.balance_after_cents || 0),
    currency: row.currency || 'CNY',
    refType: row.ref_type,
    refId: row.ref_id,
    outTradeNo: row.out_trade_no,
    note: row.note,
    createdAt: row.created_at,
  };
}

function mapRecharge(row) {
  const user = Array.isArray(row.app_users) ? row.app_users[0] : row.app_users;
  return {
    id: row.id,
    userId: row.user_id,
    userPhone: user?.phone || null,
    outTradeNo: row.out_trade_no,
    provider: row.provider,
    tradeType: row.trade_type,
    amountCents: Number(row.amount_cents || 0),
    currency: row.currency || 'CNY',
    status: row.status,
    providerTradeNo: row.provider_trade_no,
    paidAt: row.paid_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function mapAiReport(row, { includeText = false } = {}) {
  const user = Array.isArray(row.app_users) ? row.app_users[0] : row.app_users;
  const result = {
    id: row.id,
    userId: row.user_id,
    userPhone: user?.phone || null,
    productId: row.product_id,
    reportType: row.report_type,
    priceCents: Number(row.price_cents || 0),
    currency: row.currency || 'CNY',
    status: row.status,
    errorMessage: row.error_message,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
  if (includeText) {
    result.resultText = row.result_text;
    result.inputSnapshotJson = row.input_snapshot_json;
    result.baziChartJson = row.bazi_chart_json;
    result.questionResultJson = row.question_result_json;
    result.promptSnapshot = row.prompt_snapshot;
  }
  return result;
}

function mapAuditLog(row) {
  return {
    id: row.id,
    adminUserId: row.admin_user_id,
    adminPhone: row.admin_phone,
    action: row.action,
    targetType: row.target_type,
    targetId: row.target_id,
    detailJson: row.detail_json || {},
    clientIp: row.client_ip,
    userAgent: row.user_agent,
    createdAt: row.created_at,
  };
}

function pageParams(rawPage, rawPageSize) {
  const page = Math.max(1, Number(rawPage || 1));
  const pageSize = Math.min(100, Math.max(1, Number(rawPageSize || 30)));
  return {
    page,
    pageSize,
    from: (page - 1) * pageSize,
    to: page * pageSize - 1,
  };
}

function searchText(value) {
  return String(value || '')
    .trim()
    .replace(/[,%()]/g, '')
    .slice(0, 80);
}

function requirePermission(admin, permission) {
  if (!permission) return;
  if (admin.role === 'super_admin') return;
  if (!admin.permissions.includes(permission)) {
    throw new HttpError(403, 'No permission for this admin action');
  }
}

async function findAdminByPhone(phone) {
  const normalized = normalizePhone(phone);
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase
    .from('admin_users')
    .select('*')
    .eq('phone', normalized)
    .maybeSingle();
  if (error) {
    if (isMissingAdminTable(error) && isAllowedByEnv(normalized)) {
      return mapAdmin(null, normalized);
    }
    if (isMissingAdminTable(error)) return null;
    throw new HttpError(500, 'Admin lookup failed', error.message);
  }
  if (data) return mapAdmin(data, normalized);
  if (isAllowedByEnv(normalized)) return mapAdmin(null, normalized);
  return null;
}

async function upsertEnvAdminIfNeeded(admin) {
  if (admin.id || !isAllowedByEnv(admin.phone)) return admin;
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase
    .from('admin_users')
    .upsert(
      {
        phone: admin.phone,
        name: admin.name || 'Env Admin',
        role: admin.role || 'super_admin',
        permissions: admin.permissions || rolePermissions.super_admin,
        status: 'active',
        last_login_at: new Date().toISOString(),
      },
      { onConflict: 'phone' },
    )
    .select('*')
    .single();
  if (error) {
    if (isMissingAdminTable(error)) return admin;
    throw new HttpError(500, 'Admin bootstrap failed', error.message);
  }
  return mapAdmin(data, admin.phone);
}

async function updateAdminLastLogin(admin) {
  if (!admin.id || String(admin.id).startsWith('env:')) return;
  const supabase = getSupabaseServiceClient();
  await supabase
    .from('admin_users')
    .update({ last_login_at: new Date().toISOString() })
    .eq('id', admin.id);
}

async function writeAdminAuditLog({ admin, action, targetType, targetId, detail, req }) {
  const supabase = getSupabaseServiceClient();
  const { error } = await supabase.from('admin_audit_logs').insert({
    admin_user_id: admin.id && !String(admin.id).startsWith('env:') ? admin.id : null,
    admin_phone: admin.phone,
    action,
    target_type: targetType || null,
    target_id: targetId || null,
    detail_json: detail || {},
    client_ip: req ? getClientIp(req) : null,
    user_agent: String(req?.headers?.['user-agent'] || '').slice(0, 500),
  });
  if (error && !isMissingAuditTable(error)) {
    throw new HttpError(500, 'Admin audit log failed', error.message);
  }
}

async function sendAdminCode(phone, { req } = {}) {
  const admin = await findAdminByPhone(phone);
  if (!admin || admin.status !== 'active') {
    throw new HttpError(403, 'This phone is not allowed to access admin console');
  }
  await sendPhoneCode(phone, { req });
  return { ok: true };
}

async function verifyAdminCode(phone, code, { req } = {}) {
  const verified = await verifyPhoneCode(phone, code);
  let admin = await findAdminByPhone(verified.user.phone || phone);
  if (!admin || admin.status !== 'active') {
    throw new HttpError(403, 'This phone is not allowed to access admin console');
  }
  admin = await upsertEnvAdminIfNeeded(admin);
  await updateAdminLastLogin(admin);
  await writeAdminAuditLog({
    admin,
    action: 'admin.login',
    targetType: 'admin_user',
    targetId: admin.id,
    detail: { phone: admin.phone },
    req,
  });
  return {
    token: createAdminToken(admin),
    admin,
  };
}

async function requireAdmin(req, permission) {
  const token = getBearerToken(req);
  const payload = readAdminToken(token);
  if (!payload) throw new HttpError(401, 'Admin login expired');
  const admin = await findAdminByPhone(payload.phone);
  if (!admin || admin.status !== 'active') {
    throw new HttpError(403, 'Admin account is disabled or not allowed');
  }
  requirePermission(admin, permission);
  return admin;
}

async function listUsers({ q, status, page, pageSize }) {
  const supabase = getSupabaseServiceClient();
  const p = pageParams(page, pageSize);
  let query = supabase
    .from('app_users')
    .select('*, wallets(balance_cents,currency,updated_at)', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(p.from, p.to);
  if (q) {
    const text = searchText(q);
    if (text) query = query.or(`phone.ilike.%${text}%,nickname.ilike.%${text}%`);
  }
  if (status) query = query.eq('status', status);
  const { data, error, count } = await query;
  if (error) throw new HttpError(500, 'Admin users query failed', error.message);
  return {
    items: (data || []).map(mapUser),
    total: Number(count || 0),
    page: p.page,
    pageSize: p.pageSize,
  };
}

async function getUserDetail({ userId, phone }) {
  if (!userId && !phone) throw new HttpError(400, 'Missing user id or phone');
  const supabase = getSupabaseServiceClient();
  let query = supabase
    .from('app_users')
    .select('*, wallets(*)')
    .limit(1);
  if (userId) query = query.eq('id', userId);
  if (phone) query = query.eq('phone', normalizePhone(phone));
  const { data, error } = await query.maybeSingle();
  if (error) throw new HttpError(500, 'Admin user detail query failed', error.message);
  if (!data) throw new HttpError(404, 'User not found');
  const user = mapUser(data);
  const [transactions, recharges, reports] = await Promise.all([
    listWalletTransactions({ userId: user.id, page: 1, pageSize: 10 }),
    listRechargeOrders({ userId: user.id, page: 1, pageSize: 10 }),
    listAiReportOrders({ userId: user.id, page: 1, pageSize: 10 }),
  ]);
  return {
    user,
    transactions: transactions.items,
    rechargeOrders: recharges.items,
    aiReports: reports.items,
  };
}

async function listWalletTransactions({ userId, page, pageSize }) {
  const supabase = getSupabaseServiceClient();
  const p = pageParams(page, pageSize);
  let query = supabase
    .from('wallet_transactions')
    .select('*', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(p.from, p.to);
  if (userId) query = query.eq('user_id', userId);
  const { data, error, count } = await query;
  if (error) throw new HttpError(500, 'Admin wallet transactions query failed', error.message);
  return {
    items: (data || []).map(mapTransaction),
    total: Number(count || 0),
    page: p.page,
    pageSize: p.pageSize,
  };
}

async function listRechargeOrders({ userId, status, provider, outTradeNo, page, pageSize }) {
  const supabase = getSupabaseServiceClient();
  const p = pageParams(page, pageSize);
  let query = supabase
    .from('recharge_orders')
    .select('*, app_users(phone,nickname)', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(p.from, p.to);
  if (userId) query = query.eq('user_id', userId);
  if (status) query = query.eq('status', status);
  if (provider) query = query.eq('provider', provider);
  if (outTradeNo) query = query.eq('out_trade_no', outTradeNo);
  const { data, error, count } = await query;
  if (error) throw new HttpError(500, 'Admin recharge orders query failed', error.message);
  return {
    items: (data || []).map(mapRecharge),
    total: Number(count || 0),
    page: p.page,
    pageSize: p.pageSize,
  };
}

async function listAiReportOrders({ userId, status, productId, page, pageSize }) {
  const supabase = getSupabaseServiceClient();
  const p = pageParams(page, pageSize);
  let query = supabase
    .from('ai_report_orders')
    .select('*, app_users(phone,nickname)', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(p.from, p.to);
  if (userId) query = query.eq('user_id', userId);
  if (status) query = query.eq('status', status);
  if (productId) query = query.eq('product_id', productId);
  const { data, error, count } = await query;
  if (error) throw new HttpError(500, 'Admin AI report orders query failed', error.message);
  return {
    items: (data || []).map((row) => mapAiReport(row)),
    total: Number(count || 0),
    page: p.page,
    pageSize: p.pageSize,
  };
}

async function getAiReportDetailForAdmin({ orderId }) {
  if (!orderId) throw new HttpError(400, 'Missing AI report order id');
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase
    .from('ai_report_orders')
    .select('*, app_users(phone,nickname)')
    .eq('id', orderId)
    .single();
  if (error) throw new HttpError(404, 'AI report not found');
  return mapAiReport(data, { includeText: true });
}

async function adjustWallet({ admin, userId, amountCents, reason, req }) {
  requirePermission(admin, 'wallet:adjust');
  const amount = Number(amountCents);
  if (!Number.isInteger(amount) || amount === 0) {
    throw new HttpError(400, 'Adjustment amount must be a non-zero integer in cents');
  }
  const maxAbs = Math.max(100, Number(process.env.ADMIN_MAX_ADJUST_CENTS || 100000));
  if (Math.abs(amount) > maxAbs) {
    throw new HttpError(400, 'Adjustment amount exceeds admin safety limit');
  }
  const note = String(reason || '').trim();
  if (note.length < 4) throw new HttpError(400, 'Adjustment reason is required');

  const supabase = getSupabaseServiceClient();
  const requestId = crypto.randomUUID();
  const { data, error } = await supabase.rpc('admin_adjust_wallet', {
    p_admin_user_id: admin.id && !String(admin.id).startsWith('env:') ? admin.id : null,
    p_admin_phone: admin.phone,
    p_user_id: userId,
    p_amount_cents: amount,
    p_reason: note,
    p_request_id: requestId,
    p_client_ip: req ? getClientIp(req) : null,
    p_user_agent: String(req?.headers?.['user-agent'] || '').slice(0, 500),
  });
  if (error) throw new HttpError(400, 'Admin wallet adjustment failed', error.message);
  return {
    requestId,
    wallet: data?.wallet
      ? {
          balanceCents: Number(data.wallet.balance_cents || 0),
          currency: data.wallet.currency || 'CNY',
          updatedAt: data.wallet.updated_at,
        }
      : null,
    transaction: data?.transaction ? mapTransaction(data.transaction) : null,
    alreadyApplied: Boolean(data?.already_applied),
  };
}

async function listAuditLogs({ action, targetType, page, pageSize }) {
  const supabase = getSupabaseServiceClient();
  const p = pageParams(page, pageSize);
  let query = supabase
    .from('admin_audit_logs')
    .select('*', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(p.from, p.to);
  if (action) query = query.eq('action', action);
  if (targetType) query = query.eq('target_type', targetType);
  const { data, error, count } = await query;
  if (error) throw new HttpError(500, 'Admin audit logs query failed', error.message);
  return {
    items: (data || []).map(mapAuditLog),
    total: Number(count || 0),
    page: p.page,
    pageSize: p.pageSize,
  };
}

async function getAdminDashboard() {
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase.rpc('admin_dashboard_summary');
  if (error) throw new HttpError(500, 'Admin dashboard query failed', error.message);
  return data || {};
}

module.exports = {
  adjustWallet,
  getAdminDashboard,
  getAiReportDetailForAdmin,
  listAiReportOrders,
  listAuditLogs,
  listRechargeOrders,
  listUsers,
  listWalletTransactions,
  getUserDetail,
  requireAdmin,
  sendAdminCode,
  verifyAdminCode,
};

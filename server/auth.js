const crypto = require('crypto');
const { getSupabaseAnonClient, getSupabaseServiceClient } = require('./supabaseClient');
const { HttpError } = require('./response');

const phonePattern = /^1[3-9]\d{9}$/;

function normalizePhone(phone) {
  const value = String(phone || '').trim();
  if (!phonePattern.test(value)) {
    throw new HttpError(400, '请输入有效的中国大陆手机号码');
  }
  return value;
}

function isMockOtpEnabled() {
  const enabled = ['1', 'true', 'yes', 'on'].includes(
    String(process.env.ENABLE_MOCK_OTP || '').toLowerCase(),
  );
  return enabled && Boolean(process.env.MOCK_OTP_CODE);
}

function mockAuthUserId(phone) {
  const hex = crypto.createHash('sha256').update(`guoxueapp:${phone}`).digest('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20, 32)}`;
}

async function sendPhoneCode(phone) {
  const normalized = normalizePhone(phone);
  if (isMockOtpEnabled()) {
    return { ok: true, mock: true };
  }
  const supabase = getSupabaseAnonClient();
  const { error } = await supabase.auth.signInWithOtp({ phone: normalized });
  if (error) {
    throw new HttpError(400, '验证码发送失败，请稍后再试');
  }
  return { ok: true };
}

async function verifyPhoneCode(phone, code) {
  const normalized = normalizePhone(phone);
  const token = String(code || '').trim();
  if (!token) throw new HttpError(400, '请输入短信验证码');

  if (isMockOtpEnabled() && token === process.env.MOCK_OTP_CODE) {
    const authUser = {
      id: mockAuthUserId(normalized),
      phone: normalized,
    };
    const business = await ensureBusinessUser(authUser);
    return {
      token: `mock:${normalized}`,
      user: business.user,
    };
  }

  const supabase = getSupabaseAnonClient();
  const { data, error } = await supabase.auth.verifyOtp({
    phone: normalized,
    token,
    type: 'sms',
  });
  if (error || !data?.session?.access_token || !data?.user) {
    throw new HttpError(401, '验证码校验失败或已过期');
  }
  const business = await ensureBusinessUser(data.user);
  return {
    token: data.session.access_token,
    user: business.user,
  };
}

function getBearerToken(req) {
  const raw = req.headers?.authorization || req.headers?.Authorization || '';
  const match = String(raw).match(/^Bearer\s+(.+)$/i);
  if (!match) throw new HttpError(401, '请先登录');
  return match[1].trim();
}

async function getAuthUserFromToken(token) {
  if (token.startsWith('mock:') && isMockOtpEnabled()) {
    const phone = token.slice(5);
    return {
      id: mockAuthUserId(phone),
      phone,
    };
  }
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data?.user) {
    throw new HttpError(401, '登录状态已失效，请重新登录');
  }
  return data.user;
}

function mapBusinessPayload(payload) {
  return {
    user: {
      id: payload.user.id,
      phone: payload.user.phone,
      nickname: payload.user.nickname,
      avatarUrl: payload.user.avatar_url,
      status: payload.user.status,
    },
    wallet: {
      balanceCents: Number(payload.wallet.balance_cents || 0),
      currency: payload.wallet.currency || 'CNY',
      updatedAt: payload.wallet.updated_at,
      transactions: [],
    },
  };
}

async function ensureBusinessUser(authUser) {
  const phone = authUser.phone || authUser.user_metadata?.phone || null;
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase.rpc('ensure_app_user', {
    p_auth_user_id: authUser.id,
    p_phone: phone,
  });
  if (error) throw new HttpError(500, '用户账户初始化失败', error.message);
  return mapBusinessPayload(data);
}

async function requireUser(req) {
  const token = getBearerToken(req);
  const authUser = await getAuthUserFromToken(token);
  const business = await ensureBusinessUser(authUser);
  return {
    token,
    authUser,
    appUser: business.user,
    wallet: business.wallet,
  };
}

module.exports = {
  ensureBusinessUser,
  normalizePhone,
  requireUser,
  sendPhoneCode,
  verifyPhoneCode,
};

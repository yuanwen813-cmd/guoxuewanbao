const crypto = require('crypto');
const { getAliyunSmsStatus, sendAliyunSmsCode } = require('./aliyunSms');
const { getSupabaseServiceClient } = require('./supabaseClient');
const { HttpError } = require('./response');
const { grantRegistrationBonusIfEligible } = require('./walletService');
const { getClientIp } = require('./security');

const mainlandMobilePattern = /^1[3-9]\d{9}$/;

function normalizePhone(phone) {
  const raw = String(phone || '').trim();
  let value = raw.replace(/[\s\-()]/g, '');
  if (value.startsWith('+86')) {
    value = value.slice(3);
  } else if (value.startsWith('0086')) {
    value = value.slice(4);
  } else if (value.startsWith('86') && value.length === 13) {
    value = value.slice(2);
  }
  if (!mainlandMobilePattern.test(value)) {
    throw new HttpError(400, '请输入有效的中国大陆手机号码');
  }
  return value;
}

function normalizePhoneOrNull(phone) {
  try {
    return normalizePhone(phone);
  } catch (_) {
    return null;
  }
}

function toSupabasePhone(phone) {
  return `+86${normalizePhone(phone)}`;
}

function isMockOtpEnabled() {
  const enabled = ['1', 'true', 'yes', 'on'].includes(
    String(process.env.ENABLE_MOCK_OTP || '').toLowerCase(),
  );
  return enabled && Boolean(process.env.MOCK_OTP_CODE);
}

function smsCodeTtlMs() {
  return Math.max(1, Number(process.env.SMS_CODE_TTL_MINUTES || 5)) * 60 * 1000;
}

function smsMinIntervalMs() {
  return Math.max(10, Number(process.env.SMS_CODE_MIN_INTERVAL_SECONDS || 60)) *
    1000;
}

function smsMaxPerHour() {
  return Math.max(1, Number(process.env.SMS_CODE_MAX_PER_HOUR || 5));
}

function smsIpMinIntervalMs() {
  return Math.max(1, Number(process.env.SMS_IP_MIN_INTERVAL_SECONDS || 5)) *
    1000;
}

function smsIpMaxPerHour() {
  return Math.max(1, Number(process.env.SMS_IP_MAX_PER_HOUR || 30));
}

function smsGlobalMaxPerMinute() {
  return Math.max(1, Number(process.env.SMS_GLOBAL_MAX_PER_MINUTE || 120));
}

function missingSmsAttemptTable(error) {
  const message = String(error?.message || '');
  return (
    error?.code === '42P01' ||
    error?.code === 'PGRST205' ||
    message.includes('sms_send_attempts')
  );
}

function authSecret() {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new HttpError(500, '服务端缺少环境变量：JWT_SECRET');
  return secret;
}

function mockAuthUserId(phone) {
  const hex = crypto
    .createHash('sha256')
    .update(`guoxueapp:${normalizePhone(phone)}`)
    .digest('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20, 32)}`;
}

function codeHash(phone, code) {
  return crypto
    .createHmac('sha256', authSecret())
    .update(`${normalizePhone(phone)}:${String(code || '').trim()}`)
    .digest('hex');
}

function newSmsCode() {
  return crypto.randomInt(0, 1000000).toString().padStart(6, '0');
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

function createAppAuthToken(phone) {
  const normalized = normalizePhone(phone);
  const payload = {
    typ: 'phone_login',
    sub: mockAuthUserId(normalized),
    phone: normalized,
    exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 30,
  };
  const encoded = base64UrlEncode(JSON.stringify(payload));
  const signature = crypto
    .createHmac('sha256', authSecret())
    .update(encoded)
    .digest('base64url');
  return `app:${encoded}.${signature}`;
}

function readAppAuthToken(token) {
  if (!String(token || '').startsWith('app:')) return null;
  try {
    const raw = String(token).slice(4);
    const [encoded, signature] = raw.split('.');
    if (!encoded || !signature) return null;
    const expected = crypto
      .createHmac('sha256', authSecret())
      .update(encoded)
      .digest('base64url');
    const actualBuffer = Buffer.from(signature);
    const expectedBuffer = Buffer.from(expected);
    if (
      actualBuffer.length !== expectedBuffer.length ||
      !crypto.timingSafeEqual(actualBuffer, expectedBuffer)
    ) {
      return null;
    }
    const payload = JSON.parse(base64UrlDecode(encoded));
    if (payload.typ !== 'phone_login' || !payload.sub || !payload.phone) {
      return null;
    }
    if (Number(payload.exp || 0) < Math.floor(Date.now() / 1000)) {
      return null;
    }
    return {
      id: payload.sub,
      phone: normalizePhone(payload.phone),
    };
  } catch (_) {
    return null;
  }
}

function getAuthRuntimeStatus() {
  const supabaseUrl = process.env.SUPABASE_URL || '';
  let supabaseHost = '';
  let supabaseUrlValid = false;
  let supabaseUrlHasRestPath = false;
  try {
    const parsed = new URL(supabaseUrl);
    supabaseHost = parsed.host;
    supabaseUrlHasRestPath = parsed.pathname.includes('/rest/v1');
    supabaseUrlValid =
      parsed.protocol === 'https:' &&
      parsed.host.endsWith('.supabase.co') &&
      !supabaseUrlHasRestPath;
  } catch (_) {
    supabaseUrlValid = false;
  }
  return {
    mockOtpEnabled: isMockOtpEnabled(),
    enableMockOtp: process.env.ENABLE_MOCK_OTP || '',
    hasMockOtpCode: Boolean(process.env.MOCK_OTP_CODE),
    nodeEnv: process.env.NODE_ENV || '',
    vercelEnv: process.env.VERCEL_ENV || '',
    hasJwtSecret: Boolean(process.env.JWT_SECRET),
    hasSupabaseUrl: Boolean(supabaseUrl),
    supabaseHost,
    supabaseUrlValid,
    supabaseUrlHasRestPath,
    hasSupabaseAnonKey: Boolean(process.env.SUPABASE_ANON_KEY),
    hasSupabaseServiceRoleKey: Boolean(process.env.SUPABASE_SERVICE_ROLE_KEY),
    ...getAliyunSmsStatus(),
  };
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

async function countSmsAttempts(supabase, buildQuery) {
  const { count, error } = await buildQuery(
    supabase
      .from('sms_send_attempts')
      .select('id', { count: 'exact', head: true }),
  );
  if (error) {
    if (missingSmsAttemptTable(error)) return null;
    throw new HttpError(500, '短信发送风控检查失败', error.message);
  }
  return Number(count || 0);
}

async function insertSmsAttempt(supabase, payload) {
  const { data, error } = await supabase
    .from('sms_send_attempts')
    .insert(payload)
    .select('id')
    .single();
  if (error) {
    if (missingSmsAttemptTable(error)) return null;
    throw new HttpError(500, '短信发送风控记录失败', error.message);
  }
  return data?.id || null;
}

async function updateSmsAttempt(supabase, id, patch) {
  if (!id) return;
  await supabase
    .from('sms_send_attempts')
    .update({
      ...patch,
      completed_at: new Date().toISOString(),
    })
    .eq('id', id);
}

async function assertSmsRateLimit(supabase, phone, { req } = {}) {
  const now = Date.now();
  const ip = req ? getClientIp(req) : 'unknown';
  const recentSince = new Date(now - smsMinIntervalMs()).toISOString();
  const recentIpSince = new Date(now - smsIpMinIntervalMs()).toISOString();
  const hourSince = new Date(now - 60 * 60 * 1000).toISOString();
  const minuteSince = new Date(now - 60 * 1000).toISOString();

  const { data: recent, error: recentError } = await supabase
    .from('sms_login_codes')
    .select('id')
    .eq('phone', phone)
    .gte('created_at', recentSince)
    .limit(1);
  if (recentError) throw new HttpError(500, '短信发送频率检查失败', recentError.message);
  if ((recent || []).length > 0) {
    throw new HttpError(429, '验证码发送过于频繁，请稍后再试');
  }

  const { count, error: countError } = await supabase
    .from('sms_login_codes')
    .select('id', { count: 'exact', head: true })
    .eq('phone', phone)
    .gte('created_at', hourSince);
  if (countError) throw new HttpError(500, '短信发送频率检查失败', countError.message);
  if (Number(count || 0) >= smsMaxPerHour()) {
    throw new HttpError(429, '验证码发送次数过多，请稍后再试');
  }

  const recentPhoneAttempts = await countSmsAttempts(supabase, (query) =>
    query.eq('phone', phone).gte('created_at', recentSince),
  );
  if (recentPhoneAttempts !== null && recentPhoneAttempts > 0) {
    throw new HttpError(429, '验证码发送过于频繁，请稍后再试');
  }

  if (ip && ip !== 'unknown') {
    const recentIpAttempts = await countSmsAttempts(supabase, (query) =>
      query.eq('client_ip', ip).gte('created_at', recentIpSince),
    );
    if (recentIpAttempts !== null && recentIpAttempts > 0) {
      throw new HttpError(429, '验证码发送过于频繁，请稍后再试');
    }
    const hourlyIpAttempts = await countSmsAttempts(supabase, (query) =>
      query.eq('client_ip', ip).gte('created_at', hourSince),
    );
    if (hourlyIpAttempts !== null && hourlyIpAttempts >= smsIpMaxPerHour()) {
      throw new HttpError(429, '验证码发送次数过多，请稍后再试');
    }
  }

  const globalMinuteAttempts = await countSmsAttempts(supabase, (query) =>
    query.gte('created_at', minuteSince),
  );
  if (
    globalMinuteAttempts !== null &&
    globalMinuteAttempts >= smsGlobalMaxPerMinute()
  ) {
    throw new HttpError(429, '短信通道繁忙，请稍后再试');
  }
}

async function sendPhoneCode(phone, { req } = {}) {
  const normalized = normalizePhone(phone);
  if (isMockOtpEnabled()) {
    return { ok: true, mock: true };
  }
  const supabase = getSupabaseServiceClient();
  await assertSmsRateLimit(supabase, normalized, { req });
  const attemptId = await insertSmsAttempt(supabase, {
    phone: normalized,
    client_ip: req ? getClientIp(req) : null,
    user_agent: String(req?.headers?.['user-agent'] || '').slice(0, 500),
    status: 'pending',
  });

  const code = newSmsCode();
  let sms;
  try {
    sms = await sendAliyunSmsCode({ phone: normalized, code });
  } catch (error) {
    await updateSmsAttempt(supabase, attemptId, {
      status: 'failed',
      error_message: error.message || 'sms provider failed',
    });
    throw error;
  }

  const expiresAt = new Date(Date.now() + smsCodeTtlMs()).toISOString();
  const { error } = await supabase.from('sms_login_codes').insert({
    phone: normalized,
    code_hash: codeHash(normalized, code),
    provider: 'aliyun',
    provider_request_id: sms.requestId,
    provider_biz_id: sms.bizId,
    expires_at: expiresAt,
  });
  if (error) {
    await updateSmsAttempt(supabase, attemptId, {
      status: 'failed',
      provider_request_id: sms.requestId,
      provider_biz_id: sms.bizId,
      error_message: error.message || 'sms code record failed',
    });
    throw new HttpError(500, '短信验证码记录保存失败，请稍后再试', error.message);
  }
  await updateSmsAttempt(supabase, attemptId, {
    status: 'sent',
    provider_request_id: sms.requestId,
    provider_biz_id: sms.bizId,
  });
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
      token: createAppAuthToken(normalized),
      user: business.user,
    };
  }

  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase
    .from('sms_login_codes')
    .select('*')
    .eq('phone', normalized)
    .is('consumed_at', null)
    .gt('expires_at', new Date().toISOString())
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  if (error) throw new HttpError(500, '验证码校验失败，请稍后再试', error.message);
  if (!data) throw new HttpError(401, '验证码错误或已过期');
  if (Number(data.attempts || 0) >= 5) {
    throw new HttpError(429, '验证码错误次数过多，请重新获取');
  }

  const expected = Buffer.from(data.code_hash || '');
  const actual = Buffer.from(codeHash(normalized, token));
  const ok =
    expected.length === actual.length && crypto.timingSafeEqual(expected, actual);
  if (!ok) {
    await supabase
      .from('sms_login_codes')
      .update({ attempts: Number(data.attempts || 0) + 1 })
      .eq('id', data.id);
    throw new HttpError(401, '验证码错误或已过期');
  }

  await supabase
    .from('sms_login_codes')
    .update({
      consumed_at: new Date().toISOString(),
      attempts: Number(data.attempts || 0) + 1,
    })
    .eq('id', data.id);

  const authUser = {
    id: mockAuthUserId(normalized),
    phone: normalized,
  };
  const business = await ensureBusinessUser(authUser);
  return {
    token: createAppAuthToken(normalized),
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
  const appUser = readAppAuthToken(token);
  if (appUser) return appUser;
  throw new HttpError(401, '登录状态已失效，请重新登录');
}

async function ensureBusinessUser(authUser) {
  const phone =
    normalizePhoneOrNull(authUser.phone) ||
    normalizePhoneOrNull(authUser.user_metadata?.phone) ||
    null;
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase.rpc('ensure_app_user', {
    p_auth_user_id: authUser.id,
    p_phone: phone,
  });
  if (error) throw new HttpError(500, '用户账户初始化失败', error.message);
  const business = mapBusinessPayload(data);
  const bonus = await grantRegistrationBonusIfEligible(business.user.id);
  if (bonus.wallet) {
    business.wallet = {
      ...bonus.wallet,
      transactions: [],
    };
  }
  business.registrationBonus = {
    eligible: bonus.eligible,
    granted: bonus.granted,
    alreadyGranted: bonus.alreadyGranted,
  };
  return business;
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
  createAppAuthToken,
  ensureBusinessUser,
  getAuthRuntimeStatus,
  normalizePhone,
  requireUser,
  sendPhoneCode,
  toSupabasePhone,
  verifyPhoneCode,
};

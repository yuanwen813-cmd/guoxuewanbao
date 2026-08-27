const { getSupabaseServiceClient } = require('./supabaseClient');
const { HttpError } = require('./response');

const maxBatchSize = 100;
const maxPayloadBytes = 96 * 1024;

function cleanText(value, maxLength = 200) {
  const text = String(value || '').trim();
  return text ? text.slice(0, maxLength) : null;
}

function validClientId(value) {
  const id = String(value || '').trim();
  if (!id || id.length > 160 || !/^[A-Za-z0-9_.:-]+$/.test(id)) {
    throw new HttpError(400, '同步记录标识无效');
  }
  return id;
}

function parseClientDate(value, fallback) {
  const date = new Date(value || fallback || Date.now());
  if (Number.isNaN(date.getTime())) {
    throw new HttpError(400, '同步记录时间无效');
  }
  return date.toISOString();
}

function validatePayload(value, kind) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpError(400, `${kind}同步内容无效`);
  }
  const size = Buffer.byteLength(JSON.stringify(value), 'utf8');
  if (size > maxPayloadBytes) {
    throw new HttpError(413, `${kind}同步内容过大`);
  }
  return value;
}

function normalizeBatch(value, name) {
  if (value == null) return [];
  if (!Array.isArray(value)) throw new HttpError(400, `${name}必须是数组`);
  if (value.length > maxBatchSize) {
    throw new HttpError(400, `${name}单次最多同步 ${maxBatchSize} 条`);
  }
  return value;
}

async function upsertPayloadRows({ table, userId, rows, idField, kind }) {
  if (rows.length === 0) return;
  const supabase = getSupabaseServiceClient();
  const normalized = rows.map((raw) => {
    const payload = validatePayload(raw, kind);
    const clientId = validClientId(payload.id);
    return {
      user_id: userId,
      [idField]: clientId,
      payload_json: payload,
      client_updated_at: parseClientDate(
        payload.updatedAt,
        payload.createdAt,
      ),
    };
  });

  const ids = normalized.map((row) => row[idField]);
  const { data: existing, error: existingError } = await supabase
    .from(table)
    .select(`${idField},client_updated_at`)
    .eq('user_id', userId)
    .in(idField, ids);
  if (existingError) {
    throw new HttpError(500, `${kind}同步检查失败`, existingError.message);
  }
  const existingDates = new Map(
    (existing || []).map((row) => [
      row[idField],
      new Date(row.client_updated_at).getTime(),
    ]),
  );
  const newerRows = normalized.filter((row) => {
    const existingTime = existingDates.get(row[idField]);
    return existingTime == null ||
      new Date(row.client_updated_at).getTime() >= existingTime;
  });
  if (newerRows.length === 0) return;

  const { error } = await supabase.from(table).upsert(newerRows, {
    onConflict: `user_id,${idField}`,
  });
  if (error) throw new HttpError(500, `${kind}同步失败`, error.message);
}

async function deletePayloadRows({ table, userId, ids, idField, kind }) {
  if (ids.length === 0) return;
  const normalized = ids.map(validClientId);
  const supabase = getSupabaseServiceClient();
  const { error } = await supabase
    .from(table)
    .delete()
    .eq('user_id', userId)
    .in(idField, normalized);
  if (error) throw new HttpError(500, `${kind}删除同步失败`, error.message);
}

async function getUserData(userId) {
  const supabase = getSupabaseServiceClient();
  const [historyResult, profileResult] = await Promise.all([
    supabase
      .from('user_history_records')
      .select('payload_json')
      .eq('user_id', userId)
      .order('client_updated_at', { ascending: false })
      .limit(1000),
    supabase
      .from('birth_profiles')
      .select('payload_json')
      .eq('user_id', userId)
      .order('client_updated_at', { ascending: false })
      .limit(1000),
  ]);
  if (historyResult.error) {
    throw new HttpError(500, '历史记录读取失败', historyResult.error.message);
  }
  if (profileResult.error) {
    throw new HttpError(500, '命盘档案读取失败', profileResult.error.message);
  }
  return {
    histories: (historyResult.data || []).map((row) => row.payload_json),
    profiles: (profileResult.data || []).map((row) => row.payload_json),
    syncedAt: new Date().toISOString(),
  };
}

async function syncUserData(userId, body) {
  const histories = normalizeBatch(body.histories, '历史记录');
  const profiles = normalizeBatch(body.profiles, '命盘档案');
  const deletedHistoryIds = normalizeBatch(
    body.deletedHistoryIds,
    '历史记录删除列表',
  );
  const deletedProfileIds = normalizeBatch(
    body.deletedProfileIds,
    '命盘档案删除列表',
  );

  await deletePayloadRows({
    table: 'user_history_records',
    userId,
    ids: deletedHistoryIds,
    idField: 'client_record_id',
    kind: '历史记录',
  });
  await deletePayloadRows({
    table: 'birth_profiles',
    userId,
    ids: deletedProfileIds,
    idField: 'client_profile_id',
    kind: '命盘档案',
  });
  await upsertPayloadRows({
    table: 'user_history_records',
    userId,
    rows: histories,
    idField: 'client_record_id',
    kind: '历史记录',
  });
  await upsertPayloadRows({
    table: 'birth_profiles',
    userId,
    rows: profiles,
    idField: 'client_profile_id',
    kind: '命盘档案',
  });
  return getUserData(userId);
}

async function saveAiReportFeedback(userId, body) {
  const reportId = cleanText(body.reportId, 80);
  const rating = cleanText(body.rating, 20);
  const reason = cleanText(body.reason, 500);
  if (!reportId) throw new HttpError(400, '缺少 AI 报告标识');
  if (!['helpful', 'not_helpful'].includes(rating)) {
    throw new HttpError(400, '评价选项无效');
  }
  const supabase = getSupabaseServiceClient();
  const { data: report, error: reportError } = await supabase
    .from('ai_report_orders')
    .select('id,status')
    .eq('id', reportId)
    .eq('user_id', userId)
    .maybeSingle();
  if (reportError || !report) throw new HttpError(404, 'AI 报告不存在');
  if (report.status !== 'completed') {
    throw new HttpError(400, '只能评价已完成的 AI 报告');
  }
  const { error } = await supabase.from('ai_report_feedback').upsert(
    {
      user_id: userId,
      ai_report_order_id: report.id,
      rating,
      reason,
    },
    { onConflict: 'user_id,ai_report_order_id' },
  );
  if (error) throw new HttpError(500, 'AI 报告评价保存失败', error.message);
  return { reportId, rating };
}

async function recordAttribution(userId, body) {
  const source = cleanText(body.source, 80) || 'direct';
  const medium = cleanText(body.medium, 80);
  const campaign = cleanText(body.campaign, 120);
  const referrer = cleanText(body.referrer, 500);
  const now = new Date().toISOString();
  const supabase = getSupabaseServiceClient();
  const { data: existing, error: existingError } = await supabase
    .from('user_attributions')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();
  if (existingError) {
    throw new HttpError(500, '来源记录读取失败', existingError.message);
  }
  const { error } = await supabase.from('user_attributions').upsert(
    {
      user_id: userId,
      first_source: existing?.first_source || source,
      first_medium: existing?.first_medium || medium,
      first_campaign: existing?.first_campaign || campaign,
      first_referrer: existing?.first_referrer || referrer,
      first_seen_at: existing?.first_seen_at || now,
      latest_source: source,
      latest_medium: medium,
      latest_campaign: campaign,
      latest_referrer: referrer,
      last_seen_at: now,
    },
    { onConflict: 'user_id' },
  );
  if (error) throw new HttpError(500, '来源记录保存失败', error.message);
  return { source, medium, campaign };
}

async function exportAccountData(userId) {
  const supabase = getSupabaseServiceClient();
  const [user, wallet, transactions, recharges, reports, feedback, synced] =
    await Promise.all([
      supabase.from('app_users').select('*').eq('id', userId).single(),
      supabase.from('wallets').select('*').eq('user_id', userId).single(),
      supabase.from('wallet_transactions').select('*').eq('user_id', userId)
        .order('created_at', { ascending: false }).limit(1000),
      supabase.from('recharge_orders').select('*').eq('user_id', userId)
        .order('created_at', { ascending: false }).limit(1000),
      supabase.from('ai_report_orders').select('*').eq('user_id', userId)
        .order('created_at', { ascending: false }).limit(1000),
      supabase.from('ai_report_feedback').select('*').eq('user_id', userId)
        .order('created_at', { ascending: false }).limit(1000),
      getUserData(userId),
    ]);
  const failed = [user, wallet, transactions, recharges, reports, feedback]
    .find((result) => result.error);
  if (failed) throw new HttpError(500, '个人数据导出失败', failed.error.message);
  return {
    exportedAt: new Date().toISOString(),
    account: user.data,
    wallet: wallet.data,
    walletTransactions: transactions.data || [],
    rechargeOrders: recharges.data || [],
    aiReports: reports.data || [],
    aiReportFeedback: feedback.data || [],
    histories: synced.histories,
    birthProfiles: synced.profiles,
  };
}

async function deleteAccountData(userId, body) {
  if (String(body.confirmation || '').trim() !== '确认注销') {
    throw new HttpError(400, '请输入“确认注销”后再提交');
  }
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase.rpc('delete_account_data', {
    p_user_id: userId,
  });
  if (error) {
    const message = String(error.message || '');
    if (message.includes('WALLET_BALANCE_NOT_ZERO')) {
      throw new HttpError(409, '钱包仍有余额，请先联系客服处理后再注销');
    }
    if (message.includes('PENDING_RECHARGE_EXISTS')) {
      throw new HttpError(409, '仍有待支付充值订单，请先取消后再注销');
    }
    throw new HttpError(500, '账户注销失败', error.message);
  }
  return data || { deleted: true };
}

module.exports = {
  deleteAccountData,
  exportAccountData,
  getUserData,
  recordAttribution,
  saveAiReportFeedback,
  syncUserData,
};

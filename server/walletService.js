const crypto = require('crypto');
const { getSupabaseServiceClient } = require('./supabaseClient');
const { HttpError } = require('./response');
const { truncateForLog } = require('./security');

function mapWallet(row) {
  if (!row) return null;
  return {
    balanceCents: Number(row.balance_cents || 0),
    pointsBalance: Number(row.points_balance ?? (Number(row.balance_cents || 0) / 100)),
    currency: row.currency || 'CNY',
    updatedAt: row.updated_at || row.created_at,
  };
}

function mapTransaction(row) {
  return {
    id: row.id,
    type: row.type,
    amountCents: Number(row.amount_cents || 0),
    balanceAfterCents: Number(row.balance_after_cents || 0),
    pointsChange: Number(row.amount_cents || 0) / 100,
    pointsBalanceAfter: Number(row.balance_after_cents || 0) / 100,
    currency: row.currency || 'CNY',
    refType: row.ref_type,
    refId: row.ref_id,
    outTradeNo: row.out_trade_no,
    note: row.type === 'recharge' ? '积分充值'
      : row.type === 'ai_debit' ? 'AI 解析扣积分'
      : row.type === 'ai_refund' ? 'AI 解析失败退积分'
      : row.note,
    createdAt: row.created_at,
  };
}

function mapRegistrationBonus(row) {
  return {
    eligible: Boolean(row?.eligible),
    granted: Boolean(row?.granted),
    alreadyGranted: Boolean(row?.already_granted),
    wallet: mapWallet(row?.wallet),
    transaction: row?.transaction ? mapTransaction(row.transaction) : null,
  };
}

function mapRechargeOrder(row) {
  return {
    id: row.id,
    outTradeNo: row.out_trade_no,
    provider: row.provider,
    tradeType: row.trade_type,
    amountCents: Number(row.amount_cents || 0),
    pointsGranted: row.status === 'paid' ? Number(row.amount_cents || 0) / 100 : 0,
    currency: row.currency || 'CNY',
    status: row.status,
    providerTradeNo: row.provider_trade_no,
    prepayId: row.prepay_id,
    codeUrl: row.code_url,
    payUrl: row.pay_url,
    paidAt: row.paid_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function mapAiReportOrder(row) {
  return {
    id: row.id,
    productId: row.product_id,
    reportType: row.report_type,
    priceCents: Number(row.price_cents || 0),
    pricePoints: Number(row.price_cents || 0) / 100,
    chargeUnit: row.charge_unit || 'CNY',
    currency: row.currency || 'CNY',
    status: row.status,
    resultText: row.result_text,
    errorMessage: row.error_message,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function truncateJsonForLog(value, maxLength = 12000) {
  const text = JSON.stringify(value || {});
  if (text.length <= maxLength) return value || {};
  return {
    truncated: true,
    originalLength: text.length,
    preview: text.slice(0, maxLength),
  };
}

function newOutTradeNo(provider) {
  const prefix = provider === 'alipay' ? 'ALI' : 'WX';
  const stamp = new Date().toISOString().replace(/[-:.TZ]/g, '').slice(0, 14);
  const random = crypto.randomBytes(5).toString('hex').toUpperCase();
  return `${prefix}${stamp}${random}`;
}

async function getWallet(userId) {
  await reconcileEmptyAiReportsForUser(userId);
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase
    .from('wallets')
    .select('*')
    .eq('user_id', userId)
    .single();
  if (error) throw new HttpError(500, '钱包读取失败', error.message);
  return mapWallet(data);
}

async function reconcileEmptyAiReportsForUser(userId) {
  const supabase = getSupabaseServiceClient();
  const { error: expiryError } = await supabase.rpc('expire_stale_inline_ai_reports', {
    p_user_id: userId,
  });
  if (expiryError && expiryError.code !== 'PGRST202') {
    throw new HttpError(500, 'AI 解析积分核对失败', expiryError.message);
  }
  const { data, error } = await supabase
    .from('ai_report_orders')
    .select('id, result_text')
    .eq('user_id', userId)
    .eq('status', 'completed')
    .order('updated_at', { ascending: false })
    .limit(50);

  if (error) {
    throw new HttpError(500, 'AI 报告状态核对失败', error.message);
  }

  const emptyOrders = (data || []).filter((order) =>
    isInvalidAiReportText(order.result_text),
  );
  for (const order of emptyOrders) {
    await refundAiReport({
      orderId: order.id,
      errorMessage: 'AI 服务未返回有效内容，积分已自动退回',
      model: null,
    });
  }
}

function isInvalidAiReportText(value) {
  const text = String(value || '').trim();
  return !text || text === 'AI 服务未返回内容。' || text === 'AI 服务未返回内容';
}

async function grantRegistrationBonusIfEligible(userId, { supabaseClient } = {}) {
  const supabase = supabaseClient || getSupabaseServiceClient();
  const { data, error } = await supabase.rpc('grant_registration_bonus', {
    p_user_id: userId,
  });
  if (error) {
    const message = String(error.message || '');
    if (error.code === 'PGRST202' || message.includes('grant_registration_bonus')) {
      return {
        eligible: false,
        granted: false,
        alreadyGranted: false,
        wallet: null,
        transaction: null,
        schemaUnavailable: true,
      };
    }
    throw new HttpError(500, '注册赠送积分处理失败', error.message);
  }
  return mapRegistrationBonus(data || {});
}

async function listWalletTransactions(userId, { page = 1, pageSize = 30 } = {}) {
  const currentPage = Math.max(1, Number(page) || 1);
  const size = Math.min(100, Math.max(1, Number(pageSize) || 30));
  const from = (currentPage - 1) * size;
  const to = from + size - 1;
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase
    .from('wallet_transactions')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .range(from, to);
  if (error) throw new HttpError(500, '钱包流水读取失败', error.message);
  return (data || []).map(mapTransaction);
}

async function createRechargeOrder({ userId, provider, tradeType, amountCents }) {
  const outTradeNo = newOutTradeNo(provider);
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase.rpc('create_recharge_order', {
    p_user_id: userId,
    p_provider: provider,
    p_trade_type: tradeType,
    p_amount_cents: amountCents,
    p_out_trade_no: outTradeNo,
  });
  if (error) throw new HttpError(500, '充值订单创建失败', error.message);
  return mapRechargeOrder(data);
}

async function updateRechargeOrderPayment(orderId, patch) {
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase
    .from('recharge_orders')
    .update({
      prepay_id: patch.prepayId || null,
      code_url: patch.codeUrl || null,
      pay_url: patch.payUrl || null,
      raw_create_response: patch.rawCreateResponse || {},
      updated_at: new Date().toISOString(),
    })
    .eq('id', orderId)
    .select('*')
    .single();
  if (error) throw new HttpError(500, '充值支付参数保存失败', error.message);
  return mapRechargeOrder(data);
}

async function getRechargeOrderForUser({ userId, orderId, outTradeNo }) {
  const supabase = getSupabaseServiceClient();
  let query = supabase.from('recharge_orders').select('*').eq('user_id', userId);
  if (orderId) query = query.eq('id', orderId);
  if (outTradeNo) query = query.eq('out_trade_no', outTradeNo);
  const { data, error } = await query.single();
  if (error) throw new HttpError(404, '充值订单不存在');
  return mapRechargeOrder(data);
}

async function cancelRechargeOrderForUser({ userId, orderId, outTradeNo }) {
  if (!orderId && !outTradeNo) {
    throw new HttpError(400, '缺少要取消的充值订单');
  }
  const supabase = getSupabaseServiceClient();
  let query = supabase.from('recharge_orders').select('*').eq('user_id', userId);
  if (orderId) query = query.eq('id', orderId);
  if (outTradeNo) query = query.eq('out_trade_no', outTradeNo);
  const { data: order, error: readError } = await query.single();
  if (readError) throw new HttpError(404, '充值订单不存在');
  if (order.status === 'paid') throw new HttpError(400, '已支付订单不能取消');
  if (order.status !== 'pending') return mapRechargeOrder(order);

  const { data, error } = await supabase
    .from('recharge_orders')
    .update({
      status: 'closed',
      updated_at: new Date().toISOString(),
    })
    .eq('id', order.id)
    .eq('user_id', userId)
    .eq('status', 'pending')
    .select('*')
    .single();
  if (error) throw new HttpError(500, '取消充值订单失败', error.message);
  return mapRechargeOrder(data);
}

async function insertPaymentNotifyLog({
  provider,
  headersJson,
  rawBody,
  parsedJson,
  outTradeNo,
  providerTradeNo,
}) {
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase
    .from('payment_notify_logs')
    .insert({
      provider,
      out_trade_no: outTradeNo || null,
      provider_trade_no: providerTradeNo || null,
      headers_json: truncateJsonForLog(headersJson || {}, 12000),
      raw_body: truncateForLog(rawBody || '', 20000),
      parsed_json: truncateJsonForLog(parsedJson || {}, 12000),
    })
    .select('*')
    .single();
  if (error) throw new HttpError(500, '支付回调日志保存失败', error.message);
  return data;
}

async function markPaymentNotifyLog(logId, patch) {
  if (!logId) return;
  const supabase = getSupabaseServiceClient();
  await supabase
    .from('payment_notify_logs')
    .update({
      verified: Boolean(patch.verified),
      handled: Boolean(patch.handled),
      error_message: patch.errorMessage || null,
    })
    .eq('id', logId);
}

async function markRechargePaid({
  outTradeNo,
  providerTradeNo,
  amountCents,
  notifyLogId,
  rawPayload,
  supabaseClient,
}) {
  const supabase = supabaseClient || getSupabaseServiceClient();
  const { data, error } = await supabase.rpc('mark_recharge_paid', {
    p_out_trade_no: outTradeNo,
    p_provider_trade_no: providerTradeNo || null,
    p_amount_cents: amountCents,
    p_notify_log_id: notifyLogId || null,
    p_raw_payload: rawPayload || {},
  });
  if (error) throw new HttpError(400, '充值入账失败', error.message);
  return {
    order: mapRechargeOrder(data.order),
    wallet: mapWallet(data.wallet),
    alreadyPaid: Boolean(data.already_paid),
  };
}

async function createAiReportDebit({
  userId,
  product,
  inputSnapshotJson,
  baziChartJson,
  questionResultJson,
  promptSnapshot,
  requestId,
  supabaseClient,
}) {
  const supabase = supabaseClient || getSupabaseServiceClient();
  const { data, error } = await supabase.rpc('create_ai_report_debit_once', {
    p_user_id: userId,
    p_product_id: product.id,
    p_report_type: product.reportType,
    p_price_cents: product.priceCents,
    p_input_snapshot_json: inputSnapshotJson || {},
    p_bazi_chart_json: baziChartJson || {},
    p_question_result_json: questionResultJson || {},
    p_prompt_snapshot: promptSnapshot || '',
    p_request_id: requestId || crypto.randomUUID(),
  });
  if (error) {
    const message = String(error.message || '');
    if (message.includes('INSUFFICIENT_BALANCE')) {
      throw new HttpError(402, '积分不足，请先充值后再生成');
    }
    if (message.includes('REQUEST_ID_CONFLICT')) {
      throw new HttpError(409, '解析内容已改变，请重新提交；原请求可在我的报告查看');
    }
    throw new HttpError(500, 'AI 积分扣减任务创建失败', error.message);
  }
  return {
    order: mapAiReportOrder(data.order),
    wallet: mapWallet(data.wallet),
    alreadyPending: Boolean(data.already_pending),
  };
}

async function createQueuedAiReportDebit({
  userId,
  product,
  inputSnapshotJson,
  baziChartJson,
  questionResultJson,
  promptSnapshot,
  userPrompt,
  systemPrompt,
  requestId,
  supabaseClient,
}) {
  const supabase = supabaseClient || getSupabaseServiceClient();
  const { data, error } = await supabase.rpc('start_ai_report_job_once', {
    p_user_id: userId,
    p_product_id: product.id,
    p_report_type: product.reportType,
    p_price_cents: product.priceCents,
    p_input_snapshot_json: inputSnapshotJson || {},
    p_bazi_chart_json: baziChartJson || {},
    p_question_result_json: questionResultJson || {},
    p_prompt_snapshot: promptSnapshot || '',
    p_user_prompt: userPrompt,
    p_system_prompt: systemPrompt || '',
    p_request_id: requestId || crypto.randomUUID(),
  });
  if (error) {
    if (String(error.message || '').includes('REQUEST_ID_CONFLICT')) {
      throw new HttpError(409, '解析内容已改变，请重新提交；原请求可在我的报告查看');
    }
    if (String(error.message || '').includes('INSUFFICIENT_BALANCE')) {
      throw new HttpError(402, '积分不足，请先充值后再生成');
    }
    if (String(error.message || '').includes('AI_REPORT_ALREADY_GENERATING')) {
      throw new HttpError(409, '已有同类命盘报告正在生成，请在“我的报告”查看完成后再提交');
    }
    if (String(error.message || '').includes('AI_WORKER_UNAVAILABLE')) {
      throw new HttpError(503, '命盘解析服务暂未就绪，本次未扣积分，请稍后再试');
    }
    throw new HttpError(503, '长报告服务暂不可用，本次未扣积分');
  }
  return {
    order: mapAiReportOrder(data.order),
    wallet: mapWallet(data.wallet),
    alreadyPending: Boolean(data.already_pending),
  };
}

async function completeAiReport({
  orderId,
  resultText,
  model,
  usage,
  supabaseClient,
}) {
  const normalizedResult = String(resultText || '').trim();
  if (!normalizedResult) {
    throw new HttpError(424, 'AI 服务未返回有效内容');
  }
  const supabase = supabaseClient || getSupabaseServiceClient();
  const { data, error } = await supabase.rpc('complete_ai_report_order', {
    p_order_id: orderId,
    p_result_text: normalizedResult,
    p_model: model || null,
    p_request_tokens: usage?.prompt_tokens || null,
    p_response_tokens: usage?.completion_tokens || null,
  });
  if (error) throw new HttpError(500, 'AI 报告保存失败', error.message);
  return {
    order: mapAiReportOrder(data.order),
    wallet: mapWallet(data.wallet),
  };
}

async function refundAiReport({
  orderId,
  errorMessage,
  model,
  supabaseClient,
}) {
  const supabase = supabaseClient || getSupabaseServiceClient();
  const { data, error } = await supabase.rpc('refund_ai_report_order', {
    p_order_id: orderId,
    p_error_message: errorMessage || 'AI 调用失败，积分已自动退回',
    p_model: model || null,
  });
  if (error) throw new HttpError(500, 'AI 失败积分退回处理失败', error.message);
  return {
    order: mapAiReportOrder(data.order),
    wallet: mapWallet(data.wallet),
    alreadyRefunded: Boolean(data.already_refunded),
  };
}

async function getAiReportForUser({ userId, orderId }) {
  const supabase = getSupabaseServiceClient();
  if (process.env.AI_LONG_REPORTS_ENABLED === 'true') {
    const { error: expiryError } = await supabase.rpc('expire_ai_report_jobs', {
      p_user_id: userId,
    });
    if (expiryError) throw new HttpError(503, '报告状态暂时无法确认，请稍后重试');
  }
  const { data, error } = await supabase
    .from('ai_report_orders')
    .select('*')
    .eq('user_id', userId)
    .eq('id', orderId)
    .single();
  if (error) throw new HttpError(404, '报告不存在');
  return mapAiReportOrder(data);
}

async function listAiReportsForUser(userId, { page = 1, pageSize = 50, supabaseClient } = {}) {
  const currentPage = Number(page);
  const size = Number(pageSize);
  if (!Number.isSafeInteger(currentPage) || currentPage < 1 || currentPage > 1000000
      || !Number.isSafeInteger(size) || size < 1 || size > 100) {
    throw new HttpError(400, '报告分页参数无效');
  }
  const supabase = supabaseClient || getSupabaseServiceClient();
  if (process.env.AI_LONG_REPORTS_ENABLED === 'true') {
    const { error: expiryError } = await supabase.rpc('expire_ai_report_jobs', {
      p_user_id: userId,
    });
    if (expiryError) throw new HttpError(503, '报告状态暂时无法确认，请稍后重试');
  }
  const { data, error } = await supabase
    .from('ai_report_orders')
    .select('id, product_id, report_type, price_cents, status, error_message, created_at, updated_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .order('id', { ascending: false })
    .range((currentPage - 1) * size, currentPage * size - 1);
  if (error) throw new HttpError(500, '报告列表读取失败');
  return (data || []).map(mapAiReportOrder);
}

module.exports = {
  cancelRechargeOrderForUser,
  createAiReportDebit,
  createQueuedAiReportDebit,
  completeAiReport,
  createRechargeOrder,
  grantRegistrationBonusIfEligible,
  getAiReportForUser,
  getRechargeOrderForUser,
  getWallet,
  isInvalidAiReportText,
  listAiReportsForUser,
  reconcileEmptyAiReportsForUser,
  insertPaymentNotifyLog,
  listWalletTransactions,
  markPaymentNotifyLog,
  markRechargePaid,
  refundAiReport,
  updateRechargeOrderPayment,
};

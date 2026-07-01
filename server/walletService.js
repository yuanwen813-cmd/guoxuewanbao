const crypto = require('crypto');
const { getSupabaseServiceClient } = require('./supabaseClient');
const { HttpError } = require('./response');

function mapWallet(row) {
  if (!row) return null;
  return {
    balanceCents: Number(row.balance_cents || 0),
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
    currency: row.currency || 'CNY',
    refType: row.ref_type,
    refId: row.ref_id,
    outTradeNo: row.out_trade_no,
    note: row.note,
    createdAt: row.created_at,
  };
}

function mapRechargeOrder(row) {
  return {
    id: row.id,
    outTradeNo: row.out_trade_no,
    provider: row.provider,
    tradeType: row.trade_type,
    amountCents: Number(row.amount_cents || 0),
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
    currency: row.currency || 'CNY',
    status: row.status,
    resultText: row.result_text,
    errorMessage: row.error_message,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

function newOutTradeNo(provider) {
  const prefix = provider === 'alipay' ? 'ALI' : 'WX';
  const stamp = new Date().toISOString().replace(/[-:.TZ]/g, '').slice(0, 14);
  const random = crypto.randomBytes(5).toString('hex').toUpperCase();
  return `${prefix}${stamp}${random}`;
}

async function getWallet(userId) {
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase
    .from('wallets')
    .select('*')
    .eq('user_id', userId)
    .single();
  if (error) throw new HttpError(500, '钱包读取失败', error.message);
  return mapWallet(data);
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
      headers_json: headersJson || {},
      raw_body: rawBody || '',
      parsed_json: parsedJson || {},
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
}) {
  const supabase = getSupabaseServiceClient();
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
}) {
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase.rpc('create_ai_report_debit', {
    p_user_id: userId,
    p_product_id: product.id,
    p_report_type: product.reportType,
    p_price_cents: product.priceCents,
    p_input_snapshot_json: inputSnapshotJson || {},
    p_bazi_chart_json: baziChartJson || {},
    p_question_result_json: questionResultJson || {},
    p_prompt_snapshot: promptSnapshot || '',
  });
  if (error) {
    const message = String(error.message || '');
    if (message.includes('INSUFFICIENT_BALANCE')) {
      throw new HttpError(402, '余额不足，请先充值后再生成');
    }
    throw new HttpError(500, 'AI 扣费订单创建失败', error.message);
  }
  return {
    order: mapAiReportOrder(data.order),
    wallet: mapWallet(data.wallet),
  };
}

async function completeAiReport({ orderId, resultText, model, usage }) {
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase.rpc('complete_ai_report_order', {
    p_order_id: orderId,
    p_result_text: resultText || '',
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

async function refundAiReport({ orderId, errorMessage, model }) {
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase.rpc('refund_ai_report_order', {
    p_order_id: orderId,
    p_error_message: errorMessage || 'AI 调用失败，已自动退款',
    p_model: model || null,
  });
  if (error) throw new HttpError(500, 'AI 失败退款处理失败', error.message);
  return {
    order: mapAiReportOrder(data.order),
    wallet: mapWallet(data.wallet),
    alreadyRefunded: Boolean(data.already_refunded),
  };
}

async function getAiReportForUser({ userId, orderId }) {
  const supabase = getSupabaseServiceClient();
  const { data, error } = await supabase
    .from('ai_report_orders')
    .select('*')
    .eq('user_id', userId)
    .eq('id', orderId)
    .single();
  if (error) throw new HttpError(404, '报告不存在');
  return mapAiReportOrder(data);
}

module.exports = {
  createAiReportDebit,
  completeAiReport,
  createRechargeOrder,
  getAiReportForUser,
  getRechargeOrderForUser,
  getWallet,
  insertPaymentNotifyLog,
  listWalletTransactions,
  markPaymentNotifyLog,
  markRechargePaid,
  refundAiReport,
  updateRechargeOrderPayment,
};

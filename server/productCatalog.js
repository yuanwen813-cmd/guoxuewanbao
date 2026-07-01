const aiProducts = {
  question_brief_1: {
    id: 'question_brief_1',
    reportType: 'question_brief',
    priceCents: 100,
    model: 'deepseek-v4-flash',
    maxTokens: 1800,
    enabled: true,
  },
  question_full_3_9: {
    id: 'question_full_3_9',
    reportType: 'question_full',
    priceCents: 390,
    model: 'deepseek-v4-pro',
    maxTokens: 6000,
    enabled: true,
  },
  bazi_brief_1: {
    id: 'bazi_brief_1',
    reportType: 'bazi_brief',
    priceCents: 100,
    model: 'deepseek-v4-flash',
    maxTokens: 3200,
    enabled: true,
  },
  bazi_basic_3_9: {
    id: 'bazi_basic_3_9',
    reportType: 'bazi_basic',
    priceCents: 390,
    model: 'deepseek-v4-pro',
    maxTokens: 6000,
    enabled: true,
  },
  bazi_deep_6_9: {
    id: 'bazi_deep_6_9',
    reportType: 'bazi_deep',
    priceCents: 690,
    model: 'deepseek-v4-pro',
    maxTokens: 8192,
    enabled: true,
  },
  bazi_custom_13_9: {
    id: 'bazi_custom_13_9',
    reportType: 'bazi_custom',
    priceCents: 1390,
    model: 'deepseek-v4-pro',
    maxTokens: 8192,
    enabled: true,
  },
  ziwei_reserved: {
    id: 'ziwei_reserved',
    reportType: 'ziwei_reserved',
    priceCents: 0,
    model: 'deepseek-v4-pro',
    maxTokens: 0,
    enabled: false,
    disabledReason: '紫微斗数排盘结构尚未完成，第一版仅预留产品位。',
  },
  tieban_reserved: {
    id: 'tieban_reserved',
    reportType: 'tieban_reserved',
    priceCents: 0,
    model: 'deepseek-v4-pro',
    maxTokens: 0,
    enabled: false,
    disabledReason: '铁板神数结构尚未完成，第一版仅预留产品位。',
  },
  daily_hexagram_brief: {
    id: 'daily_hexagram_brief',
    reportType: 'daily_brief',
    priceCents: 100,
    model: 'deepseek-v4-flash',
    maxTokens: 1800,
    enabled: true,
  },
};

const aliases = {
  coin_hexagram_question_brief: 'question_brief_1',
  coin_hexagram_question_full: 'question_full_3_9',
  xiaoliuren_question_brief: 'question_brief_1',
  xiaoliuren_question_full: 'question_full_3_9',
  meihua_yishu_question_brief: 'question_brief_1',
  meihua_yishu_question_full: 'question_full_3_9',
  gaodao_yiduan_question_brief: 'question_brief_1',
  gaodao_yiduan_question_full: 'question_full_3_9',
  bazi_brief: 'bazi_brief_1',
  bazi_basic: 'bazi_basic_3_9',
  bazi_deep: 'bazi_deep_6_9',
};

function getAiProduct(productId) {
  const canonicalId = aliases[productId] || productId;
  const product = aiProducts[canonicalId];
  if (!product) return null;
  return { ...product, requestedProductId: productId, id: canonicalId };
}

const fixedRechargeAmounts = new Set([100, 390, 690, 1390]);

function validateRechargeAmount(amountCents) {
  const value = Number(amountCents);
  if (!Number.isInteger(value)) {
    return { ok: false, message: '充值金额必须使用整数分' };
  }
  if (fixedRechargeAmounts.has(value)) return { ok: true, amountCents: value };
  if (value >= 100 && value <= 99900) return { ok: true, amountCents: value };
  return { ok: false, message: '自定义充值金额必须在 1 元至 999 元之间' };
}

module.exports = {
  getAiProduct,
  validateRechargeAmount,
};

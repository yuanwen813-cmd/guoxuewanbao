const { getDoubaoModelId } = require('./doubaoClient');

const AI_REPORT_PRICE_CENTS = 500;

const aiProducts = {
  question_brief_1: {
    id: 'question_brief_1',
    reportType: 'question_brief',
    maxTokens: 1800,
    enabled: true,
  },
  question_full_3_9: {
    id: 'question_full_3_9',
    reportType: 'question_full',
    maxTokens: 6000,
    enabled: true,
  },
  bazi_brief_1: {
    id: 'bazi_brief_1',
    reportType: 'bazi_brief',
    maxTokens: 3200,
    enabled: true,
  },
  bazi_basic_3_9: {
    id: 'bazi_basic_3_9',
    reportType: 'bazi_basic',
    maxTokens: 6000,
    enabled: true,
  },
  bazi_deep_6_9: {
    id: 'bazi_deep_6_9',
    reportType: 'bazi_deep',
    maxTokens: 12000,
    enabled: true,
  },
  ziwei_brief: {
    id: 'ziwei_brief',
    reportType: 'ziwei_brief',
    maxTokens: 3200,
    enabled: true,
  },
  ziwei_basic: {
    id: 'ziwei_basic',
    reportType: 'ziwei_basic',
    maxTokens: 6000,
    enabled: true,
  },
  ziwei_deep: {
    id: 'ziwei_deep',
    reportType: 'ziwei_deep',
    maxTokens: 10000,
    enabled: true,
  },
  tieban_basic: {
    id: 'tieban_basic',
    reportType: 'tieban_basic',
    maxTokens: 6000,
    enabled: true,
  },
  tieban_deep: {
    id: 'tieban_deep',
    reportType: 'tieban_deep',
    maxTokens: 10000,
    enabled: true,
  },
  daily_hexagram_brief: {
    id: 'daily_hexagram_brief',
    reportType: 'daily_brief',
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
  return {
    ...product,
    requestedProductId: productId,
    id: canonicalId,
    priceCents: AI_REPORT_PRICE_CENTS,
    model: getDoubaoModelId(),
  };
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
  AI_REPORT_PRICE_CENTS,
  getAiProduct,
  validateRechargeAmount,
};

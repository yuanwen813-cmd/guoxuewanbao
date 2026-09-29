const { HttpError } = require('./response');

// Conservative delivery check, not a truth/medical assessment. A disclaimer,
// short answer, or a negative interpretation alone is never a refund reason.
const refusal = /(?:不能|无法|不便|不予|不会|不提供|不支持|拒绝|不适合)[^。！？!?\n；;，,]{0,32}(?:解读卦象|解析卦象|解卦|断卦|卦象解读|卦象解析|占卜解读|占卜分析|进行占卜|提供占卜|命理解读|命理解析|命盘解读|命盘解析|解读命盘|分析命盘|算命|批命)|(?:can(?:not|'t)|unable to|won't)[^.!?\n]{0,60}(?:interpret (?:the |your )?(?:hexagram|chart)|provide (?:a )?(?:divination|fortune.telling))/iu;
const boundaryNegation = /(?:并非|不是|并不是|不代表|不意味着|不等于)[^。！？!?\n]{0,10}$/u;
const basis = /本卦|变卦|互卦|动爻|爻辞|卦辞|[初上][六九]|[六九][二三四五]|[乾坤泰临损益渐巽兑坎离震艮][卦宫]|中孚|日主|命宫|身宫|十神|四柱|大运|流年|五行|六亲|四化|数序|落宫|大安|速喜|赤口|留连|空亡|小吉|紫微|天机|天府|太阴|武曲|破军|廉贞|七杀|伤官|财星|官星|比劫|用神|世爻|应爻|官鬼|月建|日辰/u;
const explanation = /提示|象征|意味着|反映|强调|代表|对应|倾向|寓意|体现|主张|有利|不利|宜|忌|旺|弱|生克|相生|相克|化禄|化忌|吉|凶/u;
const disclaimer = /封建迷信|没有科学依据|缺乏科学依据|不能.{0,8}(?:预测|预判|判断)|无法.{0,8}(?:预测|预判|判断)|仅供.{0,8}参考/u;

function assessAiReport(value) {
  const answer = typeof value === 'string' ? value.trim() : '';
  if (!answer) return { accepted: false, reason: 'empty' };
  const normalized = answer.normalize('NFKC').replace(/[*_`#]/g, '');
  const sentences = normalized.split(/[。！？!?\n；;]/u).filter(Boolean);
  let explicitRefusal = false;
  let substantive = false;
  for (const sentence of sentences) {
    const match = refusal.exec(sentence);
    const quoted = /[“「『"]/.test(sentence.slice(0, match?.index ?? 0))
      && /[”」』"]/.test(sentence.slice((match?.index ?? 0) + (match?.[0].length ?? 0)));
    const refused = match && !quoted && !boundaryNegation.test(sentence.slice(0, match.index));
    if (refused) explicitRefusal = true;
    const analysis = sentence.split(/[，,]/u)
      .filter((clause) => !refusal.test(clause) && !disclaimer.test(clause)).join('，');
    if (basis.test(analysis) && explanation.test(analysis)) {
      substantive = true;
    }
  }
  return explicitRefusal && !substantive
    ? { accepted: false, reason: 'refusal_only' }
    : { accepted: true, reason: explicitRefusal ? 'mixed_content' : 'content' };
}

function ensureDeliveredAiReport(value) {
  const result = assessAiReport(value);
  if (!result.accepted) {
    throw new HttpError(424, result.reason === 'empty'
      ? 'AI 服务未返回有效内容'
      : 'AI 未提供实质解析，本次解析未完成', { deliveryReason: result.reason });
  }
  return value.trim();
}

module.exports = { assessAiReport, ensureDeliveredAiReport };

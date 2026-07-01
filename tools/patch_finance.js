const fs = require('fs');
const f = 'lib/features/divination/takashima/takashima_page.dart';
let c = fs.readFileSync(f, 'utf8');

const startMarker = 'static const _financialBannedTerms = [';
const endMarker = 'bool _isFinancialQuestion';

const start = c.indexOf(startMarker);
const end = c.indexOf(endMarker, start);
if (start < 0 || end <= start) { console.log('Markers not found'); process.exit(1); }

const replacement = `// 金融风险句模式
  static final _financialRiskSentencePatterns = [
    RegExp(r'(建议|可以|应该|适合|考虑|准备|计划)\\s*(买入|卖出|持有|加仓|减仓|建仓|清仓|补仓|止盈|止损|入场|出场|做多|做空|追涨|杀跌)'),
    RegExp(r'(继续持有|分批介入|逢低|布局|轻仓|重仓|满仓|半仓|目标价|收益率|止盈点|止损点)'),
    RegExp(r'[金价|行情|走势|价格].{0,10}(会上涨|会下跌|先扬后抑|先抑后扬|冲高|回落|突破|下行|上涨|下跌|震荡|反弹)'),
    RegExp(r'(不会大涨|不会大跌|大幅上涨|大幅下跌|短期突破|方向性突破|震荡整理|短期波动)'),
    RegExp(r'(未来|后续|下[个周月]|本周|本月|下月).{0,10}(走势|行情|涨跌|价格|趋势|波动|变化)'),
    RegExp(r'(把握.{0,5}(机会|行情|时机)|操作.{0,5}(建议|策略|计划))'),
  ];
  static const _safeDisclaimerPatterns = [
    '不构成投资建议','不构成行情预测','不构成真实行情预测','不构成买卖指令','不构成持仓建议','不构成收益承诺',
    '请结合实时市场数据','请咨询具备资质的专业人士','仅供传统文化','仅从卦象象意','不构成真实行情',
  ];
  bool _isSafeDisclaimer(String text) => _safeDisclaimerPatterns.any((p) => text.contains(p));
  List<String> _splitSentences(String text) {
    return text.split(RegExp(r'(?<=[。；\\n])')).where((s) => s.trim().isNotEmpty).toList();
  }
  bool _isFinancialRiskSentence(String sentence) {
    if (_isSafeDisclaimer(sentence)) return false;
    return _financialRiskSentencePatterns.any((p) => p.hasMatch(sentence));
  }
  static const _sentenceSafeText = '涉及真实价格走势或交易操作的判断，不应仅凭卦象作出。此处仅可理解为提醒保持风险意识、节制心态和谨慎判断。';
  void _sanitizeFinancialContent(Map<String, dynamic> json) {
    final riskTerms = <String>[];
    for (final key in json.keys.toList()) {
      if (json[key] is String) {
        final original = json[key] as String;
        if (_isSafeDisclaimer(original)) continue;
        final sentences = _splitSentences(original);
        bool changed = false;
        for (int i = 0; i < sentences.length; i++) {
          if (_isFinancialRiskSentence(sentences[i])) {
            riskTerms.add(key + ': ' + sentences[i].trim().substring(0, 80));
            sentences[i] = _sentenceSafeText;
            changed = true;
          }
        }
        if (changed) {
          final rewritten = sentences.join();
          _postProcessSteps.add({'name':'financial_safety_rewrite','field':key,'reason':'financial risk sentence detected','before':original,'after':rewritten});
          json[key] = rewritten;
        }
      }
    }
    _financialRiskTermsDetected = riskTerms.isNotEmpty ? riskTerms : [];
  }

  `;
c = c.substring(0, start) + replacement + c.substring(end);
fs.writeFileSync(f, c);
console.log('Patched OK');

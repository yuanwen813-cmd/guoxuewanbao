import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/guoxue_colors.dart';
import '../../../app/theme/guoxue_decoration.dart';
import '../../../app/theme/guoxue_typography.dart';
import '../../../domain/iching/takashima_cast_engine.dart';
import '../../../domain/iching/takashima_models.dart';
import '../../../domain/iching/iching_repository.dart';
import '../../../domain/common/common_result_models.dart';
import '../../../domain/history/divination_history.dart';
import '../../../domain/unified/unified_models.dart';
import '../../../features/result_common/common_divination_result_page.dart';
import '../../../infrastructure/ai/deepseek_client_factory.dart';
import '../../../infrastructure/history_service/history_service.dart';
import '../../../shared/disclaimer/disclaimer_block.dart';
import '../../../shared/widgets/classical_card.dart';
import '../../../shared/widgets/guoxue_button.dart';

class TakashimaPage extends ConsumerStatefulWidget {
  const TakashimaPage({super.key});
  @override
  ConsumerState<TakashimaPage> createState() => _TakashimaPageState();
}

class _TakashimaPageState extends ConsumerState<TakashimaPage> {
  final _hexRepo = HexagramRepository();
  final _yaoRepo = YaoRepository();
  late final TakashimaSegmentCastEngine _engine =
      TakashimaSegmentCastEngine(hexRepo: _hexRepo, yaoRepo: _yaoRepo);
  final _questionController = TextEditingController();
  int _gender = 0;
  bool _reposReady = false;
  List<TakashimaSegmentShakeResult> _shakes = [];
  bool _shaking = false;
  int _leftCount = 0, _rightCount = 0;
  TakashimaCastResult? _castResult;
  GuoxueResult? _result;
  bool _interpreting = false;

  final List<Map<String, dynamic>> _aiAttempts = [];
  int _acceptedAttempt = 0;
  bool _aiFailedAfterRetry = false;
  Map<String, dynamic>? _acceptedResult;
  Map<String, dynamic>? _finalResult;
  Map<String, dynamic>? _rawTextParsed;
  String? _aiSystemPrompt;
  String? _aiUserPrompt;
  bool _timingPostProcessed = false;
  String? _timingBefore;
  bool _financialSafetyPostProcessed = false;
  List<String>? _financialRiskTermsDetected;
  final List<Map<String, String>> _postProcessSteps = [];
  static const _aiTemperature = 0.3;

  static const _safeTiming = '时机判断：宜先稳后动，适合在信息更明确、风险更可控后再处理；不宜仅凭卦象作出财务或投资决策。';
  static const _financialDisclaimer =
      '当前问题涉及金融或投资相关内容。本解读仅从传统文化和卦象象意角度提供参考，不构成投资建议、行情预测、买卖指令或收益承诺。真实投资请结合实时市场数据、个人风险承受能力，并咨询具备资质的专业人士。';
  static const _sentenceSafeText =
      '涉及真实价格走势或交易操作的判断，不应仅凭卦象作出。此处仅可理解为提醒保持风险意识、节制心态和谨慎判断。';
  static const _financialKeywords = [
    '金价',
    '黄金',
    '股票',
    '基金',
    '币价',
    '虚拟币',
    '比特币',
    '以太坊',
    '投资',
    '理财',
    '期货',
    '外汇',
    '买入',
    '卖出',
    '加仓',
    '减仓',
    '仓位',
    '走势',
    '行情',
    '目标价',
    '收益率',
    '回调'
  ];

  // 金融风险句模式
  static final _financialRiskSentencePatterns = [
    RegExp(
        r'(建议|可以|应该|适合|考虑|准备|计划)\s*(买入|卖出|持有|加仓|减仓|建仓|清仓|补仓|止盈|止损|入场|出场|做多|做空|追涨|杀跌)'),
    RegExp(r'(继续持有|分批介入|逢低|布局|轻仓|重仓|满仓|半仓|目标价|收益率|止盈点|止损点)'),
    RegExp(r'[金价|行情|走势|价格].{0,10}(会上涨|会下跌|先扬后抑|先抑后扬|冲高|回落|突破|下行|上涨|下跌|震荡|反弹)'),
    RegExp(r'(不会大涨|不会大跌|大幅上涨|大幅下跌|短期突破|方向性突破|震荡整理|短期波动)'),
    RegExp(r'(未来|后续|下[个周月]|本周|本月|下月).{0,10}(走势|行情|涨跌|价格|趋势|波动|变化)'),
    RegExp(r'(把握.{0,5}(机会|行情|时机)|操作.{0,5}(建议|策略|计划))'),
  ];
  static const _safeDisclaimerPatterns = [
    '不构成投资建议',
    '不构成行情预测',
    '不构成真实行情预测',
    '不构成买卖指令',
    '不构成持仓建议',
    '不构成收益承诺',
    '请结合实时市场数据',
    '请咨询具备资质的专业人士',
    '仅供传统文化',
    '仅从卦象象意',
    '不构成真实行情',
  ];

  bool _isFinancialQuestion(String q) =>
      _financialKeywords.any((kw) => q.contains(kw));
  bool _isSafeDisclaimer(String text) =>
      _safeDisclaimerPatterns.any((p) => text.contains(p));
  bool _hasInvalidTiming(String? t) {
    if (t == null || t.isEmpty) return false;
    if (RegExp(r'[子丑寅卯辰巳午未申酉戌亥]时').hasMatch(t)) return true;
    if (RegExp(r'上午|下午|傍晚|晚上|凌晨').hasMatch(t)) return true;
    if (RegExp(r'\d+日后|几日后|数日后|三日后').hasMatch(t)) return true;
    if (RegExp(r'\d+周[前后内]|几周|数周').hasMatch(t)) return true;
    if (RegExp(r'\d+个?月[后内]|几个月|数个?月').hasMatch(t)) return true;
    if (RegExp(r'\d+[-~至]\d+\s*[日天周月年]').hasMatch(t)) return true;
    if (RegExp(r'今日.{0,5}[后议决断]').hasMatch(t)) return true;
    return false;
  }

  bool _hasCorruption(String? t) =>
      t != null && (t.contains('�') || t.contains('��') || t.contains('���'));
  bool _hasCorruptionInJson(Map<String, dynamic>? j) {
    if (j == null) return false;
    for (final v in j.values) {
      if (v is String && _hasCorruption(v)) return true;
    }
    return false;
  }

  List<Map<String, String>> _findCorruptionFields(Map<String, dynamic>? j,
      [String p = '']) {
    final r = <Map<String, String>>[];
    if (j == null) return r;
    for (final e in j.entries) {
      final path = p.isEmpty ? e.key : '$p.${e.key}';
      if (e.value is String && _hasCorruption(e.value as String))
        r.add({'path': path, 'value': e.value as String});
    }
    return r;
  }

  bool _deepCompareMaps(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k)) return false;
      if (a[k].toString() != b[k].toString()) return false;
    }
    return true;
  }

  bool _isPlaceholder(String s) {
    const p = [
      '未收录',
      '参见',
      '原文',
      '请查阅',
      '请结合',
      '综合理解',
      '待补',
      '缺失',
      'TODO',
      '暂缺',
      '未录',
      '自动生成',
      '占位',
      'placeholder'
    ];
    return p.any((x) => s.contains(x));
  }

  bool _dataCompleteForAI(TakashimaCastResult cr) {
    final t = cr.movingYao.text ?? '', m = cr.movingYao.meaning ?? '';
    return cr.primaryHexagram.judgment.isNotEmpty &&
        !_isPlaceholder(cr.primaryHexagram.judgment) &&
        (cr.primaryHexagram.image ?? '').isNotEmpty &&
        !_isPlaceholder(cr.primaryHexagram.image ?? '') &&
        t.isNotEmpty &&
        !_isPlaceholder(t) &&
        m.isNotEmpty &&
        !_isPlaceholder(m) &&
        cr.changedHexagram.judgment.isNotEmpty &&
        !_isPlaceholder(cr.changedHexagram.judgment);
  }

  bool _hasPostProcess() =>
      _timingPostProcessed || _financialSafetyPostProcessed;

  List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'(?<=[。；\n])'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  bool _isFinancialRiskSentence(String s) {
    if (_isSafeDisclaimer(s)) return false;
    return _financialRiskSentencePatterns.any((p) => p.hasMatch(s));
  }

  void _sanitizeFinancialContent(Map<String, dynamic> json) {
    final riskTerms = <String>[];
    for (final key in json.keys.toList()) {
      if (json[key] is String) {
        final orig = json[key] as String;
        if (_isSafeDisclaimer(orig)) continue;
        final sentences = _splitSentences(orig);
        bool changed = false;
        for (int i = 0; i < sentences.length; i++) {
          if (_isFinancialRiskSentence(sentences[i])) {
            riskTerms.add('$key: "${sentences[i].trim()}"');
            sentences[i] = _sentenceSafeText;
            changed = true;
          }
        }
        if (changed) {
          final rewritten = sentences.join();
          _postProcessSteps.add({
            'name': 'financial_safety_rewrite',
            'field': key,
            'reason': 'financial risk sentence detected',
            'before': orig,
            'after': rewritten
          });
          json[key] = rewritten;
        }
      }
    }
    _financialRiskTermsDetected = riskTerms.isNotEmpty ? riskTerms : [];
  }

  @override
  void initState() {
    super.initState();
    _initRepos();
  }

  Future<void> _initRepos() async {
    await _hexRepo.init();
    await _yaoRepo.init();
    if (mounted) setState(() => _reposReady = true);
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _doShake() {
    if (_shakes.length >= 3 || _shaking) return;
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先填写所问之事')));
      return;
    }
    final idx = _shakes.length + 1;
    setState(() => _shaking = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final shake = _engine.generateShake(shakeIndex: idx, gender: _gender);
      setState(() {
        _shakes = [..._shakes, shake];
        _leftCount = shake.leftCount;
        _rightCount = shake.rightCount;
        _shaking = false;
      });
    });
  }

  void _finishCast() {
    final q = _questionController.text.trim();
    _castResult =
        _engine.buildResult(question: q, gender: _gender, shakes: _shakes);
    _result = _buildLocalResult(_castResult!);
    setState(() {});
  }

  void _reset() {
    setState(() {
      _shakes = [];
      _leftCount = 0;
      _rightCount = 0;
      _castResult = null;
      _result = null;
      _aiSystemPrompt = null;
      _aiUserPrompt = null;
      _acceptedResult = null;
      _finalResult = null;
      _rawTextParsed = null;
      _aiAttempts.clear();
      _acceptedAttempt = 0;
      _aiFailedAfterRetry = false;
      _postProcessSteps.clear();
    });
  }

  GuoxueResult _buildLocalResult(TakashimaCastResult cr) {
    final p = cr.primaryHexagram, c = cr.changedHexagram, my = cr.movingYao;
    final sections = <ResultSection>[
      ResultSection(
          title: '起卦方式',
          type: ResultSectionType.text,
          text: '49线段分策法（${cr.gender == 0 ? "男" : "女"}）'),
      ResultSection(
          title: '所问之事',
          type: ResultSectionType.text,
          text: cr.question.isNotEmpty ? cr.question : '（未填写）'),
      ...cr.shakes.map((s) {
        final pl = s.purpose == 'upper_trigram'
            ? '得上卦'
            : s.purpose == 'lower_trigram'
                ? '得下卦'
                : '得动爻';
        return ResultSection(
            title: '第${s.shakeIndex}次摇动（$pl）',
            type: ResultSectionType.kvTable,
            kvPairs: [
              MapEntry('左边', '${s.leftCount}根'),
              MapEntry('右边', '${s.rightCount}根'),
              MapEntry('取${s.selectedSide}边', '${s.selectedCount}'),
              MapEntry('÷${s.divisor}余数', '${s.remainder}'),
              MapEntry('结果', '→${s.mappedValue}')
            ]);
      }),
      ResultSection(
          title: '上卦',
          type: ResultSectionType.text,
          text:
              '${cr.upperTrigram.name}卦（${cr.upperTrigram.element}）${cr.upperTrigram.symbol}'),
      ResultSection(
          title: '下卦',
          type: ResultSectionType.text,
          text:
              '${cr.lowerTrigram.name}卦（${cr.lowerTrigram.element}）${cr.lowerTrigram.symbol}'),
      ResultSection(
          title: '本卦',
          type: ResultSectionType.text,
          text: '第${p.index}卦 ${p.name} ${p.symbol}'),
      ResultSection(
          title: '本卦卦辞', type: ResultSectionType.text, text: p.judgment),
      if (p.image != null && p.image!.isNotEmpty)
        ResultSection(
            title: '本卦象曰', type: ResultSectionType.text, text: p.image!),
      ResultSection(
          title: '动爻',
          type: ResultSectionType.text,
          text: '第${cr.movingLine}爻 ${my.lineName} ${my.symbol}'),
      ResultSection(
          title: '动爻爻辞', type: ResultSectionType.text, text: my.text ?? ''),
      if (my.meaning != null && my.meaning!.isNotEmpty)
        ResultSection(
            title: '动爻解释', type: ResultSectionType.text, text: my.meaning!),
      ResultSection(
          title: '变卦',
          type: ResultSectionType.text,
          text: '第${c.index}卦 ${c.name} ${c.symbol}'),
      ResultSection(
          title: '变卦卦辞', type: ResultSectionType.text, text: c.judgment),
      ResultSection(
          title: '解读权重',
          type: ResultSectionType.tags,
          tags: ['动爻51%主断', '本卦30%辅断', '变卦19%趋势']),
    ];
    return GuoxueResult(
        featureId: 'takashima',
        featureTitle: '高岛易断',
        categoryId: 'divination',
        createdAt: DateTime.now(),
        sections: sections,
        rawData: cr.toJson());
  }

  Future<void> _aiInterpret() async {
    if (_result == null || _castResult == null) return;
    if (!_dataCompleteForAI(_castResult!)) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('当前卦爻数据不完整')));
      return;
    }
    setState(() => _interpreting = true);
    _aiAttempts.clear();
    _acceptedAttempt = 0;
    _aiFailedAfterRetry = false;
    try {
      final client = await createDeepSeekClient();
      final (sp, up) = _buildPrompts(_castResult!);
      _aiSystemPrompt = sp;
      _aiUserPrompt = up;
      final raw1 = await client.chat(
          systemPrompt: sp,
          userPrompt: up,
          temperature: _aiTemperature,
          maxTokens: 3000);
      final (p1, ok1) = _tryParse(raw1);
      final c1 = _hasCorruption(raw1) || _hasCorruptionInJson(p1);
      _aiAttempts.add(_mkAttempt(1, raw1, ok1, p1, c1, !c1 && ok1));
      if (!c1 && ok1) {
        _acceptAttempt(1, p1!);
        return;
      }
      final raw2 = await client.chat(
          systemPrompt: sp,
          userPrompt: up,
          temperature: _aiTemperature,
          maxTokens: 3000);
      final (p2, ok2) = _tryParse(raw2);
      final c2 = _hasCorruption(raw2) || _hasCorruptionInJson(p2);
      _aiAttempts.add(_mkAttempt(2, raw2, ok2, p2, c2, !c2 && ok2));
      if (!c2 && ok2) {
        _acceptAttempt(2, p2!);
        return;
      }
      _aiFailedAfterRetry = true;
      if (mounted)
        setState(() {
          _result = _result!.withAi(AiInterpretation.fallback());
          _interpreting = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _result = _result!.withAi(AiInterpretation.fallback());
          _interpreting = false;
        });
    }
  }

  void _acceptAttempt(int n, Map<String, dynamic> parsed) {
    _acceptedAttempt = n;
    _rawTextParsed = parsed;
    _acceptedResult = Map<String, dynamic>.from(parsed);
    _finalResult = Map<String, dynamic>.from(parsed);
    _applyPostProcess(_finalResult!, _castResult!.question);
    final ai = _buildAiFromParsed(_finalResult!);
    if (mounted)
      setState(() {
        _result = _result!.withAi(ai);
        _interpreting = false;
      });
  }

  Map<String, dynamic> _mkAttempt(int n, String raw, bool ok,
          Map<String, dynamic>? p, bool corr, bool acc) =>
      {
        'attempt': n,
        'rawText': raw,
        'parseSuccess': ok,
        'parsedJson': p,
        'decodeCorruptionDetected': corr,
        'decodeCorruptionFields': _findCorruptionFields(p),
        'accepted': acc,
        'rejectReason': acc
            ? null
            : (corr ? 'decode_corruption' : (ok ? null : 'parse_failure'))
      };
  (Map<String, dynamic>?, bool) _tryParse(String raw) {
    try {
      String s = raw.trim();
      if (s.startsWith('```')) {
        final e = s.lastIndexOf('```');
        if (e > 3) s = s.substring(3, e).trim();
        final nl = s.indexOf('\n');
        if (nl > 0 && nl < 20) s = s.substring(nl + 1).trim();
      }
      return (json.decode(s) as Map<String, dynamic>, true);
    } catch (_) {
      return (null, false);
    }
  }

  void _applyPostProcess(Map<String, dynamic> m, String question) {
    _timingPostProcessed = false;
    _timingBefore = null;
    _financialSafetyPostProcessed = false;
    _financialRiskTermsDetected = null;
    _postProcessSteps.clear();
    _timingBefore = m['timing'] as String?;
    if (_hasInvalidTiming(_timingBefore)) {
      _timingPostProcessed = true;
      final b = m['timing'] as String;
      m['timing'] = _safeTiming;
      _postProcessSteps.add({
        'name': 'timing_safety_rewrite',
        'field': 'timing',
        'reason': 'timing contained invented specific time expression',
        'before': b,
        'after': _safeTiming
      });
    }
    if (_isFinancialQuestion(question)) {
      _sanitizeFinancialContent(m);
      _financialSafetyPostProcessed =
          _postProcessSteps.any((s) => s['name'] == 'financial_safety_rewrite');
    }
  }

  AiInterpretation _buildAiFromParsed(Map<String, dynamic> m) {
    final parts = <String>[];
    if (m['xiangDuan'] != null && (m['xiangDuan'] as String).isNotEmpty)
      parts.add('【象断】${m['xiangDuan']}');
    if (m['movingYaoAnalysis'] != null &&
        (m['movingYaoAnalysis'] as String).isNotEmpty)
      parts.add('【动爻主断·51%】${m['movingYaoAnalysis']}');
    if (m['primaryHexagramAnalysis'] != null &&
        (m['primaryHexagramAnalysis'] as String).isNotEmpty)
      parts.add('【本卦辅断·30%】${m['primaryHexagramAnalysis']}');
    if (m['changedHexagramAnalysis'] != null &&
        (m['changedHexagramAnalysis'] as String).isNotEmpty)
      parts.add('【变卦趋势·19%】${m['changedHexagramAnalysis']}');
    if (m['conflictResolution'] != null &&
        (m['conflictResolution'] as String).isNotEmpty)
      parts.add('【矛盾取舍】${m['conflictResolution']}');
    final vParts = <String>[];
    if (m['vernacular'] != null && (m['vernacular'] as String).isNotEmpty)
      vParts.add(m['vernacular'] as String);
    final aParts = <String>[];
    if (m['timing'] != null && (m['timing'] as String).isNotEmpty)
      aParts.add(m['timing'] as String);
    if (m['advice'] != null && (m['advice'] as String).isNotEmpty)
      aParts.add(m['advice'] as String);
    if (m['riskNote'] != null && (m['riskNote'] as String).isNotEmpty)
      aParts.add(m['riskNote'] as String);
    if (m['finalVerdict'] != null && (m['finalVerdict'] as String).isNotEmpty)
      aParts.add(m['finalVerdict'] as String);
    return AiInterpretation(
        classical: parts.isNotEmpty
            ? parts.join('\n\n')
            : (m['classical'] as String? ?? ''),
        vernacular: vParts.isNotEmpty ? vParts.join('\n\n') : '',
        advice: aParts.isNotEmpty ? aParts.join('\n\n') : '',
        tags: (m['tags'] as List?)?.cast<String>() ?? [],
        generatedAt: DateTime.now());
  }

  (String, String) _buildPrompts(TakashimaCastResult cr) {
    final p = cr.primaryHexagram,
        c = cr.changedHexagram,
        my = cr.movingYao,
        g = cr.gender == 0 ? '男' : '女';
    final sp = '你是精通周易象数占断的传统文化解读师。只能根据提供的起卦结果解释，不得重新起卦修改卦象编造卦辞爻辞。'
        '解读三层定位：1.动爻爻辞51%主断定成败祸福；2.本卦30%辅断当前局面；3.变卦19%趋势参考。若动爻与变卦矛盾以动爻为准。'
        '先象断再释处境再动爻关键判断再本卦环境再变卦趋势再趋避建议。禁止绝对化表达、编造具体时辰日期金额方位、自行补写缺失爻辞。'
        '${_isFinancialQuestion(cr.question) ? "【金融安全】只从卦象象意泛化解读不得输出投资建议行情预测买卖指令或收益承诺。不得使用买入卖出持有加仓减仓等表达。说明不构成投资建议。" : ""}'
        '本内容仅供传统文化研究和娱乐参考。';
    final up =
        '用户所问：${cr.question.isNotEmpty ? cr.question : "（未填写）"}\n用户性别：$g\n起卦方式：49线段分策法\n'
        '三次摇动：${cr.shakes.map((s) => "第${s.shakeIndex}次：左${s.leftCount}右${s.rightCount}取${s.selectedSide}边${s.selectedCount}÷${s.divisor}余${s.remainder}→${s.mappedValue}").join("\n")}\n'
        '上卦：${cr.upperTrigram.name}卦（${cr.upperTrigram.element}）\n下卦：${cr.lowerTrigram.name}卦（${cr.lowerTrigram.element}）\n'
        '本卦：${p.name}${p.symbol}\n卦辞：${p.judgment}\n象曰：${p.image ?? ""}\n含义：${p.meaning ?? ""}\n'
        '动爻：第${cr.movingLine}爻${my.lineName}${my.symbol}\n爻辞：${my.text ?? ""}\n含义：${my.meaning ?? ""}\n'
        '变卦：${c.name}${c.symbol}\n卦辞：${c.judgment}\n象曰：${c.image ?? ""}\n含义：${c.meaning ?? ""}\n'
        '权重：动爻51%主断、本卦30%辅一、变卦19%辅二。以动爻为准。\n'
        '返回JSON：{"xiangDuan":"象断","movingYaoAnalysis":"动爻主断51%","primaryHexagramAnalysis":"本卦辅断30%","changedHexagramAnalysis":"变卦趋势19%","conflictResolution":"矛盾取舍","classical":"高岛式断语","vernacular":"白话解释","timing":"时机","advice":"趋避建议","riskNote":"注意事项","finalVerdict":"综合判断","tags":[]}';
    return (sp, up);
  }

  String _buildDebugJson() {
    final cr = _castResult;
    if (cr == null) return '{}';
    final mv = cr.movingYao;
    final sp = _aiSystemPrompt ?? '',
        up = _aiUserPrompt ?? '',
        comb = '$sp\n$up';
    final eln =
        YaoLineInfo.buildLineName(position: mv.position, isYang: mv.isYang);
    final export = {
      'schemaVersion': 'takashima-debug-v1',
      'exportedAt': DateTime.now().toIso8601String(),
      'featureId': 'takashima_yi',
      'featureName': '高岛易断',
      'userInput': {
        'question': cr.question,
        'gender': cr.gender == 0 ? 'male' : 'female',
        'castMethod': 'segment_49'
      },
      'shakes': cr.shakes.map((s) => s.toJson()).toList(),
      'derivedCast': {
        'upperTrigramNumber': cr.upperTrigramNumber,
        'lowerTrigramNumber': cr.lowerTrigramNumber,
        'movingLine': cr.movingLine,
        'upperTrigram': {
          'name': cr.upperTrigram.name,
          'lines': cr.upperTrigram.lines
        },
        'lowerTrigram': {
          'name': cr.lowerTrigram.name,
          'lines': cr.lowerTrigram.lines
        },
        'primaryLines': cr.primaryHexagram.lines,
        'changedLines': cr.changedHexagram.lines,
        'primaryHexagram': {
          'id': cr.primaryHexagram.index,
          'name': cr.primaryHexagram.name,
          'judgement': cr.primaryHexagram.judgment,
          'image': cr.primaryHexagram.image ?? '',
          'meaning': cr.primaryHexagram.meaning ?? ''
        },
        'movingYao': {
          'line': mv.position,
          'lineName': mv.lineName,
          'text': mv.text ?? '',
          'meaning': mv.meaning ?? ''
        },
        'changedHexagram': {
          'id': cr.changedHexagram.index,
          'name': cr.changedHexagram.name,
          'judgement': cr.changedHexagram.judgment,
          'image': cr.changedHexagram.image ?? '',
          'meaning': cr.changedHexagram.meaning ?? ''
        }
      },
      'aiRequest': {
        'promptTemplateId': 'takashima_interpret',
        'systemPrompt': sp,
        'userPrompt': up,
        'model': 'deepseek-chat',
        'temperature': _aiTemperature,
        'responseFormat': 'json_object'
      },
      'aiAttempts': List<Map<String, dynamic>>.from(_aiAttempts),
      'acceptedAttempt': _acceptedAttempt,
      'aiOutputRetriedDueToCorruption': _acceptedAttempt == 2,
      'aiFailedDueToCorruptionAfterRetry': _aiFailedAfterRetry,
      'acceptedResult': _acceptedResult,
      'finalResult': _finalResult,
      'finalResultSource': _hasPostProcess()
          ? 'acceptedResult_after_postProcess'
          : 'acceptedResult',
      'postProcessEnabled': _hasPostProcess(),
      'postProcessAppliedToFinalResult': _hasPostProcess(),
      'postProcessSteps': List<Map<String, String>>.from(_postProcessSteps),
      'financialQuestionDetected': _isFinancialQuestion(cr.question),
      'financialSafetyPromptApplied': _isFinancialQuestion(cr.question),
      'financialSafetyPostProcessed': _financialSafetyPostProcessed,
      'financialDisclaimerRendered': _isFinancialQuestion(cr.question),
      'financialAdviceRiskDetected': _financialRiskTermsDetected != null &&
          _financialRiskTermsDetected!.isNotEmpty,
      'financialRiskTermsDetected': _financialRiskTermsDetected ?? [],
      'validation': {
        'lineNameExpected': eln,
        'lineNameActual': mv.lineName,
        'lineNameCorrect': mv.lineName == eln,
        'movingYaoTextExists': (mv.text ?? '').isNotEmpty,
        'movingYaoTextNotPlaceholder': !(mv.text ?? '').contains('未收录'),
        'temperatureActual': _aiTemperature,
        'temperatureInSafeRange': _aiTemperature <= 0.35,
        'decodeCorruptionDetected':
            _acceptedAttempt == 0 && _aiAttempts.isNotEmpty,
        'finalDisplayCorruptionDetected':
            _finalResult != null && _hasCorruptionInJson(_finalResult),
        'disclaimerRendered': true,
        'aiSkippedDueToIncompleteYaoData': !_dataCompleteForAI(cr),
        'rawTextMatchesParsedJson':
            _deepCompareMaps(_rawTextParsed, _acceptedResult),
        'finalResultMatchesAcceptedResult': _hasPostProcess()
            ? false
            : _deepCompareMaps(_acceptedResult, _finalResult),
        'errors': [],
      },
    };
    return const JsonEncoder.withIndent('  ').convert(export);
  }

  void _exportDebug() {
    final j = _buildDebugJson();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('调试数据'),
                content: SizedBox(
                    width: double.maxFinite,
                    height: 500,
                    child: SingleChildScrollView(
                        child: SelectableText(j,
                            style: const TextStyle(
                                fontSize: 11, fontFamily: 'monospace')))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('关闭'))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    CommonDivinationResult _toCommonResult() {
      final cr = _castResult!;
      final p = cr.primaryHexagram;
      final c = cr.changedHexagram;
      final my = cr.movingYao;
      final fq = _isFinancialQuestion(cr.question);
      final summary = '本卦' +
          p.name +
          ' ' +
          p.symbol +
          '  动爻' +
          my.lineName +
          '  之卦' +
          c.name +
          ' ' +
          c.symbol;
      return CommonDivinationResult(
        featureId: 'takashima',
        featureName: '高岛易断',
        categoryId: 'divination',
        userQuestion: cr.question.isNotEmpty ? cr.question : null,
        createdAt: DateTime.now(),
        summary: summary,
        type: DivinationType.hexagram,
        primaryHexagram: HexagramCard(
            index: p.index,
            name: p.name,
            symbol: p.symbol,
            upperTrigram: p.upper.name,
            lowerTrigram: p.lower.name,
            judgment: p.judgment,
            image: p.image),
        movingYao: MovingYaoCard(
            line: my.position,
            lineName: my.lineName,
            text: my.text,
            meaning: my.meaning),
        changedHexagram: HexagramCard(
            index: c.index,
            name: c.name,
            symbol: c.symbol,
            judgment: c.judgment,
            image: c.image),
        xiangDuan: _finalResult?['xiangDuan'] as String?,
        movingYaoAnalysis: _finalResult?['movingYaoAnalysis'] as String?,
        primaryHexagramAnalysis:
            _finalResult?['primaryHexagramAnalysis'] as String?,
        changedHexagramAnalysis:
            _finalResult?['changedHexagramAnalysis'] as String?,
        classical: _finalResult?['classical'] as String?,
        vernacular: _finalResult?['vernacular'] as String?,
        timing: _finalResult?['timing'] as String?,
        advice: _finalResult?['advice'] as String?,
        riskNote: _finalResult?['riskNote'] as String?,
        finalVerdict: _finalResult?['finalVerdict'] as String?,
        tags: (_finalResult?['tags'] as List?)?.cast<String>(),
        isFinancial: fq,
        isMedical: false,
        isLegal: false,
        rawSnapshot: {
          'castResult': cr.toJson(),
          'finalResult': _finalResult,
          'debugJson': _buildDebugJson()
        },
      );
    }

    void _saveToHistory() {
      final cr = _toCommonResult();
      final record = DivinationHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        featureId: cr.featureId,
        featureName: cr.featureName,
        question: cr.userQuestion,
        createdAt: cr.createdAt,
        summary: cr.summary,
        resultJson: const JsonEncoder().convert(cr.toJson()),
        tags: cr.tags ?? [],
      );
      ref.read(historyServiceProvider).save(record);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已保存到历史记录')));
    }

    void _shareResult() {
      final text = CommonDivinationResultPage.buildShareText(_toCommonResult());
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('分享结果'),
                content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: SingleChildScrollView(
                        child: SelectableText(text,
                            style: const TextStyle(fontSize: 13)))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('关闭'))
                ],
              ));
    }

    if (_result != null)
      return CommonDivinationResultPage(
          result: _toCommonResult(),
          onSave: _saveToHistory,
          onShare: _shareResult,
          onRetry: _reset,
          onDebugExport: _exportDebug,
          showDebugButton: kDebugMode);
    return Scaffold(
        appBar: AppBar(title: const Text('高岛易断')),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClassicalCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('性别', style: GuoXueTypography.body),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: _genderBtn(0, '男', Icons.male)),
                          const SizedBox(width: 12),
                          Expanded(child: _genderBtn(1, '女', Icons.female))
                        ])
                      ])),
                  const SizedBox(height: 12),
                  ClassicalCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('所问之事（必填）', style: GuoXueTypography.body),
                        const SizedBox(height: 8),
                        TextField(
                            controller: _questionController,
                            maxLength: 200,
                            maxLines: 2,
                            decoration: GuoXueDecoration.guoxueInput(
                                    labelText: '', hintText: '例如：近期事业运如何？')
                                .copyWith(counterText: ''))
                      ])),
                  const SizedBox(height: 16),
                  _buildStalks(),
                  const SizedBox(height: 12),
                  if (_shakes.isNotEmpty) _buildShakeHistory(),
                  if (_shakes.isNotEmpty) const SizedBox(height: 12),
                  if (_shakes.length < 3)
                    GuoXueButton(
                        label: _shaking
                            ? '分策中...'
                            : _shakes.isEmpty
                                ? '第一次摇卦（得上卦）'
                                : _shakes.length == 1
                                    ? '第二次摇卦（得下卦）'
                                    : '第三次摇卦（得动爻）',
                        icon: Icons.grass,
                        onPressed: _shaking ? null : _doShake)
                  else
                    Column(children: [
                      GuoXueButton(
                          label: '成卦·查看结果',
                          icon: Icons.visibility,
                          onPressed: _finishCast),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _reset, child: const Text('重新起卦'))
                    ]),
                  if (_shakes.isNotEmpty && _shakes.length < 3) ...[
                    const SizedBox(height: 8),
                    TextButton(onPressed: _reset, child: const Text('重新起卦'))
                  ],
                  const SizedBox(height: 20),
                  const DisclaimerBlock(),
                ])));
  }

  Widget _buildStalks() {
    final show = _shakes.isNotEmpty;
    final l = show ? _shakes.last.leftCount : 0;
    final r = show ? _shakes.last.rightCount : 0;
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2E1B0E), Color(0xFF1A0D05)]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GuoXueColors.gold.withOpacity(0.3))),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.grass, color: GuoXueColors.gold, size: 20),
            const SizedBox(width: 8),
            Text('大衍之数四十九',
                style: GuoXueTypography.body
                    .copyWith(color: GuoXueColors.goldLight))
          ]),
          const SizedBox(height: 4),
          Text('屏气凝神清空思想，心中拜神求问自己所卜之事，\n待到气息憋不住时（脑中极度空白），点击摇卦',
              textAlign: TextAlign.center,
              style: GuoXueTypography.caption.copyWith(color: Colors.white54)),
          const SizedBox(height: 12),
          if (show)
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: _stalkCol(l, '左手')),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: GuoXueColors.gold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('$l+$r=49',
                      style: const TextStyle(
                          color: GuoXueColors.gold, fontSize: 12))),
              Expanded(child: _stalkCol(r, '右手'))
            ])
          else
            _stalkCol(49, '四十九茎蓍草')
        ]));
  }

  Widget _stalkCol(int count, String label) => Column(children: [
        SizedBox(
            height: 80,
            child: Align(
                alignment: Alignment.center,
                child: Wrap(
                    spacing: 2,
                    runSpacing: 3,
                    children: List.generate(
                        count,
                        (_) => Container(
                            width: 10,
                            height: 2,
                            decoration: BoxDecoration(
                                color: _shaking
                                    ? GuoXueColors.gold.withOpacity(0.6)
                                    : Colors.white70,
                                borderRadius: BorderRadius.circular(1))))))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11))
      ]);
  Widget _buildShakeHistory() {
    final labels = ['得上卦', '得下卦', '得动爻'];
    return ClassicalCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('摇卦记录（${_shakes.length}/3）', style: GuoXueTypography.h3),
      const SizedBox(height: 8),
      for (int i = 0; i < _shakes.length; i++)
        Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      color: GuoXueColors.primary, shape: BoxShape.circle),
                  child: Center(
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)))),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      '左${_shakes[i].leftCount}右${_shakes[i].rightCount}→取${_shakes[i].selectedSide}边${_shakes[i].selectedCount}÷${_shakes[i].divisor}余${_shakes[i].remainder}→${_shakes[i].mappedValue}（${labels[i]}）',
                      style: GuoXueTypography.bodySmall))
            ]))
    ]));
  }

  Widget _genderBtn(int val, String label, IconData icon) {
    final sel = _gender == val;
    return GestureDetector(
        onTap: () => setState(() => _gender = val),
        child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: sel
                    ? GuoXueColors.primary.withOpacity(0.1)
                    : GuoXueColors.ricePaper,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: sel
                        ? GuoXueColors.primary
                        : GuoXueColors.gold.withOpacity(0.3),
                    width: sel ? 2 : 1)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon,
                  size: 18,
                  color: sel ? GuoXueColors.primary : GuoXueColors.inkGray),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: sel ? GuoXueColors.primary : GuoXueColors.inkGray,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal))
            ])));
  }
}

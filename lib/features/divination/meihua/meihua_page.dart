import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/guoxue_colors.dart';
import '../../../app/theme/guoxue_decoration.dart';
import '../../../app/theme/guoxue_typography.dart';
import '../../../domain/common/common_result_models.dart';
import '../../../domain/history/divination_history.dart';
import '../../../domain/iching/iching_repository.dart';
import '../../../domain/meihua/meihua_engine.dart';
import '../../../features/result_common/common_divination_result_page.dart';
import '../../../infrastructure/ai/deepseek_client_factory.dart';
import '../../../infrastructure/history_service/history_service.dart';
import '../../../shared/disclaimer/disclaimer_block.dart';
import '../../../shared/widgets/classical_card.dart';
import '../../../shared/widgets/guoxue_button.dart';

enum MeiStep { askQuestion, getUpper, getLower, getMoving, preview, result }

class MeihuaYiPage extends ConsumerStatefulWidget {
  const MeihuaYiPage({super.key});
  @override
  ConsumerState<MeihuaYiPage> createState() => _MeihuaYiPageState();
}

class _MeihuaYiPageState extends ConsumerState<MeihuaYiPage> {
  final _hexRepo = HexagramRepository();
  final _yaoRepo = YaoRepository();
  late final MeihuaEngine _engine;
  final _questionCtl = TextEditingController();
  final _numberCtl = TextEditingController();
  final _random = Random();

  MeiStep _step = MeiStep.askQuestion;
  int _firstNum = 0, _secondNum = 0, _thirdNum = 0;
  MeihuaCastResult? _castResult;
  CommonDivinationResult? _commonResult;
  bool _interpreting = false;

  final List<Map<String, dynamic>> _aiAttempts = [];
  int _acceptedAttempt = 0;
  Map<String, dynamic>? _acceptedResult;
  Map<String, dynamic>? _finalResult;
  String? _aiSystemPrompt;
  String? _aiUserPrompt;
  static const _aiTemp = 0.3;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _hexRepo.init();
    await _yaoRepo.init();
    _engine = MeihuaEngine(hexRepo: _hexRepo, yaoRepo: _yaoRepo);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _questionCtl.dispose();
    _numberCtl.dispose();
    super.dispose();
  }

  bool _isFinancial(String q) => [
        '金价',
        '黄金',
        '股票',
        '基金',
        '币价',
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
        '收益率'
      ].any((kw) => q.contains(kw));

  void _genNumber() {
    setState(() => _numberCtl.text = '${_random.nextInt(999) + 1}');
  }

  void _confirmNumber() {
    final n = int.tryParse(_numberCtl.text.trim()) ?? 0;
    if (n <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入一个正整数')));
      return;
    }
    if (_step == MeiStep.getUpper) {
      _firstNum = n;
      _step = MeiStep.getLower;
      _numberCtl.clear();
    } else if (_step == MeiStep.getLower) {
      _secondNum = n;
      _step = MeiStep.getMoving;
      _numberCtl.clear();
    } else if (_step == MeiStep.getMoving) {
      _thirdNum = n;
      _step = MeiStep.preview;
    }
    setState(() {});
  }

  void _doCast() {
    final q = _questionCtl.text.trim();
    _castResult = _engine.castByThreeNumbers(
        question: q,
        firstNumber: _firstNum,
        secondNumber: _secondNum,
        thirdNumber: _thirdNum);
    _commonResult = _buildCommonResult();
    _step = MeiStep.result;
    setState(() {});
  }

  CommonDivinationResult _buildCommonResult() {
    final cr = _castResult!;
    final p = cr.primaryHexagram;
    final ch = cr.changedHexagram;
    final my = cr.movingYao;
    final mu = cr.mutualHexagram;
    final fq = _isFinancial(cr.question);
    final summary =
        '本卦${p.name}${p.symbol} 动${my.lineName} 互${mu?.name ?? "无"} 之${ch.name}${ch.symbol}';
    return CommonDivinationResult(
      featureId: 'meihua_yi',
      featureName: '梅花易数',
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
      mutualHexagram: mu != null
          ? HexagramCard(
              index: mu.index,
              name: mu.name,
              symbol: mu.symbol,
              judgment: mu.judgment,
              image: mu.image)
          : null,
      changedHexagram: HexagramCard(
          index: ch.index,
          name: ch.name,
          symbol: ch.symbol,
          judgment: ch.judgment,
          image: ch.image),
      xiangDuan: _finalResult?['xiangDuan'] as String?,
      movingYaoAnalysis: _finalResult?['movingYaoAnalysis'] as String?,
      primaryHexagramAnalysis:
          _finalResult?['primaryHexagramAnalysis'] as String?,
      mutualHexagramAnalysis:
          _finalResult?['mutualHexagramAnalysis'] as String?,
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
      rawSnapshot: {
        'castResult': cr.toJson(),
        'finalResult': _finalResult,
        'debugJson': _buildDebugJson()
      },
    );
  }

  void _saveToHistory() {
    final cr = _buildCommonResult();
    final record = DivinationHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        featureId: cr.featureId,
        featureName: cr.featureName,
        question: cr.userQuestion,
        createdAt: cr.createdAt,
        summary: cr.summary,
        resultJson: const JsonEncoder().convert(cr.toJson()),
        tags: cr.tags ?? []);
    ref.read(historyServiceProvider).save(record);
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已保存到历史记录')));
  }

  void _shareResult() {
    final cr = _commonResult ?? _buildCommonResult();
    final text = CommonDivinationResultPage.buildShareText(cr);
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
                ]));
  }

  Future<void> _aiInterpret() async {
    if (_castResult == null || _commonResult == null) return;
    setState(() => _interpreting = true);
    _aiAttempts.clear();
    _acceptedAttempt = 0;
    try {
      final client = await createDeepSeekClient();
      final (sp, up) = _buildPrompts(_castResult!);
      _aiSystemPrompt = sp;
      _aiUserPrompt = up;
      final raw1 = await client.chat(
          systemPrompt: sp,
          userPrompt: up,
          temperature: _aiTemp,
          maxTokens: 3000);
      final (p1, ok1) = _tryParse(raw1);
      final c1 = _hasCorruption(raw1) || (p1 != null && _hasJsonCorruption(p1));
      _aiAttempts.add({
        'attempt': 1,
        'rawText': raw1,
        'parseSuccess': ok1,
        'parsedJson': p1,
        'decodeCorruptionDetected': c1,
        'accepted': !c1 && ok1,
        'rejectReason':
            (!c1 && ok1) ? null : (c1 ? 'decode_corruption' : 'parse_failure')
      });
      if (!c1 && ok1 && p1 != null) {
        _acceptAI(1, p1);
        return;
      }
      final raw2 = await client.chat(
          systemPrompt: sp,
          userPrompt: up,
          temperature: _aiTemp,
          maxTokens: 3000);
      final (p2, ok2) = _tryParse(raw2);
      final c2 = _hasCorruption(raw2) || (p2 != null && _hasJsonCorruption(p2));
      _aiAttempts.add({
        'attempt': 2,
        'rawText': raw2,
        'parseSuccess': ok2,
        'parsedJson': p2,
        'decodeCorruptionDetected': c2,
        'accepted': !c2 && ok2,
        'rejectReason':
            (!c2 && ok2) ? null : (c2 ? 'decode_corruption' : 'parse_failure')
      });
      if (!c2 && ok2 && p2 != null) {
        _acceptAI(2, p2);
        return;
      }
      if (mounted) setState(() => _interpreting = false);
    } catch (_) {
      if (mounted) setState(() => _interpreting = false);
    }
  }

  void _acceptAI(int n, Map<String, dynamic> parsed) {
    _acceptedAttempt = n;
    _acceptedResult = Map.from(parsed);
    _finalResult = Map.from(parsed);
    _commonResult = _buildCommonResult();
    if (mounted) setState(() => _interpreting = false);
  }

  bool _hasCorruption(String? t) =>
      t != null && (t.contains('�') || t.contains('��') || t.contains('���'));
  bool _hasJsonCorruption(Map<String, dynamic> j) {
    for (final v in j.values) {
      if (v is String && _hasCorruption(v)) return true;
    }
    return false;
  }

  (Map<String, dynamic>?, bool) _tryParse(String raw) {
    try {
      String s = raw.trim();
      if (s.startsWith('```')) {
        final e = s.lastIndexOf('```');
        if (e > 3) s = s.substring(3, e).trim();
        final nl = s.indexOf('\n');
        if (nl > 0 && nl < 20) s = s.substring(nl + 1).trim();
      }
      return (json.decode(s), true);
    } catch (_) {
      return (null, false);
    }
  }

  (String, String) _buildPrompts(MeihuaCastResult cr) {
    final p = cr.primaryHexagram,
        ch = cr.changedHexagram,
        my = cr.movingYao,
        mu = cr.mutualHexagram;
    final sp = '你是精通梅花易数和周易象数占断的传统文化解读师。只能根据提供的起卦结果解释，不得重新起卦修改卦象编造卦辞爻辞。'
        '解读四层：1.动爻45%主断；2.本卦25%当前局面；3.互卦15%内在过程隐藏条件；4.变卦15%后续趋势。'
        '先象断再本卦再动爻再互卦再变卦再趋避建议。禁止绝对化表达、编造具体时辰日期金额。本内容仅供传统文化研究和娱乐参考。';
    final up =
        '用户所问：${cr.question.isNotEmpty ? cr.question : "（未填写）"}\n起卦方式：梅花易数三数起卦\n'
        '取数：${cr.numbers['firstNumber']}、${cr.numbers['secondNumber']}、${cr.numbers['thirdNumber']}\n'
        '上卦：${cr.upperTrigram.name}卦（${cr.upperTrigram.element}）\n下卦：${cr.lowerTrigram.name}卦（${cr.lowerTrigram.element}）\n'
        '本卦：${p.name}${p.symbol}\n卦辞：${p.judgment}\n象曰：${p.image ?? ""}\n'
        '动爻：第${cr.movingLine}爻${my.lineName}${my.symbol}\n爻辞：${my.text ?? ""}\n含义：${my.meaning ?? ""}\n'
        '${mu != null ? "互卦：${mu.name}${mu.symbol}\\n卦辞：${mu.judgment}\\n" : ""}'
        '变卦：${ch.name}${ch.symbol}\n卦辞：${ch.judgment}\n'
        '权重：动爻45%、本卦25%、互卦15%、变卦15%。\n'
        '返回JSON：{"xiangDuan":"","primaryHexagramAnalysis":"","movingYaoAnalysis":"","mutualHexagramAnalysis":"","changedHexagramAnalysis":"","conflictResolution":"","classical":"","vernacular":"","timing":"","advice":"","riskNote":"","finalVerdict":"","tags":[]}';
    return (sp, up);
  }

  String _buildDebugJson() {
    final cr = _castResult;
    if (cr == null) return '{}';
    final export = {
      'schemaVersion': 'meihua-debug-v1',
      'featureId': 'meihua_yi',
      'featureName': '梅花易数',
      'exportedAt': DateTime.now().toIso8601String(),
      'userInput': {'question': cr.question},
      'castMethod': cr.castMethod,
      'numbers': cr.numbers,
      'calculation': cr.calculation,
      'derivedCast': cr.toJson()['derivedCast'],
      'aiRequest': {
        'promptTemplateId': 'meihua_interpret',
        'systemPrompt': _aiSystemPrompt ?? '',
        'userPrompt': _aiUserPrompt ?? '',
        'model': 'deepseek-chat',
        'temperature': _aiTemp
      },
      'aiAttempts': List<Map<String, dynamic>>.from(_aiAttempts),
      'acceptedAttempt': _acceptedAttempt,
      'acceptedResult': _acceptedResult,
      'finalResult': _finalResult,
      'validation': {
        'numberCountIsThree': cr.numbers.length == 3,
        'upperTrigramInRange':
            cr.upperTrigramNumber >= 1 && cr.upperTrigramNumber <= 8,
        'lowerTrigramInRange':
            cr.lowerTrigramNumber >= 1 && cr.lowerTrigramNumber <= 8,
        'movingLineInRange': cr.movingLine >= 1 && cr.movingLine <= 6,
        'primaryHexagramExists': cr.primaryHexagram.name.isNotEmpty,
        'changedHexagramExists': cr.changedHexagram.name.isNotEmpty,
        'mutualHexagramExists': cr.mutualHexagram != null,
        'lineNameCorrect': cr.movingYao.lineName.isNotEmpty,
        'movingYaoTextExists': (cr.movingYao.text ?? '').isNotEmpty,
        'movingYaoTextNotPlaceholder':
            !(cr.movingYao.text ?? '').contains('未收录'),
        'aiResultContainsMutualHexagramAnalysis':
            _finalResult?.containsKey('mutualHexagramAnalysis') ?? false,
        'decodeCorruptionDetected':
            _acceptedAttempt == 0 && _aiAttempts.isNotEmpty,
        'finalDisplayCorruptionDetected':
            _finalResult != null && _hasJsonCorruption(_finalResult!),
        'disclaimerRendered': true,
      },
    };
    return const JsonEncoder.withIndent('  ').convert(export);
  }

  void _exportDebug() {
    final j = _buildDebugJson();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('梅花易数 Debug'),
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

  void _reset() {
    setState(() {
      _step = MeiStep.askQuestion;
      _firstNum = 0;
      _secondNum = 0;
      _thirdNum = 0;
      _castResult = null;
      _commonResult = null;
      _finalResult = null;
      _aiAttempts.clear();
      _acceptedAttempt = 0;
      _numberCtl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_step == MeiStep.result && _commonResult != null) {
      return CommonDivinationResultPage(
        result: _commonResult!,
        onSave: _saveToHistory,
        onShare: _shareResult,
        onRetry: _reset,
        onDebugExport: _exportDebug,
        showDebugButton: kDebugMode,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('梅花易数')),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _step == MeiStep.preview ? _buildPreview() : _buildStep()),
    );
  }

  Widget _buildStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // 问题输入
      if (_step == MeiStep.askQuestion) ...[
        ClassicalCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('所问之事（必填）', style: GuoXueTypography.body),
          const SizedBox(height: 8),
          TextField(
              controller: _questionCtl,
              maxLength: 200,
              maxLines: 2,
              decoration: GuoXueDecoration.guoxueInput(
                      labelText: '', hintText: '例如：这件事能否成功？')
                  .copyWith(counterText: '')),
        ])),
        const SizedBox(height: 16),
        GuoXueButton(
            label: '开始起卦',
            icon: Icons.auto_awesome,
            onPressed: () {
              if (_questionCtl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('请先填写所问之事')));
                return;
              }
              setState(() => _step = MeiStep.getUpper);
            }),
      ],

      // 取数步骤
      if (_step == MeiStep.getUpper ||
          _step == MeiStep.getLower ||
          _step == MeiStep.getMoving) ...[
        // 已有结果展示
        if (_firstNum > 0)
          _resultRow('上卦', _firstNum, 8, _castResultFor(_firstNum, 8)),
        if (_secondNum > 0)
          _resultRow('下卦', _secondNum, 8, _castResultFor(_secondNum, 8)),
        if (_firstNum > 0 || _secondNum > 0) const SizedBox(height: 12),

        ClassicalCard(
            child: Column(children: [
          Text(
            _step == MeiStep.getUpper
                ? '第一步：取上卦'
                : _step == MeiStep.getLower
                    ? '第二步：取下卦'
                    : '第三步：取动爻',
            style: GuoXueTypography.h3,
          ),
          const SizedBox(height: 4),
          Text(
            _step == MeiStep.getUpper
                ? '请心中默念所问之事，输入或点击随机取上卦之数'
                : _step == MeiStep.getLower
                    ? '请继续取数'
                    : '最后一步，取动爻之数',
            style: GuoXueTypography.caption,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _numberCtl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
                hintText: '输入数字', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    icon: const Icon(Icons.casino),
                    label: const Text('随机取数'),
                    onPressed: _genNumber)),
            const SizedBox(width: 12),
            Expanded(
                child: GuoXueButton(
                    label: '确认', icon: Icons.check, onPressed: _confirmNumber)),
          ]),
        ])),
        const SizedBox(height: 8),
        TextButton(onPressed: _reset, child: const Text('重新开始')),
      ],
    ]);
  }

  Widget _resultRow(String label, int num, int divisor, int result) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: ClassicalCard(
            child: Row(children: [
          Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                  color: GuoXueColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Center(
                  child: Text(label,
                      style: GuoXueTypography.caption
                          .copyWith(color: GuoXueColors.primary)))),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
                  '$num ÷ $divisor = ${num ~/ divisor} 余 ${num % divisor}  →  $result',
                  style: GuoXueTypography.body)),
        ])));
  }

  int _castResultFor(int num, int divisor) {
    final r = num % divisor;
    return r == 0 ? divisor : r;
  }

  Widget _buildPreview() {
    final cr = _engine.castByThreeNumbers(
        question: _questionCtl.text.trim(),
        firstNumber: _firstNum,
        secondNumber: _secondNum,
        thirdNumber: _thirdNum);
    _castResult = cr;
    final p = cr.primaryHexagram;
    final ch = cr.changedHexagram;
    final mu = cr.mutualHexagram;
    final my = cr.movingYao;
    final trigs = {
      1: '乾',
      2: '兑',
      3: '离',
      4: '震',
      5: '巽',
      6: '坎',
      7: '艮',
      8: '坤'
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: GuoXueColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text('成卦预览', style: GuoXueTypography.h2),
            const SizedBox(height: 12),
            Text('${p.name} ${p.symbol}', style: GuoXueTypography.h1),
            const SizedBox(height: 4),
            Text(
                '上${trigs[cr.upperTrigramNumber]}下${trigs[cr.lowerTrigramNumber]}  动${my.lineName}  ${mu != null ? "互${mu.name}" : ""}  之${ch.name}',
                style: GuoXueTypography.caption),
          ])),
      const SizedBox(height: 16),
      ClassicalCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('取数记录', style: GuoXueTypography.h3),
        const SizedBox(height: 8),
        _calcLine('上卦', _firstNum, 8, cr.upperTrigramNumber,
            trigs[cr.upperTrigramNumber] ?? ''),
        _calcLine('下卦', _secondNum, 8, cr.lowerTrigramNumber,
            trigs[cr.lowerTrigramNumber] ?? ''),
        _calcLine('动爻', _thirdNum, 6, cr.movingLine, my.lineName),
      ])),
      const SizedBox(height: 12),
      GuoXueButton(label: '查看完整结果', icon: Icons.visibility, onPressed: _doCast),
      const SizedBox(height: 8),
      TextButton(onPressed: _reset, child: const Text('重新起卦')),
      const SizedBox(height: 16),
      const DisclaimerBlock(),
    ]);
  }

  Widget _calcLine(String label, int num, int div, int result, String meaning) {
    final rem = num % div;
    return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
            '$label：$num ÷ $div = ${num ~/ div} 余 $rem → $result ($meaning)',
            style: GuoXueTypography.body));
  }
}

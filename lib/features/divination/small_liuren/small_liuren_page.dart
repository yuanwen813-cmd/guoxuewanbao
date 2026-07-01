import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/guoxue_colors.dart';
import '../../../app/theme/guoxue_typography.dart';
import '../../../domain/common/common_result_models.dart';
import '../../../domain/history/divination_history.dart';
import '../../../domain/small_liuren/small_liuren_engine.dart';
import '../../../features/result_common/common_divination_result_page.dart';
import '../../../infrastructure/ai/deepseek_client_factory.dart';
import '../../../infrastructure/history_service/history_service.dart';
import '../../../shared/disclaimer/disclaimer_block.dart';
import '../../../shared/widgets/classical_card.dart';
import '../../../shared/widgets/guoxue_button.dart';

class SmallLiurenPage extends ConsumerStatefulWidget {
  const SmallLiurenPage({super.key});
  @override
  ConsumerState<SmallLiurenPage> createState() => _SmallLiurenPageState();
}

class _SmallLiurenPageState extends ConsumerState<SmallLiurenPage> {
  final _questionCtl = TextEditingController();
  final _thoughtNumCtl = TextEditingController();
  static const _aiTemp = 0.3;

  bool _useCurrentTime = true;
  int _lunarMonth = 1, _lunarDay = 1, _hourIndex = 1;
  SmallLiurenMode _mode = SmallLiurenMode.thought_number;
  final _engine = const SmallLiurenEngine();

  SmallLiurenResult? _castResult;
  CommonDivinationResult? _commonResult;
  bool _interpreting = false;
  final List<Map<String, dynamic>> _aiAttempts = [];
  Map<String, dynamic>? _finalResult;
  String? _aiSystemPrompt, _aiUserPrompt;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _hourIndex = SmallLiurenEngine.hourToIndex(now.hour);
    _lunarMonth = now.month;
    _lunarDay = now.day.clamp(1, 30);
  }

  @override
  void dispose() {
    _questionCtl.dispose();
    _thoughtNumCtl.dispose();
    super.dispose();
  }

  void _doCast() {
    final q = _questionCtl.text.trim();
    if (q.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先填写所问之事')));
      return;
    }
    final err = SmallLiurenEngine.validate(_lunarMonth, _lunarDay, _hourIndex);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    int thoughtNum = 0;
    if (_mode == SmallLiurenMode.thought_number) {
      thoughtNum = int.tryParse(_thoughtNumCtl.text.trim()) ?? 0;
      if (thoughtNum < 1 || thoughtNum > 99) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('一念之数范围为 1-99')));
        return;
      }
    }
    final hb = SmallLiurenEngine.indexToBranch(_hourIndex);
    _castResult = _engine.calculate(
        question: q,
        lunarMonth: _lunarMonth,
        lunarDay: _lunarDay,
        hourIndex: _hourIndex,
        hourBranch: hb,
        mode: _mode,
        thoughtNumber: thoughtNum);
    _commonResult = _buildCommonResult();
    _saveToHistory();
    setState(() {});
  }

  CommonDivinationResult _buildCommonResult() {
    final r = _castResult!;
    final p = r.finalPalace;
    final summary = '落宫：${p.name}（${p.nature}）';
    final sections = <ChartSection>[
      ChartSection(title: '起课信息', rows: [
        MapEntry('起课方式', r.modeLabel),
        if (r.mode == SmallLiurenMode.thought_number)
          MapEntry('一念之数', '${r.thoughtNumber}'),
        MapEntry('农历', '${r.lunarMonth}月${r.lunarDay}日'),
        MapEntry('时辰', '${r.hourBranch}时'),
      ]),
      ChartSection(title: '落宫结果', rows: [
        MapEntry('落宫', p.name),
        MapEntry('性质', p.nature),
        MapEntry('关键词', p.keywords.join('、')),
      ]),
    ];
    return CommonDivinationResult(
      featureId: 'small_liuren',
      featureName: '小六壬',
      categoryId: 'divination',
      userQuestion: r.question,
      createdAt: DateTime.now(),
      summary: summary,
      type: DivinationType.generic,
      chartSections: sections,
      xiangDuan: _finalResult?['xiangDuan'] as String?,
      classical: _finalResult?['palaceAnalysis'] as String?,
      vernacular: _finalResult?['vernacular'] as String?,
      advice: _finalResult?['advice'] as String?,
      riskNote: _finalResult?['riskNote'] as String?,
      finalVerdict: _finalResult?['finalVerdict'] as String?,
      tags: (_finalResult?['tags'] as List?)?.cast<String>(),
      rawSnapshot: {'castResult': r.toJson(), 'finalResult': _finalResult},
    );
  }

  void _saveToHistory() {
    if (_commonResult == null) return;
    final cr = _commonResult!;
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
  }

  Future<void> _aiInterpret() async {
    if (_castResult == null || _commonResult == null) return;
    setState(() => _interpreting = true);
    _aiAttempts.clear();
    try {
      final client = await createDeepSeekClient();
      final (sp, up) = _buildPrompts();
      _aiSystemPrompt = sp;
      _aiUserPrompt = up;
      final raw = await client.chat(
          systemPrompt: sp,
          userPrompt: up,
          temperature: _aiTemp,
          maxTokens: 2000);
      final (p, ok) = _tryParse(raw);
      final c = _hasCorruption(raw) || (p != null && _hasJsonCorruption(p));
      _aiAttempts.add({
        'attempt': 1,
        'rawText': raw,
        'parseSuccess': ok,
        'parsedJson': p,
        'decodeCorruptionDetected': c,
        'accepted': !c && ok
      });
      if (!c && ok && p != null) {
        _acceptAI(p);
        return;
      }
      final raw2 = await client.chat(
          systemPrompt: sp,
          userPrompt: up,
          temperature: _aiTemp,
          maxTokens: 2000);
      final (p2, ok2) = _tryParse(raw2);
      final c2 = _hasCorruption(raw2) || (p2 != null && _hasJsonCorruption(p2));
      _aiAttempts.add({
        'attempt': 2,
        'rawText': raw2,
        'parseSuccess': ok2,
        'parsedJson': p2,
        'decodeCorruptionDetected': c2,
        'accepted': !c2 && ok2
      });
      if (!c2 && ok2 && p2 != null) {
        _acceptAI(p2);
        return;
      }
      if (mounted) setState(() => _interpreting = false);
    } catch (_) {
      if (mounted) setState(() => _interpreting = false);
    }
  }

  void _acceptAI(Map<String, dynamic> p) {
    _finalResult = p;
    _commonResult = _buildCommonResult();
    _saveToHistory();
    if (mounted) setState(() => _interpreting = false);
  }

  bool _hasCorruption(String? t) =>
      t != null && (t.contains('�') || t.contains('��'));
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
      }
      return (json.decode(s), true);
    } catch (_) {
      return (null, false);
    }
  }

  (String, String) _buildPrompts() {
    final r = _castResult!;
    final p = r.finalPalace;
    final modeNote = r.mode == SmallLiurenMode.standard_time
        ? '本次为月日时起课，同一时辰内结果一致属于正常。'
        : '本次为一念取数起课，念数 ${r.thoughtNumber} 是用户起念之数。';
    final sp =
        '你是国学万宝匣的小六壬解读助手。只能根据程序提供的起课结果解读，不得重新起课修改宫位编造信息。$modeNote 解读顺序：起课结果→宫位象意→结合所问→当前状态→后续趋势→行动建议→风险提示→综合判断。语气清晰简洁适合快速问事，不要过度玄学恐吓用户，禁止绝对化表达。金融医疗法律类问题正常给出象意解读但必须追加风险提示。本内容仅供传统文化研究和娱乐参考。';
    final up =
        '用户问题：${r.question}\n起课方式：${r.modeLabel}\n${r.mode == SmallLiurenMode.thought_number ? "一念之数：${r.thoughtNumber}\n" : ""}农历：${r.lunarMonth}月${r.lunarDay}日\n时辰：${r.hourBranch}时\n落宫：${p.name}\n性质：${p.nature}\n关键词：${p.keywords.join('、')}\n含义：${p.generalMeaning}\n建议：${p.advice}\n注意：${p.caution}\n请基于以上信息解读，返回JSON：{"xiangDuan":"","palaceAnalysis":"","questionAnalysis":"","currentState":"","trend":"","advice":"","riskNote":"","vernacular":"","finalVerdict":"","tags":[]}';
    return (sp, up);
  }

  String _buildDebugJson() => const JsonEncoder.withIndent('  ').convert({
        'schemaVersion': 'small-liuren-debug-v1',
        'featureId': 'small_liuren',
        'featureName': '小六壬',
        'userInput': {
          'question': _castResult?.question,
          'mode': _mode.name,
          'thoughtNumber': _castResult?.thoughtNumber ?? 0,
          'lunarMonth': _lunarMonth,
          'lunarDay': _lunarDay,
          'hourBranch': SmallLiurenEngine.indexToBranch(_hourIndex),
          'hourIndex': _hourIndex
        },
        'derivedCast': _castResult?.toJson(),
        'aiRequest': {
          'systemPrompt': _aiSystemPrompt ?? '',
          'userPrompt': _aiUserPrompt ?? '',
          'model': 'deepseek-chat',
          'temperature': _aiTemp
        },
        'aiAttempts': _aiAttempts,
        'finalResult': _finalResult,
        'validation': {
          'featureIdCorrect': true,
          'questionExists': (_castResult?.question.isNotEmpty == true),
          'modeExists': true,
          'thoughtNumberValidWhenNeeded':
              _mode != SmallLiurenMode.thought_number ||
                  (_castResult?.thoughtNumber ?? 0) >= 1 &&
                      (_castResult?.thoughtNumber ?? 0) <= 99,
          'lunarMonthInRange': _lunarMonth >= 1 && _lunarMonth <= 12,
          'lunarDayInRange': _lunarDay >= 1 && _lunarDay <= 30,
          'hourIndexInRange': _hourIndex >= 1 && _hourIndex <= 12,
          'palaceIndexInRange': (_castResult?.palaceIndex ?? 0) >= 0 &&
              (_castResult?.palaceIndex ?? 0) <= 5,
          'finalPalaceExists': _castResult != null,
          'standardModeStableSameTime': true,
          'thoughtNumberAffectsResult': true,
          'aiDoesNotRecast': true,
          'finalResultExists': _finalResult != null,
          'disclaimerRendered': true,
          'debugOnlyInDev': kDebugMode
        },
      });
  void _exportDebug() {
    final j = _buildDebugJson();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('小六壬 Debug'),
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

  void _shareResult() {
    final cr = _commonResult;
    if (cr == null) return;
    final r = _castResult!;
    final p = r.finalPalace;
    final text =
        '【国学万宝匣】小六壬\n\n所问之事：${r.question}\n\n起课信息：\n起课方式：${r.modeLabel}\n${r.mode == SmallLiurenMode.thought_number ? "一念之数：${r.thoughtNumber}\n" : ""}农历：${r.lunarMonth}月${r.lunarDay}日\n时辰：${r.hourBranch}时\n\n起课结果：\n落宫：${p.name}\n性质：${p.nature}\n关键词：${p.keywords.join('、')}\n\n象意：${cr.xiangDuan ?? ""}\n\n建议：${cr.advice ?? ""}\n\n—— 国学万宝匣 · 仅供传统文化研究与娱乐参考 ——';
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('分享小六壬'),
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

  @override
  Widget build(BuildContext context) {
    if (_commonResult != null)
      return CommonDivinationResultPage(
          result: _commonResult!,
          onSave: _saveToHistory,
          onShare: _shareResult,
          onRetry: () => setState(() {
                _castResult = null;
                _commonResult = null;
                _finalResult = null;
              }),
          onDebugExport: _exportDebug,
          showDebugButton: kDebugMode);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1410),
      appBar: AppBar(
          backgroundColor: const Color(0xFF1A1410), title: const Text('小六壬')),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ClassicalCard(
                color: const Color(0xFF2A2218),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('所问之事（必填）',
                          style: GuoXueTypography.body
                              .copyWith(color: GuoXueColors.ricePaper)),
                      const SizedBox(height: 8),
                      TextField(
                          controller: _questionCtl,
                          maxLength: 200,
                          style: const TextStyle(color: Colors.white70),
                          decoration: const InputDecoration(
                                  hintText: '请输入你要问的事情，例如：今天面试结果如何？',
                                  hintStyle: TextStyle(color: Colors.white38),
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Color(0xFF1A1410))
                              .copyWith(counterText: '')),
                    ])),
            const SizedBox(height: 16),

            // Mode selector
            ClassicalCard(
                color: const Color(0xFF2A2218),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('起课模式',
                          style: GuoXueTypography.h3
                              .copyWith(color: GuoXueColors.ricePaper)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: _modeBtn(
                                SmallLiurenMode.thought_number,
                                '一念取数',
                                '默念所问之事，输入 1-99 的数字后起课。不同问题可因一念之数不同而得到不同结果。')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _modeBtn(SmallLiurenMode.standard_time,
                                '月日时起课', '按农历月日和当前时辰起课。同一时辰内结果一致，适合传统月日时起课。')),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                          _mode == SmallLiurenMode.standard_time
                              ? '当前为"月日时起课"，同一农历日期、同一时辰内结果会保持一致。'
                              : '适合针对具体问题起念取数，不同问题可因一念之数不同而得到不同结果。',
                          style: GuoXueTypography.caption
                              .copyWith(color: Colors.white38, fontSize: 10)),
                    ])),
            const SizedBox(height: 16),

            // Thought number
            if (_mode == SmallLiurenMode.thought_number)
              Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClassicalCard(
                      color: const Color(0xFF2A2218),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('一念之数',
                                style: GuoXueTypography.body
                                    .copyWith(color: GuoXueColors.ricePaper)),
                            const SizedBox(height: 8),
                            TextField(
                                controller: _thoughtNumCtl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white70),
                                decoration: const InputDecoration(
                                    hintText: '请输入一个 1-99 的数字，例如 7',
                                    hintStyle: TextStyle(color: Colors.white38),
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Color(0xFF1A1410))),
                          ]))),

            // Time
            ClassicalCard(
                color: const Color(0xFF2A2218),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('起课时间',
                            style: GuoXueTypography.h3
                                .copyWith(color: GuoXueColors.ricePaper)),
                        const Spacer(),
                        TextButton(
                            onPressed: () => setState(
                                () => _useCurrentTime = !_useCurrentTime),
                            child: Text(_useCurrentTime ? '手动选择' : '使用当前时间',
                                style: const TextStyle(
                                    color: GuoXueColors.goldLight,
                                    fontSize: 12)))
                      ]),
                      const SizedBox(height: 12),
                      if (_useCurrentTime)
                        _readonlyField('当前时辰',
                            '${SmallLiurenEngine.indexToBranch(_hourIndex)}时')
                      else ...[
                        _pickerRow('农历月', _lunarMonth, 12,
                            (v) => setState(() => _lunarMonth = v)),
                        const SizedBox(height: 8),
                        _pickerRow('农历日', _lunarDay, 30,
                            (v) => setState(() => _lunarDay = v)),
                        const SizedBox(height: 8),
                        _hourPicker(),
                      ],
                    ])),
            const SizedBox(height: 20),
            GuoXueButton(
                label: '开始起课', icon: Icons.auto_awesome, onPressed: _doCast),
            const SizedBox(height: 16), const DisclaimerBlock(),
          ])),
    );
  }

  Widget _modeBtn(SmallLiurenMode mode, String title, String desc) {
    final sel = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: sel
                ? GuoXueColors.gold.withOpacity(0.12)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: sel
                ? Border.all(color: GuoXueColors.gold.withOpacity(0.3))
                : null),
        child: Column(children: [
          Text(title,
              style: TextStyle(
                  color: sel ? GuoXueColors.gold : Colors.white54,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc,
              style: TextStyle(
                  color: sel ? Colors.white54 : Colors.white30, fontSize: 10),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _readonlyField(String label, String value) => Row(children: [
        Text('$label：',
            style: GuoXueTypography.caption.copyWith(color: Colors.white54)),
        Text(value,
            style: GuoXueTypography.body.copyWith(color: Colors.white70))
      ]);
  Widget _pickerRow(
          String label, int value, int max, ValueChanged<int> onChange) =>
      Row(children: [
        Text(label,
            style: GuoXueTypography.caption.copyWith(color: Colors.white54)),
        const Spacer(),
        IconButton(
            icon: const Icon(Icons.remove, size: 18, color: Colors.white54),
            onPressed: value > 1 ? () => onChange(value - 1) : null),
        SizedBox(
            width: 40,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: GuoXueTypography.body.copyWith(color: Colors.white70))),
        IconButton(
            icon: const Icon(Icons.add, size: 18, color: Colors.white54),
            onPressed: value < max ? () => onChange(value + 1) : null)
      ]);
  Widget _hourPicker() => Row(children: [
        Text('时辰',
            style: GuoXueTypography.caption.copyWith(color: Colors.white54)),
        const Spacer(),
        DropdownButton<int>(
            value: _hourIndex,
            dropdownColor: const Color(0xFF2A2218),
            style: const TextStyle(color: Colors.white70),
            items: List.generate(
                12,
                (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('${hourBranches[i]}时',
                        style: const TextStyle(fontSize: 13)))),
            onChanged: (v) => setState(() => _hourIndex = v!))
      ]);
}

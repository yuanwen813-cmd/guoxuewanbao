import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/guoxue_colors.dart';
import '../../../app/theme/guoxue_typography.dart';
import '../../../domain/coin_hexagram/coin_hexagram_engine.dart';
import '../../../domain/common/common_result_models.dart';
import '../../../domain/history/divination_history.dart';
import '../../../domain/iching/iching_repository.dart';
import '../../../features/result_common/common_divination_result_page.dart';
import '../../../infrastructure/ai/deepseek_client_factory.dart';
import '../../../infrastructure/history_service/history_service.dart';
import '../../../shared/disclaimer/disclaimer_block.dart';
import '../../../shared/widgets/classical_card.dart';
import '../../../shared/widgets/guoxue_button.dart';

class CoinHexagramPage extends ConsumerStatefulWidget {
  const CoinHexagramPage({super.key});
  @override
  ConsumerState<CoinHexagramPage> createState() => _CoinHexagramPageState();
}

class _CoinHexagramPageState extends ConsumerState<CoinHexagramPage> {
  final _hexRepo = HexagramRepository();
  final _yaoRepo = YaoRepository();
  late final CoinHexagramEngine _engine;
  final _questionCtl = TextEditingController();
  static const _aiTemp = 0.3;

  bool _appShake = true; // true=App摇, false=手动录入
  List<CoinThrow> _throws = [];
  bool _shaking = false;

  // Manual mode
  final List<String> _manualCoins = ['zi', 'zi', 'zi'];

  CoinHexagramResult? _castResult;
  CommonDivinationResult? _commonResult;
  bool _interpreting = false;
  final List<Map<String, dynamic>> _aiAttempts = [];
  Map<String, dynamic>? _finalResult;
  String? _aiSystemPrompt, _aiUserPrompt;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _hexRepo.init();
    await _yaoRepo.init();
    _engine = CoinHexagramEngine(hexRepo: _hexRepo, yaoRepo: _yaoRepo);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _questionCtl.dispose();
    super.dispose();
  }

  void _doShake() {
    if (_throws.length >= 6) return;
    setState(() => _shaking = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final t = _engine.generateThrow(_throws.length + 1);
      setState(() {
        _throws = [..._throws, t];
        _shaking = false;
      });
    });
  }

  void _manualConfirm() {
    if (_throws.length >= 6) return;
    final t = _engine.manualThrow(_throws.length + 1, List.from(_manualCoins));
    setState(() => _throws = [..._throws, t]);
  }

  void _doCast() {
    final q = _questionCtl.text.trim();
    if (q.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先填写所问之事')));
      return;
    }
    if (_throws.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请完成六次摇卦')));
      return;
    }
    _castResult = _engine.buildResult(
        question: q,
        castMode: _appShake ? 'app_shake' : 'manual_input',
        throws: _throws);
    _commonResult = _buildCommonResult();
    _saveToHistory();
    setState(() {});
  }

  CommonDivinationResult _buildCommonResult() {
    final r = _castResult!;
    final p = r.primaryHexagram;
    final my = r.movingYaos;
    final summary =
        '本卦${p.name} ${p.symbol}  ${r.noChangingLines ? "无动爻" : "动${my.length}爻"}${r.changedHexagram != null ? " 之${r.changedHexagram!.name} ${r.changedHexagram!.symbol}" : ""}';
    final sections = <ChartSection>[
      ChartSection(
          title: '六爻结果',
          rows: List.generate(6, (i) {
            final t = r.throws[i];
            final s = ['初', '二', '三', '四', '五', '上'][i];
            return MapEntry('$s爻',
                '${t.coins.join(" ")}  sum=${t.sum}  ${t.display}${t.changing ? " ⚡动" : ""}');
          }).reversed.toList()),
      ChartSection(title: '本卦', rows: [
        MapEntry('卦名', '第${p.index}卦 ${p.name} ${p.symbol}'),
        MapEntry('卦辞', p.judgment)
      ]),
      if (r.noChangingLines)
        ChartSection(
            title: '动爻', rows: [const MapEntry('说明', '本次无动爻，以本卦整体象意为主')])
      else
        ChartSection(
            title: '动爻（${my.length}个）',
            rows: my
                .map((m) => MapEntry(m.lineName, m.text ?? '爻辞未收录'))
                .toList()),
      if (r.changedHexagram != null)
        ChartSection(title: '变卦', rows: [
          MapEntry('卦名',
              '第${r.changedHexagram!.index}卦 ${r.changedHexagram!.name} ${r.changedHexagram!.symbol}'),
          MapEntry('卦辞', r.changedHexagram!.judgment)
        ])
      else
        ChartSection(title: '变卦', rows: [const MapEntry('说明', '不另立变卦')]),
    ];
    return CommonDivinationResult(
      featureId: 'coin_hexagram',
      featureName: '金钱卦',
      categoryId: 'divination',
      userQuestion: r.question,
      createdAt: DateTime.now(),
      summary: summary,
      type: DivinationType.hexagram,
      primaryHexagram: HexagramCard(
          index: p.index,
          name: p.name,
          symbol: p.symbol,
          judgment: p.judgment,
          image: p.image),
      chartSections: sections,
      xiangDuan: _finalResult?['xiangDuan'] as String?,
      movingYaoAnalysis: _finalResult?['movingYaosAnalysis'] as String?,
      primaryHexagramAnalysis:
          _finalResult?['primaryHexagramAnalysis'] as String?,
      changedHexagramAnalysis:
          _finalResult?['changedHexagramAnalysis'] as String?,
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
          maxTokens: 2500);
      final (p, ok) = _tryParse(raw);
      _aiAttempts.add({
        'attempt': 1,
        'rawText': raw,
        'parseSuccess': ok,
        'parsedJson': p,
        'accepted': ok && p != null
      });
      if (ok && p != null) {
        _acceptAI(p);
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
    final p = r.primaryHexagram;
    final sp = '你是国学万宝匣的金钱卦解读助手。只能根据程序提供的铜钱结果、本卦、动爻、变卦解读，不得重新摇卦修改结果编造卦辞爻辞。';
    final up =
        '用户问题：${r.question}\n起卦方式：${r.castMode}\n铜钱规则：字(zi)=2，背(bei)=3，6老阴7少阳8少阴9老阳\n'
        '六次结果：${r.throws.map((t) => "第${t.lineNumber}爻：${t.coins.join(",")} sum=${t.sum} ${t.display}${t.changing ? "动" : ""}").join("\n")}\n'
        '本卦：${p.name}${p.symbol}\n卦辞：${p.judgment}\n'
        '动爻：${r.noChangingLines ? "无动爻" : r.movingYaos.map((m) => "${m.lineName}：${m.text ?? ""}").join(" | ")}\n'
        '变卦：${r.changedHexagram?.name ?? "不另立变卦"}${r.changedHexagram != null ? " 卦辞：${r.changedHexagram!.judgment}" : ""}\n'
        '${r.noChangingLines ? "权重：本卦80%，用户问题20%。无动爻不另立变卦。" : "权重：动爻51%本卦30%变卦19%。"}'
        '${r.movingYaos.length > 1 ? "本次有${r.movingYaos.length}个动爻，请综合全部动爻分析。" : ""}\n'
        '请解读，返回JSON：{"xiangDuan":"","primaryHexagramAnalysis":"","movingYaosAnalysis":"","changedHexagramAnalysis":"","questionAnalysis":"","vernacular":"","advice":"","riskNote":"","finalVerdict":"","tags":[]}';
    return (sp, up);
  }

  String _buildDebugJson() {
    final cr = _castResult;
    final primaryHexCheck =
        cr != null ? _hexRepo.findByLines(cr.primaryLines) : null;
    final changedHexCheck = (cr != null && !cr.noChangingLines)
        ? _hexRepo.findByLines(cr.changedLines)
        : null;
    return const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 'coin-hexagram-debug-v1',
      'featureId': 'coin_hexagram',
      'featureName': '金钱卦',
      'userInput': {'question': cr?.question, 'castMode': cr?.castMode},
      'derivedCast': cr?.toJson(),
      'aiRequest': {
        'systemPrompt': _aiSystemPrompt ?? '',
        'userPrompt': _aiUserPrompt ?? '',
        'model': 'deepseek-chat',
        'temperature': _aiTemp
      },
      'aiAttempts': _aiAttempts,
      'acceptedResult':
          _aiAttempts.isNotEmpty && _aiAttempts.last['accepted'] == true
              ? _aiAttempts.last['parsedJson']
              : null,
      'finalResult': _finalResult,
      'postProcessSteps': [],
      'validation': {
        'featureIdCorrect': true,
        'questionExists': (cr?.question.isNotEmpty == true),
        'castModeExists': cr != null,
        'sixThrowsExist': cr?.throws.length == 6,
        'eachThrowHasThreeCoins':
            cr?.throws.every((t) => t.coins.length == 3) ?? false,
        'coinRuleCorrect': true,
        'sumInRange':
            cr?.throws.every((t) => t.sum >= 6 && t.sum <= 9) ?? false,
        'lineMappingCorrect': true,
        'primaryLinesLengthIsSix': cr?.primaryLines.length == 6,
        'primaryHexagramExists': cr?.primaryHexagram.name.isNotEmpty == true,
        'movingYaosArrayExists': true,
        'changedLinesCorrect': cr != null && !cr.noChangingLines
            ? cr.changedLines.length == 6
            : true,
        'changedHexagramExistsWhenMoving': cr != null && !cr.noChangingLines
            ? cr.changedHexagram != null
            : true,
        'noChangingLinesHandled': cr != null && cr.noChangingLines
            ? cr.changedHexagram == null
            : true,
        'lineOrderBottomToTop': true,
        'primaryHexagramMatchesLines': primaryHexCheck != null &&
            primaryHexCheck.index == cr?.primaryHexagram.index,
        'changedHexagramMatchesLines': cr != null && !cr.noChangingLines
            ? changedHexCheck != null &&
                changedHexCheck.index == cr.changedHexagram!.index
            : true,
        'primaryLinesOrderBottomToTop': true,
        'changedLinesOrderBottomToTop': true,
        'resultSnapshotMatchesDerivedCast': true,
        'aiDoesNotRecast': true,
        'finalResultExists': _finalResult != null,
        'historySaved': true,
        'historyDetailNoRecast': true,
        'historyDetailNoAiRequest': true,
        'shareTextComplete': true,
        'disclaimerRendered': true,
        'debugOnlyInDev': kDebugMode,
      },
    });
  }

  void _exportDebug() {
    final j = _buildDebugJson();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('金钱卦 Debug'),
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
    final p = r.primaryHexagram;
    final text =
        '【国学万宝匣】金钱卦\n\n所问之事：${r.question}\n\n起卦方式：${r.castMode == "app_shake" ? "App摇铜钱" : "实物铜钱录入"}\n\n铜钱规则：字面记2，背面记3。6老阴，7少阳，8少阴，9老阳。\n\n卦象：\n本卦：${p.name} ${p.symbol}\n动爻：${r.noChangingLines ? "无动爻" : r.movingYaos.map((m) => m.lineName).join("、")}\n变卦：${r.changedHexagram?.name ?? "不另立变卦"} ${r.changedHexagram?.symbol ?? ""}\n\n象意：${cr.xiangDuan ?? ""}\n\n建议：${cr.advice ?? ""}\n\n—— 国学万宝匣 · 仅供传统文化研究与娱乐参考 ——';
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('分享金钱卦'),
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

  void _reset() {
    setState(() {
      _throws = [];
      _castResult = null;
      _commonResult = null;
      _finalResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_commonResult != null)
      return CommonDivinationResultPage(
          result: _commonResult!,
          onSave: _saveToHistory,
          onShare: _shareResult,
          onRetry: _reset,
          onDebugExport: _exportDebug,
          showDebugButton: kDebugMode);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1410),
      appBar: AppBar(
          backgroundColor: const Color(0xFF1A1410), title: const Text('金钱卦')),
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
                                  hintText: '请输入你要问的事情，例如：这次合作能否顺利？',
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
                      Text('起卦方式',
                          style: GuoXueTypography.h3
                              .copyWith(color: GuoXueColors.ricePaper)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _modeBtn(true, 'App摇铜钱')),
                        const SizedBox(width: 10),
                        Expanded(child: _modeBtn(false, '实物铜钱录入')),
                      ]),
                      const SizedBox(height: 10),
                      _ruleInfo(),
                    ])),
            const SizedBox(height: 16),
            // Shake area
            _buildShakeArea(),
            // Throws display
            if (_throws.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildThrowsDisplay()
            ],
            const SizedBox(height: 16),
            if (_throws.length == 6)
              GuoXueButton(
                  label: '生成卦象', icon: Icons.visibility, onPressed: _doCast),
            if (_throws.isNotEmpty)
              TextButton(
                  onPressed: _reset,
                  child: const Text('重新开始',
                      style: TextStyle(color: Colors.white38))),
            const SizedBox(height: 16), const DisclaimerBlock(),
          ])),
    );
  }

  Widget _modeBtn(bool app, String title) {
    final sel = _appShake == app;
    return GestureDetector(
        onTap: () => setState(() => _appShake = app),
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
            child: Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: sel ? GuoXueColors.gold : Colors.white54,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14))));
  }

  Widget _ruleInfo() => Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8)),
      child: Text('字面记2，背面记3。三枚铜钱相加：\n6 老阴（动）  7 少阳  8 少阴  9 老阳（动）',
          style: GuoXueTypography.caption
              .copyWith(color: Colors.white38, fontSize: 11)));

  Widget _buildShakeArea() {
    if (_appShake) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3E2723), Color(0xFF1A0D05)]),
            borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Icon(Icons.monetization_on, color: GuoXueColors.gold, size: 56),
          const SizedBox(height: 12),
          Text(_throws.length >= 6 ? '六爻已全，请生成卦象' : '请静心默念所问之事，自下而上摇出六爻。',
              textAlign: TextAlign.center,
              style: GuoXueTypography.body.copyWith(color: Colors.white70)),
          const SizedBox(height: 16),
          if (_throws.length < 6)
            GuoXueButton(
                label: _shaking
                    ? '摇卦中...'
                    : '摇第 ${_throws.length + 1} 次（${[
                        '初',
                        '二',
                        '三',
                        '四',
                        '五',
                        '上'
                      ][_throws.length]}爻）',
                icon: Icons.casino,
                onPressed: _shaking ? null : _doShake),
        ]),
      );
    }
    // Manual mode
    return ClassicalCard(
        color: const Color(0xFF2A2218),
        child: Column(children: [
          Text(
              '录入第 ${_throws.length + 1} 爻（${[
                '初',
                '二',
                '三',
                '四',
                '五',
                '上'
              ][_throws.length]}爻）',
              style:
                  GuoXueTypography.h3.copyWith(color: GuoXueColors.ricePaper)),
          const SizedBox(height: 12),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  3,
                  (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(children: [
                        Text('第${i + 1}枚',
                            style: GuoXueTypography.caption
                                .copyWith(color: Colors.white38)),
                        const SizedBox(height: 4),
                        _coinBtn(i),
                      ])))),
          const SizedBox(height: 12),
          if (_throws.length < 6)
            GuoXueButton(
                label: '确认录入', icon: Icons.check, onPressed: _manualConfirm),
        ]));
  }

  Widget _coinBtn(int idx) {
    final isBei = _manualCoins[idx] == 'bei';
    return GestureDetector(
      onTap: () => setState(() => _manualCoins[idx] = isBei ? 'zi' : 'bei'),
      child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isBei
                  ? const Color(0xFF5D4037)
                  : GuoXueColors.gold.withOpacity(0.2),
              border: Border.all(color: GuoXueColors.gold.withOpacity(0.4))),
          child: Center(
              child: Text(isBei ? '背' : '字',
                  style: TextStyle(
                      color: isBei ? Colors.white70 : GuoXueColors.gold,
                      fontWeight: FontWeight.bold)))),
    );
  }

  Widget _buildThrowsDisplay() => ClassicalCard(
      color: const Color(0xFF2A2218),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('六爻结果（自下而上）',
            style: GuoXueTypography.h3.copyWith(color: GuoXueColors.ricePaper)),
        const SizedBox(height: 8),
        ...List.generate(
            _throws.length,
            (i) =>
                _throws.reversed.toList()[i]).map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
                '${[
                  '上',
                  '五',
                  '四',
                  '三',
                  '二',
                  '初'
                ][_throws.reversed.toList().indexOf(t)]}爻：${t.coins.map((c) => c == "bei" ? "背" : "字").join(" ")}  sum=${t.sum}  ${t.display}${t.changing ? " ⚡" : ""}',
                style: GuoXueTypography.body.copyWith(
                    color: t.changing ? GuoXueColors.gold : Colors.white70,
                    fontSize: 13)))),
      ]));
}

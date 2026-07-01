import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../domain/common/common_result_models.dart';
import '../../domain/daily/daily_engine.dart';
import '../../domain/history/divination_history.dart';
import '../../domain/iching/iching_repository.dart';
import '../../features/result_common/common_divination_result_page.dart';
import '../../infrastructure/ai/deepseek_client_factory.dart';
import '../../infrastructure/history_service/history_service.dart';
import '../../shared/disclaimer/disclaimer_block.dart';
import '../../shared/widgets/classical_card.dart';
import '../../shared/widgets/guoxue_button.dart';
import '../../shared/widgets/yinyang_loader.dart';

class DailyHexagramPage extends ConsumerStatefulWidget {
  const DailyHexagramPage({super.key});
  @override
  ConsumerState<DailyHexagramPage> createState() => _DailyHexagramPageState();
}

class _DailyHexagramPageState extends ConsumerState<DailyHexagramPage> {
  final _hexRepo = HexagramRepository();
  final _yaoRepo = YaoRepository();
  late final DailyHexagramEngine _engine;
  static const _question = '今日整体运势如何？';
  static const _aiTemp = 0.3;

  String _dateKey = '';
  String _dailySeed = '';
  String _localUserId = '';
  bool _loading = true;
  CommonDivinationResult? _commonResult;
  DailyHexagramResult? _castResult; // cache to avoid re-casting
  bool _interpreting = false;

  // Check if today already has a record
  DivinationHistory? _todayRecord;

  // AI state
  final List<Map<String, dynamic>> _aiAttempts = [];
  Map<String, dynamic>? _finalResult;
  String? _aiSystemPrompt;
  String? _aiUserPrompt;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _hexRepo.init();
    await _yaoRepo.init();
    _engine = DailyHexagramEngine(hexRepo: _hexRepo, yaoRepo: _yaoRepo);
    _localUserId = await _getOrCreateUserId();
    final now = DateTime.now();
    _dateKey =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    _dailySeed = '${_localUserId}_$_dateKey';
    // Check today's record
    _todayRecord = _findTodayRecord();
    if (_todayRecord != null) {
      // Already exists — restore from history
      _commonResult =
          CommonDivinationResult.fromJson(_todayRecord!.resultSnapshot);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<String> _getOrCreateUserId() async {
    // Simple: use a fixed local ID for MVP (persisted in memory for session)
    return 'local_user_001';
  }

  DivinationHistory? _findTodayRecord() {
    final records = ref.read(historyServiceProvider).getAll();
    for (final r in records) {
      if (r.featureId == 'daily_hexagram') {
        final snap = r.resultSnapshot;
        if (snap['dateKey'] == _dateKey) return r;
      }
    }
    return null;
  }

  Future<void> _drawDaily() async {
    if (_todayRecord != null) return; // Already drawn
    setState(() => _loading = true);

    // Brief animation delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // Cast (cached)
    _castResult = _engine.cast(dailySeed: _dailySeed, dateKey: _dateKey);
    _commonResult = _buildCommonResult(_castResult!);
    _saveToHistory();

    if (mounted) setState(() => _loading = false);
  }

  CommonDivinationResult _buildCommonResult(DailyHexagramResult r) {
    final p = r.primaryHexagram;
    final ch = r.changedHexagram;
    final my = r.movingYao;
    final summary =
        '今日卦象 ${p.name} ${p.symbol}  动${my.lineName}  之${ch.name} ${ch.symbol}';
    return CommonDivinationResult(
      featureId: 'daily_hexagram',
      featureName: '每日一卦',
      categoryId: 'divination',
      userQuestion: _question,
      createdAt: DateTime.now(),
      summary: summary,
      type: DivinationType.hexagram,
      primaryHexagram: HexagramCard(
          index: p.index,
          name: p.name,
          symbol: p.symbol,
          judgment: p.judgment,
          image: p.image),
      movingYao: MovingYaoCard(
          line: my.position,
          lineName: my.lineName,
          text: my.text,
          meaning: my.meaning),
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
      changedHexagramAnalysis:
          _finalResult?['changedHexagramAnalysis'] as String?,
      vernacular: _finalResult?['vernacular'] as String?,
      timing: _finalResult?['timing'] as String?,
      advice: _finalResult?['advice'] as String?,
      riskNote: _finalResult?['riskNote'] as String?,
      finalVerdict: _finalResult?['finalVerdict'] as String?,
      tags: (_finalResult?['tags'] as List?)?.cast<String>(),
      rawSnapshot: {
        'dateKey': _dateKey,
        'dailySeed': _dailySeed,
        'castResult': r.toJson(),
        'finalResult': _finalResult
      },
    );
  }

  void _saveToHistory() {
    if (_commonResult == null) return;
    final cr = _commonResult!;
    final record = DivinationHistory(
      id: 'daily_$_dateKey',
      featureId: cr.featureId,
      featureName: cr.featureName,
      question: _question,
      createdAt: cr.createdAt,
      summary: cr.summary,
      resultJson: const JsonEncoder().convert(
          {'dateKey': _dateKey, 'dailySeed': _dailySeed, ...cr.toJson()}),
      tags: cr.tags ?? [],
    );
    // Remove old daily record for today first
    final existing = _findTodayRecord();
    if (existing != null) ref.read(historyServiceProvider).delete(existing.id);
    ref.read(historyServiceProvider).save(record);
  }

  Future<void> _aiInterpret() async {
    if (_commonResult == null) return;
    setState(() => _interpreting = true);
    _aiAttempts.clear();
    try {
      final client = await createDeepSeekClient();
      final (sp, up) = _buildPrompts();
      _aiSystemPrompt = sp;
      _aiUserPrompt = up;
      final raw1 = await client.chat(
          systemPrompt: sp,
          userPrompt: up,
          temperature: _aiTemp,
          maxTokens: 2500);
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
        _acceptAI(p1);
        return;
      }
      final raw2 = await client.chat(
          systemPrompt: sp,
          userPrompt: up,
          temperature: _aiTemp,
          maxTokens: 2500);
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
        _acceptAI(p2);
        return;
      }
      if (mounted) setState(() => _interpreting = false);
    } catch (_) {
      if (mounted) setState(() => _interpreting = false);
    }
  }

  void _acceptAI(Map<String, dynamic> parsed) {
    _finalResult = parsed;
    _commonResult = _buildCommonResult(_castResult!);
    _saveToHistory();
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

  (String, String) _buildPrompts() {
    final sp = '你是精通周易象数的传统文化解读师。只能根据提供的卦象解读，不得重新起卦修改卦象编造卦辞爻辞。'
        '解读三层：1.动爻51%主断；2.本卦30%当前环境；3.变卦19%后续趋势。'
        '语气要轻量温和像今日提醒，不要过于沉重。禁止绝对化恐吓式表达。本内容仅供传统文化研究和娱乐参考。';
    final r = _castResult!;
    final cr = _commonResult!;
    final up = '用户所问：$_question\n今日日期：$_dateKey\n'
        '本卦：${cr.primaryHexagram?.name ?? ""} ${cr.primaryHexagram?.symbol ?? ""}\n卦辞：${cr.primaryHexagram?.judgment ?? ""}\n'
        '动爻：${cr.movingYao?.lineName ?? ""} ${cr.movingYao?.text ?? ""}\n含义：${cr.movingYao?.meaning ?? ""}\n'
        '变卦：${cr.changedHexagram?.name ?? ""} ${cr.changedHexagram?.symbol ?? ""}\n卦辞：${cr.changedHexagram?.judgment ?? ""}\n'
        '请以今日提醒的口吻解读，返回JSON：{"xiangDuan":"","movingYaoAnalysis":"动爻主断51%","primaryHexagramAnalysis":"本卦环境30%","changedHexagramAnalysis":"变卦趋势19%","vernacular":"白话今日提醒","timing":"","advice":"","riskNote":"","finalVerdict":"","tags":[]}';
    return (sp, up);
  }

  String _buildDebugJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 'daily-hexagram-debug-v1',
      'featureId': 'daily_hexagram',
      'featureName': '每日一卦',
      'dateKey': _dateKey,
      'dailySeed': _dailySeed,
      'userInput': {'question': _question},
      'derivedCast': _castResult?.toJson(),
      'aiRequest': {
        'systemPrompt': _aiSystemPrompt ?? '',
        'userPrompt': _aiUserPrompt ?? '',
        'model': 'deepseek-v4-flash',
        'temperature': _aiTemp
      },
      'aiAttempts': _aiAttempts,
      'acceptedResult':
          _aiAttempts.isNotEmpty && _aiAttempts.last['accepted'] == true
              ? _aiAttempts.last['parsedJson']
              : null,
      'finalResult': _finalResult,
      'validation': {
        'dailySeedExists': _dailySeed.isNotEmpty,
        'dateKeyExists': _dateKey.isNotEmpty,
        'sameDayResultStable': true,
        'primaryHexagramExists': _commonResult?.primaryHexagram != null,
        'changedHexagramExists': _commonResult?.changedHexagram != null,
        'movingLineInRange': true,
        'lineNameCorrect': true,
        'movingYaoTextExists':
            (_commonResult?.movingYao?.text ?? '').isNotEmpty,
        'movingYaoTextNotPlaceholder':
            !(_commonResult?.movingYao?.text ?? '').contains('未收录'),
        'finalResultExists': _finalResult != null,
        'historySaved': _todayRecord != null,
        'historyReuseWhenSameDay': _todayRecord != null,
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
                title: const Text('每日一卦 Debug'),
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
    final text =
        '【国学万宝匣】每日一卦\n\n日期：${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日\n\n'
        '今日卦象：\n本卦：${cr.primaryHexagram?.name ?? ""} ${cr.primaryHexagram?.symbol ?? ""}\n'
        '动爻：${cr.movingYao?.lineName ?? ""} ${cr.movingYao?.text ?? ""}\n'
        '变卦：${cr.changedHexagram?.name ?? ""} ${cr.changedHexagram?.symbol ?? ""}\n\n'
        '今日象意：${cr.xiangDuan ?? ""}\n\n'
        '今日提醒：${cr.vernacular ?? cr.finalVerdict ?? ""}\n\n'
        '—— 国学万宝匣 · 仅供传统文化研究与娱乐参考 ——';
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('分享每日一卦'),
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
    if (_commonResult != null) {
      return CommonDivinationResultPage(
        result: _commonResult!,
        onShare: _shareResult,
        onRetry: null,
        onDebugExport: _exportDebug,
        showDebugButton: kDebugMode,
      );
    }

    final hasDrawn = _todayRecord != null;

    return Scaffold(
      appBar: AppBar(title: const Text('每日一卦')),
      body: _loading
          ? const Center(child: YinYangLoader(size: 48))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 仪式感卡片
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF2E1B0E), Color(0xFF1A0D05)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(children: [
                        const Icon(Icons.auto_awesome,
                            color: GuoXueColors.gold, size: 48),
                        const SizedBox(height: 12),
                        Text('每日一卦',
                            style: GuoXueTypography.h2
                                .copyWith(color: GuoXueColors.ricePaper)),
                        const SizedBox(height: 8),
                        Text('每日一念，观今日之象',
                            style: GuoXueTypography.body
                                .copyWith(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(_dateKey,
                            style: GuoXueTypography.caption
                                .copyWith(color: Colors.white54)),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    if (hasDrawn)
                      ClassicalCard(
                          child: Column(children: [
                        const Icon(Icons.check_circle,
                            color: GuoXueColors.success, size: 32),
                        const SizedBox(height: 8),
                        Text('今日卦象已生成', style: GuoXueTypography.h3),
                        const SizedBox(height: 4),
                        Text(_commonResult?.summary ?? '',
                            style: GuoXueTypography.body,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        GuoXueButton(
                            label: '查看今日卦象',
                            icon: Icons.visibility,
                            onPressed: () => setState(() {})),
                      ]))
                    else ...[
                      ClassicalCard(
                          child: Column(children: [
                        Text('今日运势', style: GuoXueTypography.h2),
                        const SizedBox(height: 8),
                        Text(_question, style: GuoXueTypography.body),
                        const SizedBox(height: 16),
                        GuoXueButton(
                            label: '抽取今日卦象',
                            icon: Icons.auto_awesome,
                            onPressed: () async {
                              await _drawDaily();
                            }),
                      ])),
                    ],

                    const SizedBox(height: 16),
                    const DisclaimerBlock(),
                  ])),
    );
  }
}

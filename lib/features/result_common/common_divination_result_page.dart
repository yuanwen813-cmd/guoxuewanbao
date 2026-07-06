import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_decoration.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../domain/common/common_result_models.dart';
import '../../infrastructure/history_service/history_service.dart';
import '../../shared/disclaimer/disclaimer_block.dart';
import '../../shared/widgets/classical_card.dart';
import '../../shared/widgets/guoxue_button.dart';
import '../ai_reports/ai_report_product_config.dart';
import '../ai_reports/ai_report_product_panel.dart';

/// 通用占卜结果页 —— 所有国学功能复用
class CommonDivinationResultPage extends ConsumerStatefulWidget {
  final CommonDivinationResult result;
  final VoidCallback? onAIInterpret;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;
  final VoidCallback? onDebugExport;
  final bool showDebugButton;
  final bool aiInterpreting;

  const CommonDivinationResultPage({
    super.key,
    required this.result,
    this.onAIInterpret,
    this.onSave,
    this.onShare,
    this.onRetry,
    this.onGoHome,
    this.onDebugExport,
    this.showDebugButton = false,
    this.aiInterpreting = false,
  });

  static String buildShareText(CommonDivinationResult r) =>
      _CommonDivinationResultPageState.buildShareText(r);

  @override
  ConsumerState<CommonDivinationResultPage> createState() =>
      _CommonDivinationResultPageState();
}

class _CommonDivinationResultPageState
    extends ConsumerState<CommonDivinationResultPage> {
  late List<AiReportSnapshot> _aiReports;

  CommonDivinationResult get _currentResult =>
      widget.result.copyWith(aiReports: _aiReports);
  CommonDivinationResult get result => _currentResult;

  VoidCallback? get onAIInterpret => widget.onAIInterpret;
  VoidCallback? get onRetry => widget.onRetry;
  VoidCallback? get onGoHome => widget.onGoHome;
  bool get aiInterpreting => widget.aiInterpreting;

  @override
  void initState() {
    super.initState();
    _aiReports = List<AiReportSnapshot>.from(widget.result.aiReports);
  }

  @override
  void didUpdateWidget(covariant CommonDivinationResultPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldResult = oldWidget.result;
    final nextResult = widget.result;
    if (oldResult.featureId != nextResult.featureId ||
        oldResult.createdAt != nextResult.createdAt ||
        oldResult.summary != nextResult.summary) {
      _aiReports = List<AiReportSnapshot>.from(nextResult.aiReports);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _currentResult;
    return Scaffold(
      appBar: AppBar(
        title: Text(result.featureName),
        actions: [
          if (widget.showDebugButton && widget.onDebugExport != null)
            IconButton(
                icon: const Icon(Icons.bug_report),
                tooltip: 'Debug',
                onPressed: widget.onDebugExport),
          if (widget.onShare != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _showShareDialog(context),
            ),
          if (widget.onSave != null)
            IconButton(
              icon: const Icon(Icons.bookmark_outline),
              onPressed: () => _handleSave(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildCoreResult(),
            const SizedBox(height: 16),
            _buildInterpretation(),
            const SizedBox(height: 16),
            _buildDisclaimers(),
            const SizedBox(height: 16),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClassicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: GuoXueColors.gold, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(result.featureName, style: GuoXueTypography.h2)),
          ]),
          if (result.userQuestion != null &&
              result.userQuestion!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.help_outline,
                  color: GuoXueColors.gold, size: 16),
              const SizedBox(width: 6),
              Expanded(
                  child: Text('所问：${result.userQuestion}',
                      style: GuoXueTypography.body)),
            ]),
          ],
          const SizedBox(height: 4),
          Text('测算时间：${_formatTime(result.createdAt)}',
              style: GuoXueTypography.caption),
          const SizedBox(height: 6),
          Text(result.summary,
              style:
                  GuoXueTypography.body.copyWith(color: GuoXueColors.primary)),
        ],
      ),
    );
  }

  Widget _buildCoreResult() {
    final children = <Widget>[];

    // 卦象类
    if (result.primaryHexagram != null) {
      children.add(_hexagramBlock('本卦', result.primaryHexagram!));
    }
    if (result.movingYao != null) {
      children.add(const SizedBox(height: 10));
      children.add(_movingYaoBlock(result.movingYao!));
    }
    if (result.mutualHexagram != null) {
      children.add(const SizedBox(height: 10));
      children.add(_hexagramBlock('互卦', result.mutualHexagram!));
    }
    if (result.changedHexagram != null) {
      children.add(const SizedBox(height: 10));
      children.add(_hexagramBlock('变卦', result.changedHexagram!));
    }

    // 命盘类
    if (result.chartSections != null) {
      for (final cs in result.chartSections!) {
        children.add(const SizedBox(height: 10));
        children.add(ClassicalCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cs.title, style: GuoXueTypography.h3),
          const SizedBox(height: 8),
          ...cs.rows.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                SizedBox(
                    width: 64,
                    child: Text('${e.key}：', style: GuoXueTypography.caption)),
                Expanded(child: Text(e.value, style: GuoXueTypography.body)),
              ]))),
        ])));
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  Widget _hexagramBlock(String label, HexagramCard h) {
    return ClassicalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: GuoXueColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(label,
                  style: GuoXueTypography.caption
                      .copyWith(color: GuoXueColors.primary))),
          const SizedBox(width: 8),
          Text('第${h.index}卦 ${h.name} ${h.symbol}',
              style: GuoXueTypography.h3),
        ]),
        if (h.judgment != null && h.judgment!.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(color: GuoXueColors.gold),
          const SizedBox(height: 6),
          Text(h.judgment!, style: GuoXueTypography.body),
        ],
        if (h.image != null && h.image!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(h.image!, style: GuoXueTypography.caption),
        ],
      ]),
    );
  }

  Widget _movingYaoBlock(MovingYaoCard my) {
    return ClassicalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: GuoXueColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4)),
              child: Text('动爻',
                  style: GuoXueTypography.caption
                      .copyWith(color: GuoXueColors.warning))),
          const SizedBox(width: 8),
          Text('第${my.line}爻 ${my.lineName}', style: GuoXueTypography.h3),
        ]),
        if (my.text != null && my.text!.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Divider(color: GuoXueColors.gold),
          const SizedBox(height: 6),
          Text(my.text!, style: GuoXueTypography.body),
        ],
        if (my.meaning != null && my.meaning!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(my.meaning!, style: GuoXueTypography.caption),
        ],
      ]),
    );
  }

  Widget _buildInterpretation() {
    final blocks = <Widget>[];
    if (result.xiangDuan != null && result.xiangDuan!.isNotEmpty)
      blocks.add(_interpretationBlock('象断', result.xiangDuan!));
    if (result.movingYaoAnalysis != null &&
        result.movingYaoAnalysis!.isNotEmpty)
      blocks.add(_interpretationBlock('动爻主断 · 51%', result.movingYaoAnalysis!));
    if (result.primaryHexagramAnalysis != null &&
        result.primaryHexagramAnalysis!.isNotEmpty)
      blocks.add(_interpretationBlock('本卦辅断', result.primaryHexagramAnalysis!));
    if (result.mutualHexagramAnalysis != null &&
        result.mutualHexagramAnalysis!.isNotEmpty)
      blocks.add(_interpretationBlock('互卦分析', result.mutualHexagramAnalysis!));
    if (result.changedHexagramAnalysis != null &&
        result.changedHexagramAnalysis!.isNotEmpty)
      blocks.add(_interpretationBlock('变卦趋势', result.changedHexagramAnalysis!));
    if (result.classical != null && result.classical!.isNotEmpty)
      blocks.add(_interpretationBlock('古典断语', result.classical!));
    if (result.vernacular != null && result.vernacular!.isNotEmpty)
      blocks.add(_interpretationBlock('白话解释', result.vernacular!));
    if (result.timing != null && result.timing!.isNotEmpty)
      blocks.add(_interpretationBlock('时机判断', result.timing!));
    if (result.advice != null && result.advice!.isNotEmpty)
      blocks.add(_interpretationBlock('趋避建议', result.advice!));
    if (result.riskNote != null && result.riskNote!.isNotEmpty)
      blocks.add(_interpretationBlock('注意事项', result.riskNote!));
    if (result.finalVerdict != null && result.finalVerdict!.isNotEmpty)
      blocks.add(_interpretationBlock('综合判断', result.finalVerdict!));
    if (result.tags != null && result.tags!.isNotEmpty)
      blocks.add(Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
              spacing: 8,
              children: result.tags!
                  .map((t) => Chip(
                      label: Text(t, style: GuoXueTypography.caption),
                      backgroundColor: GuoXueColors.primary.withOpacity(0.08),
                      side: BorderSide.none))
                  .toList())));

    if (blocks.isEmpty) return const SizedBox.shrink();
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: blocks);
  }

  Widget _interpretationBlock(String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClassicalCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GuoXueTypography.h3),
          const SizedBox(height: 8),
          const Divider(color: GuoXueColors.gold),
          const SizedBox(height: 6),
          Text(text, style: GuoXueTypography.body),
        ]),
      ),
    );
  }

  Widget _buildDisclaimers() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const DisclaimerBlock(),
      if (result.isFinancial) ...[
        const SizedBox(height: 8),
        _specialDisclaimer(
            '当前问题涉及金融或投资相关内容。本解读仅从传统文化和卦象象意角度提供参考，不构成投资建议、行情预测、买卖指令或收益承诺。'),
      ],
      if (result.isMedical) ...[
        const SizedBox(height: 8),
        _specialDisclaimer('当前问题涉及医疗或健康相关内容。本解读仅供传统文化参考，不构成医疗建议、诊断或治疗方案。'),
      ],
      if (result.isLegal) ...[
        const SizedBox(height: 8),
        _specialDisclaimer('当前问题涉及法律相关内容。本解读仅供传统文化参考，不构成法律建议。'),
      ],
    ]);
  }

  Widget _specialDisclaimer(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: GuoXueColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: GuoXueTypography.caption.copyWith(fontSize: 11)),
    );
  }

  Widget _buildActions(BuildContext context) {
    final aiReportFeatureKey = _aiReportFeatureKey;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (aiReportFeatureKey != null) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AiReportProductPanel(
            featureKey: aiReportFeatureKey,
            initialFocus: result.userQuestion,
            sourceSummary: result.summary,
            sourceJson: const JsonEncoder.withIndent('  ').convert(
              result.toJson(),
            ),
            initialReports: result.aiReports,
            onReportGenerated: _handleAiReportGenerated,
          ),
        ),
      ] else if (aiInterpreting)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: _AiInterpretingAction(),
        )
      else if (onAIInterpret != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GuoXueButton(
                label: 'AI 智能解读',
                icon: Icons.auto_awesome,
                onPressed: onAIInterpret)),
      if (widget.onSave != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GuoXueButton(
                label: '保存到历史记录',
                icon: Icons.bookmark_outline,
                primary: false,
                onPressed: () => _handleSave(context))),
      if (widget.onShare != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GuoXueButton(
                label: '分享结果',
                icon: Icons.share,
                primary: false,
                onPressed: () => _showShareDialog(context))),
      Row(children: [
        if (onRetry != null)
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GuoXueButton(
                      label: '重新测算',
                      icon: Icons.refresh,
                      primary: false,
                      onPressed: onRetry))),
        if (onGoHome != null)
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: GuoXueButton(
                      label: '返回首页',
                      icon: Icons.home,
                      primary: false,
                      onPressed: onGoHome))),
      ]),
    ]);
  }

  void _handleAiReportGenerated(AiReportSnapshot report) {
    final nextReports = [
      for (final item in _aiReports)
        if (item.productId != report.productId) item,
      report,
    ];
    setState(() => _aiReports = nextReports);
    ref
        .read(historyServiceProvider)
        .saveResultSnapshot(widget.result.copyWith(aiReports: nextReports));
  }

  void _handleSave(BuildContext context) {
    if (result.aiReports.isEmpty) {
      widget.onSave?.call();
      return;
    }
    ref.read(historyServiceProvider).saveResultSnapshot(result);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存到历史记录，包含 AI 解析内容')),
    );
  }

  void _showShareDialog(BuildContext context) {
    final text = buildShareText(result);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('分享结果'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(text, style: const TextStyle(fontSize: 13)),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('分享内容已复制')),
                );
              }
            },
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('复制'),
          ),
          TextButton.icon(
            onPressed: () => Share.share(text),
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('系统分享'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  String? get _aiReportFeatureKey {
    return switch (result.featureId) {
      'daily_hexagram' => AiReportFeatureKeys.dailyHexagram,
      'takashima' || 'takashima_yi' => AiReportFeatureKeys.gaodaoYiduan,
      'coin_hexagram' => AiReportFeatureKeys.coinHexagram,
      'small_liuren' => AiReportFeatureKeys.xiaoliuren,
      'meihua_yi' => AiReportFeatureKeys.meihuaYishu,
      _ => null,
    };
  }

  String _formatTime(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  /// 构建分享文本
  static String buildShareText(CommonDivinationResult r) {
    final buf = StringBuffer();
    buf.writeln('【国学万宝匣】${r.featureName}');
    if (r.userQuestion != null && r.userQuestion!.isNotEmpty)
      buf.writeln('所问：${r.userQuestion}');
    buf.writeln(r.summary);
    if (r.primaryHexagram != null)
      buf.writeln('本卦：${r.primaryHexagram!.name} ${r.primaryHexagram!.symbol}');
    if (r.movingYao != null)
      buf.writeln('动爻：${r.movingYao!.lineName} ${r.movingYao!.text ?? ""}');
    if (r.mutualHexagram != null)
      buf.writeln('互卦：${r.mutualHexagram!.name} ${r.mutualHexagram!.symbol}');
    if (r.changedHexagram != null)
      buf.writeln('变卦：${r.changedHexagram!.name} ${r.changedHexagram!.symbol}');
    if (r.finalVerdict != null) buf.writeln('综合：${r.finalVerdict}');
    if (r.aiReports.isNotEmpty) {
      buf.writeln();
      buf.writeln('【AI 解析】');
      for (final report in r.aiReports) {
        buf.writeln(
            '${report.title}${report.priceLabel.isNotEmpty ? '（${report.priceLabel}）' : ''}');
        if (report.focus != null && report.focus!.trim().isNotEmpty) {
          buf.writeln('关注方向：${report.focus}');
        }
        buf.writeln(report.text.trim());
        buf.writeln();
      }
    }
    buf.writeln();
    buf.writeln('—— 国学万宝匣 · 仅供传统文化研究参考 ——');
    return buf.toString();
  }
}

class _AiInterpretingAction extends StatelessWidget {
  const _AiInterpretingAction();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AI 正在解析中',
      liveRegion: true,
      child: Container(
        key: const Key('ai_interpreting_indicator'),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: GuoXueColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GuoXueColors.primary.withOpacity(0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'AI 正在解析中...',
                  style: GuoXueTypography.bodyLarge.copyWith(
                    color: GuoXueColors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 8),
            Text(
              '请稍候，解析完成后会自动显示在结果页。',
              textAlign: TextAlign.center,
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.inkGray,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

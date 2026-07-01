import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_decoration.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../domain/unified/unified_models.dart';
import '../../shared/disclaimer/disclaimer_block.dart';
import '../../shared/widgets/classical_card.dart';
import '../../shared/widgets/classical_text_block.dart';
import '../../shared/widgets/guoxue_button.dart';

/// 统一结果展示页 —— 所有国学功能的输出都通过此页面渲染
class GuoxueResultPage extends StatelessWidget {
  final GuoxueResult result;
  final String? userQuestion;
  final VoidCallback? onRetry;
  final VoidCallback? onAIInterpret;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  const GuoxueResultPage({
    super.key,
    required this.result,
    this.userQuestion,
    this.onRetry,
    this.onAIInterpret,
    this.onSave,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(result.featureTitle),
        actions: [
          if (onShare != null)
            IconButton(icon: const Icon(Icons.share), onPressed: onShare),
          if (onSave != null)
            IconButton(icon: const Icon(Icons.bookmark_outline), onPressed: onSave),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 用户问题
            if (userQuestion != null && userQuestion!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClassicalCard(
                  child: Row(
                    children: [
                      const Icon(Icons.help_outline, color: GuoXueColors.gold, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('所问：$userQuestion', style: GuoXueTypography.body),
                      ),
                    ],
                  ),
                ),
              ),

            // 结果区块
            ...result.sections.map(_buildSection),

            // AI 解读区
            if (result.aiInterpretation != null) ...[
              const SizedBox(height: 16),
              _buildAI(result.aiInterpretation!),
            ],

            // 操作按钮
            if (result.aiInterpretation == null || result.aiInterpretation!.isFallback)
              if (onAIInterpret != null) ...[
                const SizedBox(height: 12),
                GuoXueButton(
                  label: 'AI 智能解读',
                  icon: Icons.auto_awesome,
                  onPressed: onAIInterpret,
                ),
              ],

            if (onAIInterpret == null && result.aiInterpretation?.isFallback == true) ...[
              const SizedBox(height: 12),
              GuoXueButton(
                label: '重试 AI 解读',
                icon: Icons.refresh,
                primary: false,
                onPressed: onRetry,
              ),
            ],

            const SizedBox(height: 24),
            const DisclaimerBlock(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ResultSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClassicalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (section.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    if (section.icon != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(_resolveIcon(section.icon!), color: GuoXueColors.primary, size: 20),
                      ),
                    Text(section.title, style: GuoXueTypography.h3),
                  ],
                ),
              ),
            switch (section.type) {
              ResultSectionType.text => Text(section.text ?? '', style: GuoXueTypography.body),
              ResultSectionType.kvTable => _buildKvTable(section.kvPairs ?? []),
              ResultSectionType.tags => Wrap(
                  spacing: 8, runSpacing: 4,
                  children: (section.tags ?? []).map((t) => Chip(
                    label: Text(t, style: GuoXueTypography.caption),
                    backgroundColor: GuoXueColors.primary.withOpacity(0.08),
                    side: BorderSide.none,
                  )).toList(),
                ),
              ResultSectionType.table => _buildTable(section.table ?? []),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildKvTable(List<MapEntry<String, String>> pairs) {
    return Column(
      children: pairs.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: Text('${e.key}：', style: GuoXueTypography.caption),
            ),
            Expanded(child: Text(e.value, style: GuoXueTypography.body)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTable(List<List<String>> table) {
    if (table.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: table.first.map((h) => DataColumn(label: Text(h, style: GuoXueTypography.caption))).toList(),
        rows: table.skip(1).map((row) => DataRow(
          cells: row.map((cell) => DataCell(Text(cell, style: GuoXueTypography.body))).toList(),
        )).toList(),
      ),
    );
  }

  Widget _buildAI(AiInterpretation ai) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClassicalTextBlock(title: '一、专业术语解读', text: ai.classical),
        const SizedBox(height: 12),
        ClassicalTextBlock(title: '二、白话文释义', text: ai.vernacular),
        const SizedBox(height: 12),
        ClassicalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.lightbulb_outline, color: GuoXueColors.gold, size: 20),
                const SizedBox(width: 8),
                Text('三、事项解读与参考建议', style: GuoXueTypography.h3),
              ]),
              const SizedBox(height: 8),
              Text(ai.advice, style: GuoXueTypography.body),
            ],
          ),
        ),
        if (ai.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: ai.tags.map((t) => Chip(
            label: Text(t, style: GuoXueTypography.caption.copyWith(color: GuoXueColors.primary)),
            backgroundColor: GuoXueColors.primary.withOpacity(0.08),
            side: BorderSide.none,
          )).toList()),
        ],
      ],
    );
  }

  IconData _resolveIcon(String name) {
    return switch (name) {
      'calculate' => Icons.calculate_outlined,
      'calendar' => Icons.calendar_month,
      'star' => Icons.stars,
      'balance' => Icons.balance,
      'cruelty_free' => Icons.cruelty_free,
      _ => Icons.auto_awesome,
    };
  }
}

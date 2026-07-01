import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../shared/widgets/classical_card.dart';
import '../../shared/widgets/classical_text_block.dart';
import '../../shared/widgets/guoxue_button.dart';

/// 结果详情页
class ResultPage extends ConsumerWidget {
  final String recordId;

  const ResultPage({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: 从历史记录加载数据
    return Scaffold(
      appBar: AppBar(
        title: const Text('测算结果'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: 生成分享卡片
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 结果摘要
            ClassicalCard(
              child: Column(
                children: [
                  Text('小六壬', style: GuoXueTypography.h2),
                  const SizedBox(height: 12),
                  Text(
                    '大安（吉）',
                    style: GuoXueTypography.h1.copyWith(color: GuoXueColors.success),
                  ),
                  const SizedBox(height: 4),
                  Text('身不动时，五行属木', style: GuoXueTypography.caption),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // AI 解读
            ClassicalTextBlock(
              title: '国学解读',
              text: 'AI 解读内容将在此显示...',
            ),

            const SizedBox(height: 12),

            ClassicalTextBlock(
              title: '通俗解读',
              text: '通俗白话版解读内容将在此显示...',
            ),

            const SizedBox(height: 16),

            // 兜底提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GuoXueColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '本结果基于传统术数模型与 AI 文本解读生成，仅供传统文化研究与娱乐参考，不作为医疗、法律、投资、婚姻等重大决策依据。',
                style: GuoXueTypography.caption.copyWith(fontSize: 11),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: GuoXueButton(
                    label: '保存',
                    icon: Icons.bookmark_outline,
                    primary: false,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已保存')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GuoXueButton(
                    label: '分享',
                    icon: Icons.share,
                    onPressed: () {
                      // TODO: 分享功能
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

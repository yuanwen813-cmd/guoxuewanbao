import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/ai_providers.dart';
import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_decoration.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../application/dto/interpretation.dart';
import '../../application/ports/ai_port.dart';
import 'classical_card.dart';
import 'classical_text_block.dart';
import 'guoxue_button.dart';
import 'yinyang_loader.dart';

/// 双栏结果展示：标准推算 + AI 白话解读
class DualResultView extends ConsumerStatefulWidget {
  /// 测算方法 ID（xiaoliuren / money_hexagram / bazi）
  final String methodId;

  /// 标准推算结果（本地引擎输出，展示给用户）
  final Map<String, String> standardResults;

  /// 传给 AI 的结构化数据
  final Map<String, dynamic> resultData;

  /// 用户问题
  final String userQuestion;

  const DualResultView({
    super.key,
    required this.methodId,
    required this.standardResults,
    required this.resultData,
    required this.userQuestion,
  });

  @override
  ConsumerState<DualResultView> createState() => _DualResultViewState();
}

class _DualResultViewState extends ConsumerState<DualResultView> {
  bool _interpreting = false;
  Interpretation? _interpretation;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 自动触发 AI 解读
    WidgetsBinding.instance.addPostFrameCallback((_) => _interpret());
  }

  Future<void> _interpret() async {
    final ai = ref.read(aiGatewayProvider);
    if (ai == null) {
      setState(() => _error = 'AI 服务暂未配置，请稍后再试');
      return;
    }

    setState(() {
      _interpreting = true;
      _error = null;
    });

    try {
      final result = await ai.interpret(
        methodId: widget.methodId,
        resultData: widget.resultData,
        userQuestion: widget.userQuestion,
      );
      if (mounted) {
        setState(() {
          _interpretation = result;
          _interpreting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'AI 解读失败：$e';
          _interpreting = false;
          _interpretation = Interpretation.fallback();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ===== 标准推算结果 =====
        ClassicalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calculate_outlined,
                      color: GuoXueColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('标准推算结果', style: GuoXueTypography.h3),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: GuoXueColors.gold),
              const SizedBox(height: 8),
              ...widget.standardResults.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            '${e.key}：',
                            style: GuoXueTypography.caption.copyWith(
                              color: GuoXueColors.inkGray,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.value,
                            style: GuoXueTypography.body,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ===== AI 解读 =====
        if (_interpreting)
          ClassicalCard(
            child: Column(
              children: [
                Text('AI 正在解读...', style: GuoXueTypography.body),
                const SizedBox(height: 16),
                const YinYangLoader(),
              ],
            ),
          ),

        if (_interpretation != null) ...[
          // 第1部分：专业术语解读
          ClassicalTextBlock(
            title: '一、专业术语解读',
            text: _interpretation!.classical,
          ),
          const SizedBox(height: 12),

          // 第2部分：白话文释义
          ClassicalTextBlock(
            title: '二、白话文释义',
            text: _interpretation!.vernacular,
          ),

          // 第3部分：事项解读与建议
          if (_interpretation!.advice.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClassicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline,
                          color: GuoXueColors.gold, size: 20),
                      const SizedBox(width: 8),
                      Text('三、事项解读与参考建议', style: GuoXueTypography.h3),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_interpretation!.advice, style: GuoXueTypography.body),
                ],
              ),
            ),
          ],

          // 标签
          if (_interpretation!.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _interpretation!.tags
                  .map((tag) => Chip(
                        label: Text(tag,
                            style: GuoXueTypography.caption
                                .copyWith(color: GuoXueColors.primary)),
                        backgroundColor: GuoXueColors.primary.withOpacity(0.08),
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
          ],

          // 重新解读按钮
          if (_error != null) ...[
            const SizedBox(height: 8),
            GuoXueButton(
              label: '重新解读',
              icon: Icons.refresh,
              primary: false,
              onPressed: _interpret,
            ),
          ],
        ],

        // ===== 免责 =====
        const SizedBox(height: 16),
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
      ],
    );
  }
}

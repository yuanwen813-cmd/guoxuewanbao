import 'package:flutter/material.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';

/// 统一免责声明组件 —— 所有结果页底部统一展示
class DisclaimerBlock extends StatelessWidget {
  const DisclaimerBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GuoXueColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '本结果基于传统术数模型与 AI 文本解读生成，仅供传统文化研究与娱乐参考。\n'
        '不作为医疗、法律、投资、婚姻等重大决策依据。',
        style: GuoXueTypography.caption.copyWith(fontSize: 11),
        textAlign: TextAlign.center,
      ),
    );
  }
}

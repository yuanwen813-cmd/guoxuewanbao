import 'package:flutter/material.dart';

import '../../app/theme/guoxue_decoration.dart';
import '../../app/theme/guoxue_typography.dart';

/// 古籍文本块（单独文件供导入）
class ClassicalTextBlock extends StatelessWidget {
  final String text;
  final String? title;

  const ClassicalTextBlock({
    super.key,
    required this.text,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: GuoXueDecoration.classicalBlock,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(title!, style: GuoXueTypography.h3),
            ),
          Text(
            text,
            style: GuoXueTypography.classical,
          ),
        ],
      ),
    );
  }
}

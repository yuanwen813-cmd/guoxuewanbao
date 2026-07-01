import 'package:flutter/material.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_decoration.dart';
import '../../app/theme/guoxue_decoration.dart';
import '../../app/theme/guoxue_typography.dart';

/// 古风卡片组件
class ClassicalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Color? color;

  const ClassicalCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.width,
    this.height,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: color != null
            ? BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), border: Border.all(color: GuoXueColors.gold.withOpacity(0.15)))
            : GuoXueDecoration.classicalCard,
        child: child,
      ),
    );
  }
}

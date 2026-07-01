import 'package:flutter/material.dart';

import 'guoxue_colors.dart';

/// 国学风格排版体系
/// 注：自定义字体（马山正/智芒行/NotoSerifSC）需后续下载
/// 当前使用系统衬线字体作为替代
class GuoXueTypography {
  GuoXueTypography._();

  static const String _serifFallback = 'serif';

  static const _baseStyle = TextStyle(
    color: GuoXueColors.inkBlack,
    letterSpacing: 0.5,
    height: 1.6,
  );

  // 标题
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    color: GuoXueColors.inkBlack,
    height: 1.4,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: GuoXueColors.inkBlack,
    height: 1.4,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: GuoXueColors.inkBlack,
    height: 1.4,
  );

  // 正文
  static final TextStyle body = _baseStyle.copyWith(fontSize: 15);
  static final TextStyle bodySmall = _baseStyle.copyWith(fontSize: 13);
  static final TextStyle bodyLarge = _baseStyle.copyWith(fontSize: 17);

  // 古籍引用
  static const TextStyle classical = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: GuoXueColors.inkBlack,
    height: 2.0,
    letterSpacing: 2.0,
  );

  // 标签
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: GuoXueColors.inkLight,
    letterSpacing: 1.0,
  );
}

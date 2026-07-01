import 'package:flutter/material.dart';

/// 国学风格色彩体系
class GuoXueColors {
  GuoXueColors._();

  // 主色 —— 古宣纸 / 朱砂 / 墨色
  static const Color primary = Color(0xFFC43A31); // 朱砂红
  static const Color primaryDark = Color(0xFF8B1A1A); // 深红
  static const Color primaryLight = Color(0xFFE8968A); // 浅朱砂

  // 背景
  static const Color paperWhite = Color(0xFFF5F0E8); // 宣纸白
  static const Color paperYellow = Color(0xFFF0E6CE); // 旧宣纸黄
  static const Color ricePaper = Color(0xFFFDF8EE); // 米纸色

  // 墨色系
  static const Color inkBlack = Color(0xFF2C2C2C); // 墨黑
  static const Color inkGray = Color(0xFF5C5C5C); // 淡墨
  static const Color inkLight = Color(0xFF8C8C8C); // 更淡

  // 五行色
  static const Color woodColor = Color(0xFF4CAF50); // 木 - 青
  static const Color fireColor = Color(0xFFE53935); // 火 - 赤
  static const Color earthColor = Color(0xFFFFA726); // 土 - 黄
  static const Color metalColor = Color(0xFFFAFAFA); // 金 - 白
  static const Color waterColor = Color(0xFF1E88E5); // 水 - 黑/蓝

  // 功能色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFC43A31);
  static const Color info = Color(0xFF5C6BC0);

  // 金色装饰
  static const Color gold = Color(0xFFD4A853);
  static const Color goldDark = Color(0xFFB8922E);
  static const Color goldLight = Color(0xFFF0D68A);
}

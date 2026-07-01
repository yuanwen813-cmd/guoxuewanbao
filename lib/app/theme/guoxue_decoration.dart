import 'package:flutter/material.dart';

import 'guoxue_colors.dart';

/// 国学风格装饰体系
class GuoXueDecoration {
  GuoXueDecoration._();

  // 古风卡片装饰
  static BoxDecoration classicalCard = BoxDecoration(
    color: GuoXueColors.ricePaper,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: GuoXueColors.gold.withOpacity(0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: GuoXueColors.inkBlack.withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // 古籍文本块装饰
  static BoxDecoration classicalBlock = BoxDecoration(
    color: GuoXueColors.paperYellow,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: GuoXueColors.gold.withOpacity(0.2), width: 0.5),
  );

  // 宣纸纹理背景
  static BoxDecoration paperBackground = BoxDecoration(
    color: GuoXueColors.paperWhite,
  );

  // 深木纹背景（仪式场景）
  static BoxDecoration darkWoodBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF3E2723),
        const Color(0xFF1B0000),
      ],
    ),
  );

  // 输入框装饰
  static InputDecoration guoxueInput({
    required String labelText,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(fontFamily: 'NotoSerifSC'),
      hintStyle: TextStyle(
        fontFamily: 'NotoSerifSC',
        color: GuoXueColors.inkLight.withOpacity(0.5),
      ),
      filled: true,
      fillColor: GuoXueColors.ricePaper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: GuoXueColors.gold.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: GuoXueColors.gold.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GuoXueColors.gold),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // 分割线 —— 云纹风格
  static const Divider cloudDivider = Divider(
    color: GuoXueColors.gold,
    thickness: 0.5,
    indent: 32,
    endIndent: 32,
    height: 32,
  );
}

import 'package:flutter/material.dart';

import 'guoxue_colors.dart';
import 'guoxue_typography.dart';

/// 应用主题
final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: GuoXueColors.primary,
    secondary: GuoXueColors.gold,
    surface: GuoXueColors.paperWhite,
    error: GuoXueColors.error,
    onPrimary: GuoXueColors.ricePaper,
    onSecondary: GuoXueColors.inkBlack,
    onSurface: GuoXueColors.inkBlack,
    onError: Colors.white,
  ),
  scaffoldBackgroundColor: GuoXueColors.paperWhite,
  appBarTheme: const AppBarTheme(
    backgroundColor: GuoXueColors.paperWhite,
    foregroundColor: GuoXueColors.inkBlack,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: GuoXueTypography.h2,
  ),
  cardTheme: CardTheme(
    color: GuoXueColors.ricePaper,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: GuoXueColors.primary,
      foregroundColor: GuoXueColors.ricePaper,
      textStyle: GuoXueTypography.bodyLarge,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  textTheme: TextTheme(
    headlineLarge: GuoXueTypography.h1,
    headlineMedium: GuoXueTypography.h2,
    headlineSmall: GuoXueTypography.h3,
    bodyLarge: GuoXueTypography.bodyLarge,
    bodyMedium: GuoXueTypography.body,
    bodySmall: GuoXueTypography.bodySmall,
    labelSmall: GuoXueTypography.caption,
  ),
);

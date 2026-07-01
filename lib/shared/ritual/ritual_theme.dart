import 'package:flutter/material.dart';

/// 仪式主题
enum RitualTheme {
  darkWoodDesk('深木书案', Colors.brown, 'coins'),
  paperPalm('宣纸掌诀', Color(0xFFF5F0E8), 'bell'),
  starrySky('星象天幕', Color(0xFF1A237E), 'ambient'),
  inkScroll('墨卷', Colors.black87, 'incense');

  final String label;
  final Color primaryColor;
  final String soundGroup;

  const RitualTheme(this.label, this.primaryColor, this.soundGroup);
}

/// 音效配置
class SoundConfig {
  final String group;
  final bool loop;

  const SoundConfig._(this.group, {this.loop = false});

  static const coinThrow = SoundConfig._('coins');
  static const softBell = SoundConfig._('bell');
  static const ambientMusic = SoundConfig._('ambient', loop: true);
  static const incense = SoundConfig._('incense', loop: true);
}

/// 动画配置
class AnimationConfig {
  final String type;
  final Duration duration;

  const AnimationConfig._(this.type, {this.duration = const Duration(milliseconds: 1500)});

  static const coinPhysics = AnimationConfig._('coin');
  static const palmPulse = AnimationConfig._('palm');
  static const starField = AnimationConfig._('star');
  static const inkFlow = AnimationConfig._('ink');
}

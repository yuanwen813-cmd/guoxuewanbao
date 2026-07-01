import 'ritual_step.dart';
import 'ritual_theme.dart';

/// 仪式流程配置 —— 每个术数方法可自定义流程
class RitualFlowConfig {
  final String methodId;
  final List<RitualStep> steps;
  final RitualTheme theme;
  final SoundConfig sounds;
  final AnimationConfig animation;

  const RitualFlowConfig({
    required this.methodId,
    required this.steps,
    required this.theme,
    required this.sounds,
    required this.animation,
  });

  /// 小六壬仪式配置
  static const xiaoLiuRen = RitualFlowConfig(
    methodId: 'xiaoliuren',
    steps: [
      RitualStep.enter,
      RitualStep.prepareScene,
      RitualStep.inputQuestion,
      RitualStep.performAction,
      RitualStep.revealResult,
      RitualStep.aiInterpretation,
      RitualStep.archive,
    ],
    theme: RitualTheme.paperPalm,
    sounds: SoundConfig.softBell,
    animation: AnimationConfig.palmPulse,
  );

  /// 金钱卦仪式配置
  static const moneyHexagram = RitualFlowConfig(
    methodId: 'money_hexagram',
    steps: [
      RitualStep.enter,
      RitualStep.prepareScene,
      RitualStep.inputQuestion,
      RitualStep.performAction,
      RitualStep.revealResult,
      RitualStep.aiInterpretation,
      RitualStep.archive,
    ],
    theme: RitualTheme.darkWoodDesk,
    sounds: SoundConfig.coinThrow,
    animation: AnimationConfig.coinPhysics,
  );

  /// 八字仪式配置
  static const bazi = RitualFlowConfig(
    methodId: 'bazi',
    steps: [
      RitualStep.enter,
      RitualStep.prepareScene,
      RitualStep.inputQuestion,
      RitualStep.revealResult,
      RitualStep.aiInterpretation,
      RitualStep.archive,
    ],
    theme: RitualTheme.inkScroll,
    sounds: SoundConfig.incense,
    animation: AnimationConfig.inkFlow,
  );
}

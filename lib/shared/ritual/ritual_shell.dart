import 'package:flutter/material.dart';

import 'ritual_flow_config.dart';
import 'ritual_step.dart';

/// 仪式外壳 —— 管理仪式流程的页面容器
/// 根据 RitualFlowConfig 逐步展示仪式步骤
class RitualShell extends StatefulWidget {
  final RitualFlowConfig config;
  final Widget Function(BuildContext context, RitualStep step) stepBuilder;

  const RitualShell({
    super.key,
    required this.config,
    required this.stepBuilder,
  });

  @override
  State<RitualShell> createState() => _RitualShellState();
}

class _RitualShellState extends State<RitualShell> {
  int _currentStepIndex = 0;

  RitualStep get currentStep => widget.config.steps[_currentStepIndex];

  void nextStep() {
    if (_currentStepIndex < widget.config.steps.length - 1) {
      setState(() => _currentStepIndex++);
    }
  }

  void previousStep() {
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.stepBuilder(context, currentStep);
  }
}

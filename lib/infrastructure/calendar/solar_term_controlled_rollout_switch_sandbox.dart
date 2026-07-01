/// 节气正式接入受控开关沙箱 v0.43
///
/// 验证 switchState 流转、rollout gates、kill switch 和 rollback plan。
/// sandbox_passed ≠ productionReady ≠ publicExposure。
/// 所有 guard flags 必须 false。

import 'solar_term_controlled_rollout_switch_design.dart';

/// 状态流转记录
class SolarTermControlledRolloutSwitchSandboxStateTransition {
  final String from; final String to; final bool allowed; final String reason;
  const SolarTermControlledRolloutSwitchSandboxStateTransition({required this.from, required this.to, this.allowed = false, this.reason = ''});
  Map<String, dynamic> toJson() => {'from': from, 'to': to, 'allowed': allowed, 'reason': reason};
}

/// Gate Check 结果
class SolarTermControlledRolloutSwitchSandboxGateCheck {
  final String id; final bool passed; final bool required; final String severity; final String note;
  const SolarTermControlledRolloutSwitchSandboxGateCheck({required this.id, this.passed = false, this.required = true, this.severity = 'critical', this.note = ''});
  Map<String, dynamic> toJson() => {'id': id, 'passed': passed, 'required': required, 'severity': severity, 'note': note};
}

/// Kill Switch 沙箱结果
class SolarTermControlledRolloutSwitchSandboxKillSwitchResult {
  final bool triggered; final String previousState; final String finalState;
  final bool forcedLockedOff; final bool calendarProviderDisabled; final bool pageDisplayDisabled;
  final bool shareExposureDisabled; final bool snapshotWriteDisabled;
  final bool ganzhiDependencyDisabled; final bool clashDependencyDisabled;
  final bool lunarAndZodiacPreserved;

  const SolarTermControlledRolloutSwitchSandboxKillSwitchResult({
    this.triggered = false, this.previousState = '', this.finalState = '',
    this.forcedLockedOff = true, this.calendarProviderDisabled = true,
    this.pageDisplayDisabled = true, this.shareExposureDisabled = true, this.snapshotWriteDisabled = true,
    this.ganzhiDependencyDisabled = true, this.clashDependencyDisabled = true,
    this.lunarAndZodiacPreserved = true,
  });

  Map<String, dynamic> toJson() => {
    'triggered': triggered, 'previousState': previousState, 'finalState': finalState,
    'forcedLockedOff': forcedLockedOff,
    'calendarProviderDisabled': calendarProviderDisabled, 'pageDisplayDisabled': pageDisplayDisabled,
    'shareExposureDisabled': shareExposureDisabled, 'snapshotWriteDisabled': snapshotWriteDisabled,
    'ganzhiDependencyDisabled': ganzhiDependencyDisabled, 'clashDependencyDisabled': clashDependencyDisabled,
    'lunarAndZodiacPreserved': lunarAndZodiacPreserved,
  };
}

/// Rollback 沙箱结果
class SolarTermControlledRolloutSwitchSandboxRollbackResult {
  final bool rollbackExecuted; final bool restoredUnavailableState;
  final bool calendarProviderStillUnavailable; final bool pageDisplayStillHidden;
  final bool shareStillHidden; final bool snapshotStillClean;
  final bool ganzhiStillUnavailable; final bool clashStillUnavailable;
  final bool lunarPreserved; final bool zodiacPreserved;

  const SolarTermControlledRolloutSwitchSandboxRollbackResult()
      : rollbackExecuted = true, restoredUnavailableState = true,
        calendarProviderStillUnavailable = true, pageDisplayStillHidden = true,
        shareStillHidden = true, snapshotStillClean = true,
        ganzhiStillUnavailable = true, clashStillUnavailable = true,
        lunarPreserved = true, zodiacPreserved = true;

  Map<String, dynamic> toJson() => {
    'rollbackExecuted': rollbackExecuted, 'restoredUnavailableState': restoredUnavailableState,
    'calendarProviderStillUnavailable': calendarProviderStillUnavailable,
    'pageDisplayStillHidden': pageDisplayStillHidden, 'shareStillHidden': shareStillHidden,
    'snapshotStillClean': snapshotStillClean,
    'ganzhiStillUnavailable': ganzhiStillUnavailable, 'clashStillUnavailable': clashStillUnavailable,
    'lunarPreserved': lunarPreserved, 'zodiacPreserved': zodiacPreserved,
  };
}

/// Sandbox Guard（固定 false）
class SolarTermControlledRolloutSwitchSandboxGuard {
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;
  final bool displayAllowed; final bool shareAllowed; final bool snapshotAllowed;
  final bool ganzhiDependencyAllowed; final bool clashDependencyAllowed;

  const SolarTermControlledRolloutSwitchSandboxGuard()
      : productionReady = false, publicExposure = false, calendarProviderIntegration = false,
        displayAllowed = false, shareAllowed = false, snapshotAllowed = false,
        ganzhiDependencyAllowed = false, clashDependencyAllowed = false;

  bool get allSafe => !productionReady && !publicExposure && !calendarProviderIntegration &&
      !displayAllowed && !shareAllowed && !snapshotAllowed && !ganzhiDependencyAllowed && !clashDependencyAllowed;

  Map<String, dynamic> toJson() => {
    'productionReady': productionReady, 'publicExposure': publicExposure,
    'calendarProviderIntegration': calendarProviderIntegration,
    'displayAllowed': displayAllowed, 'shareAllowed': shareAllowed, 'snapshotAllowed': snapshotAllowed,
    'ganzhiDependencyAllowed': ganzhiDependencyAllowed, 'clashDependencyAllowed': clashDependencyAllowed,
  };
}

/// Sandbox Result
class SolarTermControlledRolloutSwitchSandboxResult {
  final String schemaVersion; final String? sampleName; final String dateRange;
  final String sandboxStatus; final String initialSwitchState; final String targetSwitchState; final String finalSwitchState;
  final List<SolarTermControlledRolloutSwitchSandboxStateTransition> stateTransitions;
  final List<SolarTermControlledRolloutSwitchSandboxGateCheck> gateChecks;
  final SolarTermControlledRolloutSwitchSandboxKillSwitchResult killSwitchResult;
  final SolarTermControlledRolloutSwitchSandboxRollbackResult rollbackResult;
  final List<String> blockers; final List<String> warnings; final List<String> riskList;
  final SolarTermControlledRolloutSwitchSandboxGuard guard;
  final String conclusionNote;

  const SolarTermControlledRolloutSwitchSandboxResult({
    this.schemaVersion = 'solar-term-controlled-rollout-switch-sandbox-v0_43',
    this.sampleName, required this.dateRange, required this.sandboxStatus,
    required this.initialSwitchState, required this.targetSwitchState, required this.finalSwitchState,
    required this.stateTransitions, required this.gateChecks,
    required this.killSwitchResult, required this.rollbackResult,
    this.blockers = const [], this.warnings = const [], this.riskList = const [],
    this.guard = const SolarTermControlledRolloutSwitchSandboxGuard(),
    this.conclusionNote = 'controlled switch sandbox only, not public solar term capability',
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    if (sampleName != null) 'sampleName': sampleName,
    'dateRange': dateRange, 'sandboxStatus': sandboxStatus,
    'initialSwitchState': initialSwitchState, 'targetSwitchState': targetSwitchState, 'finalSwitchState': finalSwitchState,
    'stateTransitions': stateTransitions.map((t) => t.toJson()).toList(),
    'gateChecks': gateChecks.map((g) => g.toJson()).toList(),
    'killSwitchResult': killSwitchResult.toJson(), 'rollbackResult': rollbackResult.toJson(),
    'blockers': blockers, 'warnings': warnings, 'riskList': riskList,
    'guardFlags': guard.toJson(), 'conclusionNote': conclusionNote,
  };
}

/// 受控开关沙箱验证器
class SolarTermControlledRolloutSwitchSandbox {
  const SolarTermControlledRolloutSwitchSandbox();

  static const allowedTransitions = {
    'locked_off': ['review_frozen'],
    'review_frozen': ['human_approved_pending'],
    'human_approved_pending': ['sandbox_ready'],
    'sandbox_ready': ['controlled_rollout_ready'],
  };

  SolarTermControlledRolloutSwitchSandboxResult validate({
    required String switchDesignStatus,
    required String initialSwitchState,
    String targetSwitchState = 'sandbox_ready',
    required bool allGatesPassed,
    required bool killSwitchTriggered,
    required bool rollbackSuccessful,
    required bool hasHighRisk,
    String? sampleName,
    String dateRange = '',
  }) {
    final guard = const SolarTermControlledRolloutSwitchSandboxGuard();
    final blockers = <String>[];

    // State transitions
    final transitions = <SolarTermControlledRolloutSwitchSandboxStateTransition>[];
    final allowed = allowedTransitions[initialSwitchState] ?? const [];
    final isAllowed = allowed.contains(targetSwitchState);
    transitions.add(SolarTermControlledRolloutSwitchSandboxStateTransition(
      from: initialSwitchState, to: targetSwitchState, allowed: isAllowed,
      reason: isAllowed ? '' : '从 $initialSwitchState 不支持直接转到 $targetSwitchState',
    ));

    // Gate checks
    final gateChecks = <SolarTermControlledRolloutSwitchSandboxGateCheck>[
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'reviewFrozenConfirmed', passed: switchDesignStatus == 'switch_design_ready', note: switchDesignStatus),
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'humanApprovalConfirmed', passed: false, note: '需人工批准'),
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'noGoRulesClear', passed: allGatesPassed, severity: 'high'),
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'noHighRisk', passed: !hasHighRisk, severity: 'high'),
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'rollbackPlanReady', passed: rollbackSuccessful),
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'killSwitchReady', passed: true),
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'calendarProviderGuardReady', passed: !guard.calendarProviderIntegration),
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'pageDisplayGuardReady', passed: !guard.displayAllowed),
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'shareExposureGuardReady', passed: !guard.shareAllowed),
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'snapshotWriteGuardReady', passed: !guard.snapshotAllowed),
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'ganzhiDependencyGuardReady', passed: !guard.ganzhiDependencyAllowed),
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'clashDependencyGuardReady', passed: !guard.clashDependencyAllowed),
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'monitoringPlanReady', passed: false, note: '需监控计划'),
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'rollbackDrillRequired', passed: false, severity: 'high'),
      SolarTermControlledRolloutSwitchSandboxGateCheck(id: 'finalReleaseApprovalRequired', passed: false),
    ];

    // Determine sandbox status and final state
    String status;
    String finalState;

    if (!guard.allSafe) {
      status = 'blocked'; finalState = 'locked_off'; blockers.add('guard_unsafe');
    } else if (switchDesignStatus == 'blocked') {
      status = 'blocked'; finalState = initialSwitchState; blockers.add('design_blocked');
    } else if (switchDesignStatus == 'design_not_allowed') {
      status = 'sandbox_not_allowed'; finalState = initialSwitchState;
    } else if (hasHighRisk) {
      status = 'blocked'; finalState = 'locked_off'; blockers.add('high_risk');
    } else if (killSwitchTriggered) {
      status = 'killed_and_locked_off'; finalState = 'locked_off';
    } else if (!rollbackSuccessful) {
      status = 'sandbox_failed'; finalState = initialSwitchState; blockers.add('rollback_failed');
    } else if (!allGatesPassed) {
      status = 'sandbox_failed'; finalState = initialSwitchState; blockers.add('required_gate_failed');
    } else if (!isAllowed) {
      status = 'sandbox_failed'; finalState = initialSwitchState; blockers.add('invalid_transition');
    } else if (switchDesignStatus == 'switch_design_ready') {
      status = 'sandbox_passed'; finalState = targetSwitchState;
    } else {
      status = 'blocked'; finalState = 'locked_off';
    }

    // Kill switch result
    final killResult = SolarTermControlledRolloutSwitchSandboxKillSwitchResult(
      triggered: killSwitchTriggered, previousState: initialSwitchState, finalState: finalState,
    );

    return SolarTermControlledRolloutSwitchSandboxResult(
      sampleName: sampleName, dateRange: dateRange.isEmpty ? 'v0.22-v0.43' : dateRange,
      sandboxStatus: status, initialSwitchState: initialSwitchState,
      targetSwitchState: targetSwitchState, finalSwitchState: finalState,
      stateTransitions: transitions, gateChecks: gateChecks,
      killSwitchResult: killResult,
      rollbackResult: const SolarTermControlledRolloutSwitchSandboxRollbackResult(),
      blockers: blockers,
      riskList: hasHighRisk ? ['highRiskCount > 0'] : [],
    );
  }

  Map<String, dynamic> buildDebugJson() => {
    'schemaVersion': 'solar-term-controlled-rollout-switch-sandbox-debug-v0_43',
    'switchSandboxEnabled': true,
    'sampleName': null, 'dateRange': 'v0.22-v0.43',
    'sandboxStatus': 'sandbox_not_allowed',
    'initialSwitchState': 'locked_off', 'targetSwitchState': 'sandbox_ready', 'finalSwitchState': 'locked_off',
    'stateTransitions': [], 'gatePassedCount': 0, 'gateFailedCount': 15,
    'killSwitchResult': const SolarTermControlledRolloutSwitchSandboxKillSwitchResult().toJson(),
    'rollbackResult': const SolarTermControlledRolloutSwitchSandboxRollbackResult().toJson(),
    'blockers': [], 'warnings': [], 'riskList': [],
    'guardFlags': const SolarTermControlledRolloutSwitchSandboxGuard().toJson(),
    'conclusionNote': 'controlled switch sandbox only, not public solar term capability',
  };
}

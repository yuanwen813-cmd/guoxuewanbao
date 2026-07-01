/// 节气正式接入受控开关设计 v0.42
///
/// 设计受控开关、Kill Switch、灰度条件、人工批准门禁和回滚策略。
/// switch_design_ready ≠ productionReady ≠ publicExposure。
/// 所有 guard flags 必须 false。

/// 开关状态枚举（仅设计，不驱动 public path）
class SolarTermControlledRolloutSwitchStates {
  static const lockedOff = 'locked_off';
  static const reviewFrozen = 'review_frozen';
  static const humanApprovedPending = 'human_approved_pending';
  static const sandboxReady = 'sandbox_ready';
  static const controlledRolloutReady = 'controlled_rollout_ready';

  static const all = [lockedOff, reviewFrozen, humanApprovedPending, sandboxReady, controlledRolloutReady];

  const SolarTermControlledRolloutSwitchStates();
}

/// Kill Switch 设计
class SolarTermControlledRolloutKillSwitch {
  final bool killSwitchExists;
  final String defaultState;
  final bool canDisableCalendarProviderIntegration;
  final bool canDisablePageDisplay;
  final bool canDisableShareExposure;
  final bool canDisableSnapshotWrite;
  final bool canDisableGanzhiDependency;
  final bool canDisableClashDependency;
  final bool rollbackToUnavailable;
  final bool preserveLunarAndZodiac;

  const SolarTermControlledRolloutKillSwitch({
    this.killSwitchExists = true,
    this.defaultState = 'locked_off',
    this.canDisableCalendarProviderIntegration = true,
    this.canDisablePageDisplay = true,
    this.canDisableShareExposure = true,
    this.canDisableSnapshotWrite = true,
    this.canDisableGanzhiDependency = true,
    this.canDisableClashDependency = true,
    this.rollbackToUnavailable = true,
    this.preserveLunarAndZodiac = true,
  });

  Map<String, dynamic> toJson() => {
    'killSwitchExists': killSwitchExists, 'defaultState': defaultState,
    'canDisableCalendarProviderIntegration': canDisableCalendarProviderIntegration,
    'canDisablePageDisplay': canDisablePageDisplay,
    'canDisableShareExposure': canDisableShareExposure,
    'canDisableSnapshotWrite': canDisableSnapshotWrite,
    'canDisableGanzhiDependency': canDisableGanzhiDependency,
    'canDisableClashDependency': canDisableClashDependency,
    'rollbackToUnavailable': rollbackToUnavailable,
    'preserveLunarAndZodiac': preserveLunarAndZodiac,
  };
}

/// Rollout Gate
class SolarTermControlledRolloutGate {
  final String id; final String title; final bool passed; final bool required;
  final String severity; final String note;

  const SolarTermControlledRolloutGate({
    required this.id, required this.title, this.passed = false, this.required = true,
    this.severity = 'critical', this.note = '',
  });

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'passed': passed, 'required': required, 'severity': severity, 'note': note};
}

/// Switch Guard（固定 false）
class SolarTermControlledRolloutGuard {
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;
  final bool displayAllowed; final bool shareAllowed; final bool snapshotAllowed;
  final bool ganzhiDependencyAllowed; final bool clashDependencyAllowed;

  const SolarTermControlledRolloutGuard()
      : productionReady = false, publicExposure = false, calendarProviderIntegration = false,
        displayAllowed = false, shareAllowed = false, snapshotAllowed = false,
        ganzhiDependencyAllowed = false, clashDependencyAllowed = false;

  bool get allSafe => !productionReady && !publicExposure && !calendarProviderIntegration &&
      !displayAllowed && !shareAllowed && !snapshotAllowed &&
      !ganzhiDependencyAllowed && !clashDependencyAllowed;

  Map<String, dynamic> toJson() => {
    'productionReady': productionReady, 'publicExposure': publicExposure,
    'calendarProviderIntegration': calendarProviderIntegration,
    'displayAllowed': displayAllowed, 'shareAllowed': shareAllowed, 'snapshotAllowed': snapshotAllowed,
    'ganzhiDependencyAllowed': ganzhiDependencyAllowed, 'clashDependencyAllowed': clashDependencyAllowed,
  };
}

/// Switch Design Result
class SolarTermControlledRolloutSwitchResult {
  final String schemaVersion;
  final String? sampleName;
  final String dateRange;
  final String switchDesignStatus;
  final String switchState;
  final List<SolarTermControlledRolloutGate> rolloutGates;
  final SolarTermControlledRolloutKillSwitch killSwitch;
  final List<String> rollbackPlan;
  final List<String> riskList;
  final List<String> blockers;
  final List<String> warnings;
  final SolarTermControlledRolloutGuard guard;
  final String conclusionNote;

  const SolarTermControlledRolloutSwitchResult({
    this.schemaVersion = 'solar-term-controlled-rollout-switch-design-v0_42',
    this.sampleName, required this.dateRange, required this.switchDesignStatus, required this.switchState,
    required this.rolloutGates, required this.killSwitch,
    this.rollbackPlan = const [], this.riskList = const [], this.blockers = const [], this.warnings = const [],
    this.guard = const SolarTermControlledRolloutGuard(),
    this.conclusionNote = 'controlled switch design only, not public solar term capability',
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    if (sampleName != null) 'sampleName': sampleName,
    'dateRange': dateRange, 'switchDesignStatus': switchDesignStatus, 'switchState': switchState,
    'rolloutGates': rolloutGates.map((g) => g.toJson()).toList(),
    'killSwitch': killSwitch.toJson(),
    'rollbackPlan': rollbackPlan, 'riskList': riskList, 'blockers': blockers, 'warnings': warnings,
    'guardFlags': guard.toJson(), 'conclusionNote': conclusionNote,
  };
}

/// 受控开关设计器
class SolarTermControlledRolloutSwitchDesign {
  const SolarTermControlledRolloutSwitchDesign();

  static const rollbackSteps = [
    'disableSupportsSolarTerm',
    'hidePageSolarTerm',
    'hideShareSolarTerm',
    'stopSnapshotSolarTermWrite',
    'keepOldSnapshotCompatible',
    'restoreUnavailableState',
    'preserveLunarAndZodiac',
    'disableGanzhiDependency',
    'disableClashDependency',
    'rollbackDebugFlag',
  ];

  /// 设计受控开关
  SolarTermControlledRolloutSwitchResult design({
    required String reviewStatus,
    required bool hasNoGoTriggered,
    required bool hasHighRisk,
    required bool hasKillSwitch,
    required bool hasRollbackPlan,
    String? sampleName,
    String dateRange = '',
  }) {
    final guard = const SolarTermControlledRolloutGuard();
    final blockers = <String>[];

    // Determine switch design status
    String status;
    String switchState;

    if (!guard.allSafe) {
      status = 'blocked'; blockers.add('guard_unsafe'); switchState = 'locked_off';
    } else if (reviewStatus == 'blocked') {
      status = 'blocked'; blockers.add('review_blocked'); switchState = 'locked_off';
    } else if (reviewStatus == 'review_not_allowed') {
      status = 'design_not_allowed'; switchState = 'locked_off';
    } else if (reviewStatus == 'ready_for_human_approval') {
      status = 'design_not_allowed'; switchState = 'human_approved_pending';
    } else if (hasNoGoTriggered) {
      status = 'blocked'; blockers.add('noGo_triggered'); switchState = 'locked_off';
    } else if (hasHighRisk) {
      status = 'blocked'; blockers.add('high_risk'); switchState = 'locked_off';
    } else if (!hasKillSwitch) {
      status = 'blocked'; blockers.add('missing_kill_switch'); switchState = 'locked_off';
    } else if (!hasRollbackPlan) {
      status = 'blocked'; blockers.add('missing_rollback_plan'); switchState = 'locked_off';
    } else if (reviewStatus == 'review_frozen') {
      status = 'switch_design_ready'; switchState = 'sandbox_ready';
    } else {
      status = 'blocked'; switchState = 'locked_off';
    }

    // Rollout gates
    final gates = <SolarTermControlledRolloutGate>[
      SolarTermControlledRolloutGate(id: 'reviewFrozenConfirmed', title: 'Review frozen 确认', passed: reviewStatus == 'review_frozen', note: reviewStatus),
      SolarTermControlledRolloutGate(id: 'humanApprovalConfirmed', title: '人工批准确认', passed: false, note: '需人工批准'),
      SolarTermControlledRolloutGate(id: 'noGoRulesClear', title: 'No-go rules 清零', passed: !hasNoGoTriggered, severity: 'high'),
      SolarTermControlledRolloutGate(id: 'noHighRisk', title: '无 high risk', passed: !hasHighRisk, severity: 'high'),
      SolarTermControlledRolloutGate(id: 'rollbackPlanReady', title: '回滚计划就绪', passed: hasRollbackPlan),
      SolarTermControlledRolloutGate(id: 'killSwitchReady', title: 'Kill switch 就绪', passed: hasKillSwitch),
      SolarTermControlledRolloutGate(id: 'calendarProviderGuardReady', title: 'CalendarProvider guard', passed: !guard.calendarProviderIntegration),
      SolarTermControlledRolloutGate(id: 'pageDisplayGuardReady', title: '页面展示 guard', passed: !guard.displayAllowed),
      SolarTermControlledRolloutGate(id: 'shareExposureGuardReady', title: '分享暴露 guard', passed: !guard.shareAllowed),
      SolarTermControlledRolloutGate(id: 'snapshotWriteGuardReady', title: 'Snapshot guard', passed: !guard.snapshotAllowed),
      SolarTermControlledRolloutGate(id: 'ganzhiDependencyGuardReady', title: '干支依赖 guard', passed: !guard.ganzhiDependencyAllowed),
      SolarTermControlledRolloutGate(id: 'clashDependencyGuardReady', title: '冲煞依赖 guard', passed: !guard.clashDependencyAllowed),
      SolarTermControlledRolloutGate(id: 'monitoringPlanReady', title: '监控计划就绪', passed: false, note: '需灰度监控计划'),
      SolarTermControlledRolloutGate(id: 'rollbackDrillRequired', title: '回滚演练', passed: false, severity: 'high', note: '正式灰度前必须完成回滚演练'),
      SolarTermControlledRolloutGate(id: 'finalReleaseApprovalRequired', title: '最终发布审批', passed: false, note: '需最终 release 审批'),
    ];

    return SolarTermControlledRolloutSwitchResult(
      sampleName: sampleName,
      dateRange: dateRange.isEmpty ? 'v0.22-v0.42' : dateRange,
      switchDesignStatus: status,
      switchState: switchState,
      rolloutGates: gates,
      killSwitch: const SolarTermControlledRolloutKillSwitch(),
      rollbackPlan: rollbackSteps,
      riskList: hasHighRisk ? ['highRiskCount > 0'] : [],
      blockers: blockers,
    );
  }

  Map<String, dynamic> buildDebugJson() => {
    'schemaVersion': 'solar-term-controlled-rollout-switch-design-debug-v0_42',
    'switchDesignEnabled': true,
    'sampleName': null, 'dateRange': 'v0.22-v0.42',
    'switchDesignStatus': 'design_not_allowed', 'switchState': 'locked_off',
    'rolloutGatePassedCount': 0, 'rolloutGateFailedCount': 15,
    'killSwitch': const SolarTermControlledRolloutKillSwitch().toJson(),
    'blockers': [], 'warnings': [], 'riskList': [],
    'guardFlags': const SolarTermControlledRolloutGuard().toJson(),
    'conclusionNote': 'controlled switch design only, not public solar term capability',
  };
}

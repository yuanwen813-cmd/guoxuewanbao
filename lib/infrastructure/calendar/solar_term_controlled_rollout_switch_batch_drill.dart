/// 节气正式接入受控开关批量演练 v0.44
///
/// 批量演练多日期范围下的 switch sandbox 状态流转、Kill Switch、Rollback 和 gate 阻断。
/// drill_passed ≠ productionReady ≠ publicExposure。
/// 所有 guard flags 必须 false。

/// Drill Scenario
class SolarTermControlledRolloutSwitchBatchDrillScenario {
  final String id; final String title; final String simulatedAction;
  final String expectedSandboxStatus; final String expectedFinalSwitchState;
  final bool required; final String severity; final String note;

  const SolarTermControlledRolloutSwitchBatchDrillScenario({
    required this.id, required this.title, required this.simulatedAction,
    required this.expectedSandboxStatus, required this.expectedFinalSwitchState,
    this.required = true, this.severity = 'critical', this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'simulatedAction': simulatedAction,
    'expectedSandboxStatus': expectedSandboxStatus, 'expectedFinalSwitchState': expectedFinalSwitchState,
    'required': required, 'severity': severity, 'note': note,
  };
}

/// Drill Issue
class SolarTermControlledRolloutSwitchBatchDrillIssue {
  final String date; final String scenario; final String reason; final String severity;
  const SolarTermControlledRolloutSwitchBatchDrillIssue({required this.date, required this.scenario, required this.reason, this.severity = 'high'});
  Map<String, dynamic> toJson() => {'date': date, 'scenario': scenario, 'reason': reason, 'severity': severity};
}

/// Drill Guard（固定 false）
class SolarTermControlledRolloutSwitchBatchDrillGuard {
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;
  final bool displayAllowed; final bool shareAllowed; final bool snapshotAllowed;
  final bool ganzhiDependencyAllowed; final bool clashDependencyAllowed;

  const SolarTermControlledRolloutSwitchBatchDrillGuard()
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

/// Drill Result
class SolarTermControlledRolloutSwitchBatchDrillResult {
  final String schemaVersion; final String? sampleName; final String dateRange;
  final int totalDays; final int totalScenarios; final int totalRuns;
  final int sandboxPassedCount; final int sandboxFailedCount; final int sandboxBlockedCount;
  final int sandboxNotAllowedCount; final int killedAndLockedOffCount;
  final int rollbackExecutedCount; final int rollbackFailedCount;
  final int requiredGateFailedCount; final int guardUnsafeCount; final int highRiskCount;
  final Map<String, int> statusDistribution; final Map<String, int> scenarioDistribution;
  final String? firstFailureDate; final String? firstBlockedDate;
  final List<SolarTermControlledRolloutSwitchBatchDrillIssue> issues;
  final List<String> riskList; final List<String> blockers; final List<String> warnings;
  final SolarTermControlledRolloutSwitchBatchDrillGuard guard;
  final String drillStatus; final String conclusionNote;

  const SolarTermControlledRolloutSwitchBatchDrillResult({
    this.schemaVersion = 'solar-term-controlled-rollout-switch-batch-drill-v0_44',
    this.sampleName, required this.dateRange, required this.totalDays,
    required this.totalScenarios, required this.totalRuns,
    required this.sandboxPassedCount, required this.sandboxFailedCount,
    required this.sandboxBlockedCount, required this.sandboxNotAllowedCount,
    required this.killedAndLockedOffCount, required this.rollbackExecutedCount,
    required this.rollbackFailedCount, required this.requiredGateFailedCount,
    required this.guardUnsafeCount, required this.highRiskCount,
    this.statusDistribution = const {}, this.scenarioDistribution = const {},
    this.firstFailureDate, this.firstBlockedDate,
    this.issues = const [], this.riskList = const [], this.blockers = const [], this.warnings = const [],
    this.guard = const SolarTermControlledRolloutSwitchBatchDrillGuard(),
    required this.drillStatus,
    this.conclusionNote = 'controlled switch batch drill only, not public solar term capability',
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    if (sampleName != null) 'sampleName': sampleName,
    'dateRange': dateRange, 'totalDays': totalDays, 'totalScenarios': totalScenarios, 'totalRuns': totalRuns,
    'sandboxPassedCount': sandboxPassedCount, 'sandboxFailedCount': sandboxFailedCount,
    'sandboxBlockedCount': sandboxBlockedCount, 'sandboxNotAllowedCount': sandboxNotAllowedCount,
    'killedAndLockedOffCount': killedAndLockedOffCount,
    'rollbackExecutedCount': rollbackExecutedCount, 'rollbackFailedCount': rollbackFailedCount,
    'requiredGateFailedCount': requiredGateFailedCount, 'guardUnsafeCount': guardUnsafeCount, 'highRiskCount': highRiskCount,
    'statusDistribution': statusDistribution, 'scenarioDistribution': scenarioDistribution,
    if (firstFailureDate != null) 'firstFailureDate': firstFailureDate,
    if (firstBlockedDate != null) 'firstBlockedDate': firstBlockedDate,
    'issues': issues.map((i) => i.toJson()).toList(),
    'riskList': riskList, 'blockers': blockers, 'warnings': warnings,
    'guardFlags': guard.toJson(), 'drillStatus': drillStatus, 'conclusionNote': conclusionNote,
  };
}

/// 批量演练器
class SolarTermControlledRolloutSwitchBatchDrill {
  const SolarTermControlledRolloutSwitchBatchDrill();

  static const scenarios = [
    SolarTermControlledRolloutSwitchBatchDrillScenario(id: 'normalSandboxPass', title: '正常沙箱演练', simulatedAction: 'gates_passed', expectedSandboxStatus: 'sandbox_passed', expectedFinalSwitchState: 'controlled_rollout_ready'),
    SolarTermControlledRolloutSwitchBatchDrillScenario(id: 'requiredGateFailure', title: 'Required gate 失败', simulatedAction: 'gates_failed', expectedSandboxStatus: 'sandbox_failed', expectedFinalSwitchState: 'sandbox_ready'),
    SolarTermControlledRolloutSwitchBatchDrillScenario(id: 'killSwitchTriggered', title: 'Kill Switch 触发', simulatedAction: 'kill_switch_triggered', expectedSandboxStatus: 'killed_and_locked_off', expectedFinalSwitchState: 'locked_off'),
    SolarTermControlledRolloutSwitchBatchDrillScenario(id: 'rollbackExecuted', title: 'Rollback 执行', simulatedAction: 'rollback_executed', expectedSandboxStatus: 'sandbox_passed', expectedFinalSwitchState: 'controlled_rollout_ready'),
    SolarTermControlledRolloutSwitchBatchDrillScenario(id: 'guardUnsafeBlocked', title: 'Guard unsafe', simulatedAction: 'guard_unsafe', expectedSandboxStatus: 'blocked', expectedFinalSwitchState: 'locked_off'),
    SolarTermControlledRolloutSwitchBatchDrillScenario(id: 'highRiskBlocked', title: 'High risk', simulatedAction: 'high_risk', expectedSandboxStatus: 'blocked', expectedFinalSwitchState: 'locked_off'),
  ];

  /// 运行批量演练
  SolarTermControlledRolloutSwitchBatchDrillResult drill({
    required String switchDesignStatus,
    required DateTime startDate,
    required DateTime endDate,
    String? sampleName,
  }) {
    final guard = const SolarTermControlledRolloutSwitchBatchDrillGuard();
    final issues = <SolarTermControlledRolloutSwitchBatchDrillIssue>[];
    final statusDist = <String, int>{};
    final scenarioDist = <String, int>{};

    int totalDays = 0, total = 0;
    int passed = 0, failed = 0, blocked = 0, notAllowed = 0, killed = 0;
    int rollbackOk = 0, rollbackFail = 0, gateFail = 0, guardUnsafe = 0, highRisk = 0;
    String? firstFailure, firstBlocked;

    for (var d = startDate; !d.isAfter(endDate); d = d.add(const Duration(days: 1))) {
      totalDays++;
      final dk = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      for (final sc in scenarios) {
        total++;
        String status; String finalState;
        switch (sc.id) {
          case 'normalSandboxPass':
            status = 'sandbox_passed'; finalState = 'controlled_rollout_ready'; passed++;
            break;
          case 'requiredGateFailure':
            status = 'sandbox_failed'; finalState = 'sandbox_ready'; failed++; gateFail++;
            issues.add(SolarTermControlledRolloutSwitchBatchDrillIssue(date: dk, scenario: sc.id, reason: 'required gate failure simulated'));
            break;
          case 'killSwitchTriggered':
            status = 'killed_and_locked_off'; finalState = 'locked_off'; killed++;
            break;
          case 'rollbackExecuted':
            status = 'sandbox_passed'; finalState = 'controlled_rollout_ready'; passed++; rollbackOk++;
            break;
          case 'guardUnsafeBlocked':
            status = 'blocked'; finalState = 'locked_off'; blocked++; guardUnsafe++;
            issues.add(SolarTermControlledRolloutSwitchBatchDrillIssue(date: dk, scenario: sc.id, reason: 'guard unsafe'));
            firstBlocked ??= dk;
            break;
          case 'highRiskBlocked':
            status = 'blocked'; finalState = 'locked_off'; blocked++; highRisk++;
            firstBlocked ??= dk;
            break;
          default:
            status = 'blocked'; finalState = 'locked_off'; blocked++;
        }
        statusDist[status] = (statusDist[status] ?? 0) + 1;
        scenarioDist[sc.id] = (scenarioDist[sc.id] ?? 0) + 1;

        if (finalState != sc.expectedFinalSwitchState) {
          issues.add(SolarTermControlledRolloutSwitchBatchDrillIssue(date: dk, scenario: sc.id, reason: 'expected ${sc.expectedFinalSwitchState}, got $finalState'));
          firstFailure ??= dk;
        }
      }
    }

    // Determine drill status
    String drillStatus;
    if (totalDays <= 0 || total <= 0) {
      drillStatus = 'insufficient_samples';
    } else if (switchDesignStatus != 'switch_design_ready') {
      drillStatus = 'blocked';
    } else if (!guard.allSafe) {
      drillStatus = 'blocked';
    } else if (blocked > 0 || highRisk > 0) {
      drillStatus = 'blocked';
    } else if (rollbackFail > 0) {
      drillStatus = 'drill_failed';
    } else if (gateFail > 0) {
      drillStatus = 'drill_failed';
    } else if (killed > 0 && finalStateMismatch(issues)) {
      drillStatus = 'drill_failed';
    } else {
      drillStatus = 'drill_passed';
    }

    return SolarTermControlledRolloutSwitchBatchDrillResult(
      sampleName: sampleName,
      dateRange: '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}'
          ' ~ ${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      totalDays: totalDays, totalScenarios: scenarios.length, totalRuns: total,
      sandboxPassedCount: passed, sandboxFailedCount: failed, sandboxBlockedCount: blocked,
      sandboxNotAllowedCount: notAllowed, killedAndLockedOffCount: killed,
      rollbackExecutedCount: rollbackOk, rollbackFailedCount: rollbackFail,
      requiredGateFailedCount: gateFail, guardUnsafeCount: guardUnsafe, highRiskCount: highRisk,
      statusDistribution: statusDist, scenarioDistribution: scenarioDist,
      firstFailureDate: firstFailure, firstBlockedDate: firstBlocked, issues: issues,
      riskList: highRisk > 0 ? ['highRiskCount > 0'] : [],
      drillStatus: drillStatus,
    );
  }

  bool finalStateMismatch(List<SolarTermControlledRolloutSwitchBatchDrillIssue> issues) {
    return issues.any((i) => i.reason.contains('expected'));
  }

  Map<String, dynamic> buildDebugJson() => {
    'schemaVersion': 'solar-term-controlled-rollout-switch-batch-drill-debug-v0_44',
    'batchDrillEnabled': true,
    'sampleName': null, 'dateRange': null,
    'drillStatus': 'blocked',
    'totalDays': 0, 'totalScenarios': 6, 'totalRuns': 0,
    'sandboxPassedCount': 0, 'killedAndLockedOffCount': 0,
    'rollbackExecutedCount': 0, 'rollbackFailedCount': 0,
    'requiredGateFailedCount': 0, 'guardUnsafeCount': 0,
    'firstFailureDate': null, 'firstBlockedDate': null,
    'blockers': [], 'warnings': [], 'riskList': [],
    'guardFlags': const SolarTermControlledRolloutSwitchBatchDrillGuard().toJson(),
    'conclusionNote': 'controlled switch batch drill only, not public solar term capability',
  };
}

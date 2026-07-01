/// 节气试运行证据包 v0.35
///
/// 将 trial engine / audit / observation 组合为只读 evidence package。
/// ready_for_next_evaluation ≠ productionReady ≠ publicExposure。
/// 所有 guard flags 必须 false。

import 'solar_term_trial_observer.dart';

/// 证据包 guard flags（固定 false）
class SolarTermTrialEvidenceGuard {
  final bool productionReady;
  final bool publicExposure;
  final bool calendarProviderIntegration;
  final bool displayAllowed;
  final bool shareAllowed;
  final bool snapshotAllowed;
  final bool ganzhiDependencyAllowed;
  final bool clashDependencyAllowed;

  const SolarTermTrialEvidenceGuard()
      : productionReady = false,
        publicExposure = false,
        calendarProviderIntegration = false,
        displayAllowed = false,
        shareAllowed = false,
        snapshotAllowed = false,
        ganzhiDependencyAllowed = false,
        clashDependencyAllowed = false;

  bool get allGuardsSafe => !productionReady && !publicExposure && !calendarProviderIntegration &&
      !displayAllowed && !shareAllowed && !snapshotAllowed &&
      !ganzhiDependencyAllowed && !clashDependencyAllowed;

  Map<String, dynamic> toJson() => {
    'productionReady': productionReady, 'publicExposure': publicExposure,
    'calendarProviderIntegration': calendarProviderIntegration,
    'displayAllowed': displayAllowed, 'shareAllowed': shareAllowed, 'snapshotAllowed': snapshotAllowed,
    'ganzhiDependencyAllowed': ganzhiDependencyAllowed, 'clashDependencyAllowed': clashDependencyAllowed,
  };
}

/// 证据包风险项
class SolarTermTrialEvidenceRisk {
  final String description;
  final String severity; // high | medium | low

  const SolarTermTrialEvidenceRisk({required this.description, this.severity = 'medium'});

  Map<String, dynamic> toJson() => {'description': description, 'severity': severity};
}

/// 证据包决策
class SolarTermTrialEvidenceDecision {
  final String status; // evidence_only | blocked | insufficient_evidence | ready_for_next_evaluation
  final String reason;
  final List<String> blockingFactors;

  const SolarTermTrialEvidenceDecision({
    this.status = 'evidence_only',
    this.reason = '',
    this.blockingFactors = const [],
  });

  Map<String, dynamic> toJson() => {
    'status': status, 'reason': reason, 'blockingFactors': blockingFactors,
  };
}

/// 证据包汇总
class SolarTermTrialEvidenceSummary {
  final String schemaVersion;
  final String? sampleName;
  final String dateRange; // "YYYY-MM-DD ~ YYYY-MM-DD"
  final int totalDays;
  final int auditPassedCount;
  final int auditFailedCount;
  final int trialAvailableCount;
  final int trialUnavailableCount;
  final int blockedCount;
  final List<String> failedReasons;
  final String? firstFailedDate;
  final List<SolarTermTrialEvidenceRisk> riskList;
  final SolarTermTrialEvidenceGuard guard;
  final SolarTermTrialEvidenceDecision decision;
  final String conclusionNote;

  const SolarTermTrialEvidenceSummary({
    this.schemaVersion = 'solar-term-trial-evidence-package-v0_35',
    this.sampleName,
    required this.dateRange,
    required this.totalDays,
    required this.auditPassedCount,
    required this.auditFailedCount,
    required this.trialAvailableCount,
    required this.trialUnavailableCount,
    required this.blockedCount,
    this.failedReasons = const [],
    this.firstFailedDate,
    this.riskList = const [],
    this.guard = const SolarTermTrialEvidenceGuard(),
    this.decision = const SolarTermTrialEvidenceDecision(),
    this.conclusionNote = 'evidence package only, not public solar term capability',
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    if (sampleName != null) 'sampleName': sampleName,
    'dateRange': dateRange,
    'totalDays': totalDays,
    'auditPassedCount': auditPassedCount,
    'auditFailedCount': auditFailedCount,
    'trialAvailableCount': trialAvailableCount,
    'trialUnavailableCount': trialUnavailableCount,
    'blockedCount': blockedCount,
    'failedReasons': failedReasons,
    if (firstFailedDate != null) 'firstFailedDate': firstFailedDate,
    'riskList': riskList.map((r) => r.toJson()).toList(),
    'guardFlags': guard.toJson(),
    'decision': decision.toJson(),
    'conclusionNote': conclusionNote,
  };
}

/// 证据包构建器
class SolarTermTrialEvidencePackage {
  const SolarTermTrialEvidencePackage();

  /// 基于 observation summary 构建证据包
  SolarTermTrialEvidenceSummary build({
    required SolarTermTrialObservationSummary observation,
    String? sampleName,
  }) {
    final dateRange = '${observation.startDate.year}-${observation.startDate.month.toString().padLeft(2, '0')}-${observation.startDate.day.toString().padLeft(2, '0')}'
        ' ~ ${observation.endDate.year}-${observation.endDate.month.toString().padLeft(2, '0')}-${observation.endDate.day.toString().padLeft(2, '0')}';

    final guard = const SolarTermTrialEvidenceGuard();
    final risks = <SolarTermTrialEvidenceRisk>[];

    // Decision logic
    final decision = _makeDecision(observation, guard, risks);

    return SolarTermTrialEvidenceSummary(
      sampleName: sampleName,
      dateRange: dateRange,
      totalDays: observation.totalDays,
      auditPassedCount: observation.auditPassedCount,
      auditFailedCount: observation.auditFailedCount,
      trialAvailableCount: observation.trialAvailableCount,
      trialUnavailableCount: observation.trialUnavailableCount,
      blockedCount: observation.blockedCount,
      failedReasons: observation.failedReasons,
      firstFailedDate: observation.firstFailedDate?.toIso8601String(),
      riskList: risks,
      guard: guard,
      decision: decision,
    );
  }

  SolarTermTrialEvidenceDecision _makeDecision(
    SolarTermTrialObservationSummary observation,
    SolarTermTrialEvidenceGuard guard,
    List<SolarTermTrialEvidenceRisk> risks,
  ) {
    // 1. guard flags must all be false
    if (!guard.allGuardsSafe) {
      risks.add(const SolarTermTrialEvidenceRisk(description: 'guard flags 不一致，存在允许泄露的 flag', severity: 'high'));
      return const SolarTermTrialEvidenceDecision(status: 'blocked', reason: 'guard flags 不安全', blockingFactors: ['guard_violation']);
    }

    // 2. audit failed count > 0
    if (observation.auditFailedCount > 0) {
      risks.add(SolarTermTrialEvidenceRisk(
        description: '${observation.auditFailedCount} 天 audit 失败',
        severity: 'high',
      ));
      return SolarTermTrialEvidenceDecision(
        status: 'blocked',
        reason: '存在 audit 失败日期',
        blockingFactors: observation.failedReasons,
      );
    }

    // 3. insufficient data
    if (observation.totalDays <= 0) {
      return const SolarTermTrialEvidenceDecision(
        status: 'insufficient_evidence',
        reason: '观测天数为 0，证据不足',
        blockingFactors: ['totalDays <= 0'],
      );
    }

    // 4. trial data unavailable (all days unavailable without being blocked)
    if (observation.trialAvailableCount == 0 && observation.trialUnavailableCount > 0) {
      risks.add(const SolarTermTrialEvidenceRisk(
        description: '所有观测日期 trial 数据不可用',
        severity: 'medium',
      ));
      return const SolarTermTrialEvidenceDecision(
        status: 'insufficient_evidence',
        reason: '试运行数据不可用，无法形成有效证据',
        blockingFactors: ['trialAvailableCount == 0'],
      );
    }

    // 5. all passed → ready for next evaluation
    return SolarTermTrialEvidenceDecision(
      status: 'ready_for_next_evaluation',
      reason: '证据包安全，可进入下一阶段评估',
    );
  }

  Map<String, dynamic> buildDebugJson() => {
    'schemaVersion': 'solar-term-trial-evidence-package-debug-v0_35',
    'evidencePackageEnabled': true,
    'sampleName': null,
    'dateRange': null,
    'decisionStatus': 'evidence_only',
    'totalDays': 0,
    'auditPassedCount': 0,
    'auditFailedCount': 0,
    'failedReasons': [],
    'riskList': [],
    'guardFlags': const SolarTermTrialEvidenceGuard().toJson(),
    'conclusionNote': 'evidence package only, not public solar term capability',
  };
}

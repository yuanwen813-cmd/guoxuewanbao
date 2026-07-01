/// 节气正式接入准入评估器 v0.36
///
/// 基于证据包判定是否具备进入正式接入设计评审的资格。
/// ready_for_design_review ≠ productionReady ≠ publicExposure。
/// 所有 guard flags 必须 false。

import 'solar_term_trial_evidence_package.dart';

/// 准入检查项
class SolarTermPublicIntegrationReadinessCheckItem {
  final String id;
  final String title;
  final bool passed;
  final String severity; // critical | high | medium | info
  final String note;

  const SolarTermPublicIntegrationReadinessCheckItem({
    required this.id, required this.title, required this.passed,
    this.severity = 'medium', this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'passed': passed, 'severity': severity, 'note': note,
  };
}

/// 准入 checklist
class SolarTermPublicIntegrationReadinessChecklist {
  final List<SolarTermPublicIntegrationReadinessCheckItem> items;

  const SolarTermPublicIntegrationReadinessChecklist({required this.items});

  int get passedCount => items.where((i) => i.passed).length;
  int get failedCount => items.where((i) => !i.passed).length;
  List<SolarTermPublicIntegrationReadinessCheckItem> get criticalFailures =>
      items.where((i) => !i.passed && i.severity == 'critical').toList();

  Map<String, dynamic> toJson() => {
    'items': items.map((i) => i.toJson()).toList(),
    'passedCount': passedCount, 'failedCount': failedCount,
  };
}

/// 准入 guard（固定 false）
class SolarTermPublicIntegrationReadinessGuard {
  final bool productionReady;
  final bool publicExposure;
  final bool calendarProviderIntegration;
  final bool displayAllowed;
  final bool shareAllowed;
  final bool snapshotAllowed;
  final bool ganzhiDependencyAllowed;
  final bool clashDependencyAllowed;

  const SolarTermPublicIntegrationReadinessGuard()
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

/// 准入风险项
class SolarTermPublicIntegrationReadinessRisk {
  final String description;
  final String severity; // high | medium | low

  const SolarTermPublicIntegrationReadinessRisk({required this.description, this.severity = 'medium'});

  Map<String, dynamic> toJson() => {'description': description, 'severity': severity};
}

/// 准入决策
class SolarTermPublicIntegrationReadinessDecision {
  final String status; // blocked | insufficient_evidence | ready_for_design_review
  final String reason;
  final List<String> blockers;

  const SolarTermPublicIntegrationReadinessDecision({
    this.status = 'blocked', this.reason = '', this.blockers = const [],
  });

  Map<String, dynamic> toJson() => {'status': status, 'reason': reason, 'blockers': blockers};
}

/// 准入结果
class SolarTermPublicIntegrationReadinessResult {
  final String schemaVersion;
  final String? sampleName;
  final String dateRange;
  final String readinessStatus;
  final SolarTermPublicIntegrationReadinessDecision decision;
  final SolarTermPublicIntegrationReadinessChecklist checklist;
  final List<SolarTermPublicIntegrationReadinessRisk> riskList;
  final List<String> blockers;
  final List<String> warnings;
  final SolarTermPublicIntegrationReadinessGuard guard;
  final String conclusionNote;

  const SolarTermPublicIntegrationReadinessResult({
    this.schemaVersion = 'solar-term-public-integration-readiness-v0_36',
    this.sampleName,
    required this.dateRange,
    required this.readinessStatus,
    required this.decision,
    required this.checklist,
    this.riskList = const [],
    this.blockers = const [],
    this.warnings = const [],
    this.guard = const SolarTermPublicIntegrationReadinessGuard(),
    this.conclusionNote = 'readiness only, not public solar term capability',
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    if (sampleName != null) 'sampleName': sampleName,
    'dateRange': dateRange,
    'readinessStatus': readinessStatus,
    'decision': decision.toJson(),
    'checklist': checklist.toJson(),
    'riskList': riskList.map((r) => r.toJson()).toList(),
    'blockers': blockers,
    'warnings': warnings,
    'guardFlags': guard.toJson(),
    'conclusionNote': conclusionNote,
  };
}

/// 正式接入准入评估器
class SolarTermPublicIntegrationReadiness {
  const SolarTermPublicIntegrationReadiness();

  /// 构建 checklist
  SolarTermPublicIntegrationReadinessChecklist _buildChecklist(
    SolarTermTrialEvidenceSummary evidence,
    SolarTermPublicIntegrationReadinessGuard guard,
  ) {
    final items = <SolarTermPublicIntegrationReadinessCheckItem>[
      SolarTermPublicIntegrationReadinessCheckItem(id: 'trialEngineExists', title: 'Trial engine 存在', passed: true, severity: 'critical'),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'trialAuditorExists', title: 'Trial auditor 存在', passed: true, severity: 'critical'),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'trialObserverExists', title: 'Trial observer 存在', passed: true, severity: 'critical'),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'evidencePackageExists', title: 'Evidence package 存在', passed: true, severity: 'critical'),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'auditPassed', title: 'Audit 通过', passed: evidence.auditFailedCount == 0, severity: 'critical',
        note: evidence.auditFailedCount > 0 ? '${evidence.auditFailedCount} 天 audit 失败' : ''),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'observationAvailable', title: '观测数据可用', passed: evidence.totalDays > 0, severity: 'critical'),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'evidenceDecisionReady', title: '证据包决策通过', passed: evidence.decision.status == 'ready_for_next_evaluation', severity: 'critical'),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'noAuditFailure', title: '无 audit 失败', passed: evidence.auditFailedCount == 0, severity: 'high'),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'noHighRisk', title: '无 high risk', passed: evidence.riskList.every((r) => r.severity != 'high'), severity: 'high'),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'allGuardFlagsSafe', title: 'Guard flags 全部安全', passed: guard.allSafe, severity: 'critical'),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'noCalendarProviderIntegration', title: '不接入 CalendarProvider', passed: !guard.calendarProviderIntegration, severity: 'critical'),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'noPageDisplay', title: '不展示页面', passed: !guard.displayAllowed, severity: 'critical'),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'noShareExposure', title: '不展示分享', passed: !guard.shareAllowed, severity: 'critical'),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'noSnapshotWrite', title: '不写入 snapshot', passed: !guard.snapshotAllowed, severity: 'critical'),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'noGanzhiDependency', title: '不驱动干支', passed: !guard.ganzhiDependencyAllowed, severity: 'critical'),
      SolarTermPublicIntegrationReadinessCheckItem(id: 'noClashDependency', title: '不驱动冲煞', passed: !guard.clashDependencyAllowed, severity: 'critical'),
    ];
    return SolarTermPublicIntegrationReadinessChecklist(items: items);
  }

  /// 评估准入
  SolarTermPublicIntegrationReadinessResult assess({
    required SolarTermTrialEvidenceSummary evidence,
    String? sampleName,
  }) {
    final guard = const SolarTermPublicIntegrationReadinessGuard();
    final checklist = _buildChecklist(evidence, guard);
    final risks = <SolarTermPublicIntegrationReadinessRisk>[];
    final blockers = <String>[];
    final warnings = <String>[];

    // Decision logic
    String status;
    String reason;

    if (!guard.allSafe) {
      status = 'blocked';
      reason = 'Guard flags 不安全';
      blockers.add('guard_violation');
      risks.add(const SolarTermPublicIntegrationReadinessRisk(description: 'Guard flags 存在不安全项', severity: 'high'));
    } else if (evidence.decision.status == 'blocked') {
      status = 'blocked';
      reason = '证据包被 block';
      blockers.addAll(evidence.decision.blockingFactors);
    } else if (evidence.decision.status == 'insufficient_evidence') {
      status = 'insufficient_evidence';
      reason = '证据不足';
    } else if (evidence.auditFailedCount > 0) {
      status = 'blocked';
      reason = '存在 audit 失败';
      blockers.add('audit_failed: ${evidence.auditFailedCount}');
    } else if (evidence.totalDays <= 0) {
      status = 'insufficient_evidence';
      reason = '观测天数为 0';
    } else if (evidence.trialAvailableCount == 0 && evidence.trialUnavailableCount > 0) {
      status = 'insufficient_evidence';
      reason = 'trial 数据不可用';
    } else if (evidence.riskList.any((r) => r.severity == 'high')) {
      status = 'blocked';
      reason = '存在 high risk';
      blockers.add('high_risk_present');
    } else {
      status = 'ready_for_design_review';
      reason = '具备进入正式接入设计评审的资格';
    }

    for (final item in checklist.items) {
      if (!item.passed && item.severity == 'critical') {
        blockers.add(item.id);
      }
    }

    if (evidence.trialAvailableCount == 0 && status != 'insufficient_evidence') {
      warnings.add('trial 数据不可用，观测结果参考价值有限');
    }

    return SolarTermPublicIntegrationReadinessResult(
      sampleName: sampleName,
      dateRange: evidence.dateRange,
      readinessStatus: status,
      decision: SolarTermPublicIntegrationReadinessDecision(status: status, reason: reason, blockers: blockers),
      checklist: checklist,
      riskList: risks,
      blockers: blockers,
      warnings: warnings,
    );
  }

  Map<String, dynamic> buildDebugJson() => {
    'schemaVersion': 'solar-term-public-integration-readiness-debug-v0_36',
    'readinessEnabled': true,
    'sampleName': null,
    'dateRange': null,
    'readinessStatus': 'blocked',
    'checklistPassedCount': 0,
    'checklistFailedCount': 0,
    'blockers': [],
    'warnings': [],
    'riskList': [],
    'guardFlags': const SolarTermPublicIntegrationReadinessGuard().toJson(),
    'conclusionNote': 'readiness only, not public solar term capability',
  };
}

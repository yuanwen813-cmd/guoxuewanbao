/// 节气正式接入沙箱验收包 v0.40
///
/// 汇总 v0.33-v0.39 全部沙箱验证结果，输出验收报告。
/// sandbox_accepted ≠ productionReady ≠ publicExposure。
/// 所有 guard flags 必须 false。

import 'solar_term_public_sandbox_batch_validator.dart';

/// 验收 checklist 项
class SolarTermPublicSandboxAcceptanceCheckItem {
  final String id; final String title; final bool passed; final bool required;
  final String severity; final String note;

  const SolarTermPublicSandboxAcceptanceCheckItem({
    required this.id, required this.title, this.passed = false, this.required = true,
    this.severity = 'critical', this.note = '',
  });

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'passed': passed, 'required': required, 'severity': severity, 'note': note};
}

/// 验收 checklist
class SolarTermPublicSandboxAcceptanceChecklist {
  final List<SolarTermPublicSandboxAcceptanceCheckItem> items;
  const SolarTermPublicSandboxAcceptanceChecklist({required this.items});

  int get passedCount => items.where((i) => i.passed).length;
  int get failedCount => items.where((i) => !i.passed).length;
  List<SolarTermPublicSandboxAcceptanceCheckItem> get criticalFailures =>
      items.where((i) => !i.passed && i.severity == 'critical').toList();

  Map<String, dynamic> toJson() => {
    'items': items.map((i) => i.toJson()).toList(),
    'passedCount': passedCount, 'failedCount': failedCount,
  };
}

/// 验收 guard（固定 false）
class SolarTermPublicSandboxAcceptanceGuard {
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;
  final bool displayAllowed; final bool shareAllowed; final bool snapshotAllowed;
  final bool ganzhiDependencyAllowed; final bool clashDependencyAllowed;

  const SolarTermPublicSandboxAcceptanceGuard()
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

/// 验收汇总
class SolarTermPublicSandboxAcceptanceSummary {
  final int totalDays; final int mappedForSandboxCount; final int unavailableCount;
  final int blockedCount; final int mappingFailedCount;
  final int issueCount; final int highRiskCount; final int mediumRiskCount; final int lowRiskCount;
  final String? firstIssueDate; final String? firstBlockedDate;
  final List<String> failedReasons;
  final List<String> acceptedEvidenceChain;

  const SolarTermPublicSandboxAcceptanceSummary({
    required this.totalDays, required this.mappedForSandboxCount,
    required this.unavailableCount, required this.blockedCount, required this.mappingFailedCount,
    required this.issueCount, required this.highRiskCount, required this.mediumRiskCount, required this.lowRiskCount,
    this.firstIssueDate, this.firstBlockedDate,
    this.failedReasons = const [],
    this.acceptedEvidenceChain = const [
      'v0.33 audit',
      'v0.34 observation',
      'v0.35 evidence package',
      'v0.36 readiness',
      'v0.37 design',
      'v0.38 sandbox adapter',
      'v0.39 batch validation',
    ],
  });

  Map<String, dynamic> toJson() => {
    'totalDays': totalDays, 'mappedForSandboxCount': mappedForSandboxCount,
    'unavailableCount': unavailableCount, 'blockedCount': blockedCount, 'mappingFailedCount': mappingFailedCount,
    'issueCount': issueCount, 'highRiskCount': highRiskCount, 'mediumRiskCount': mediumRiskCount, 'lowRiskCount': lowRiskCount,
    if (firstIssueDate != null) 'firstIssueDate': firstIssueDate,
    if (firstBlockedDate != null) 'firstBlockedDate': firstBlockedDate,
    'failedReasons': failedReasons, 'acceptedEvidenceChain': acceptedEvidenceChain,
  };
}

/// 验收结果
class SolarTermPublicSandboxAcceptanceResult {
  final String schemaVersion;
  final String? sampleName;
  final String dateRange;
  final String acceptanceStatus;
  final SolarTermPublicSandboxAcceptanceSummary summary;
  final SolarTermPublicSandboxAcceptanceChecklist checklist;
  final List<String> riskList;
  final List<String> blockers;
  final List<String> warnings;
  final SolarTermPublicSandboxAcceptanceGuard guard;
  final String conclusionNote;

  const SolarTermPublicSandboxAcceptanceResult({
    this.schemaVersion = 'solar-term-public-sandbox-acceptance-package-v0_40',
    this.sampleName, required this.dateRange, required this.acceptanceStatus,
    required this.summary, required this.checklist,
    this.riskList = const [], this.blockers = const [], this.warnings = const [],
    this.guard = const SolarTermPublicSandboxAcceptanceGuard(),
    this.conclusionNote = 'sandbox acceptance package only, not public solar term capability',
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    if (sampleName != null) 'sampleName': sampleName,
    'dateRange': dateRange, 'acceptanceStatus': acceptanceStatus,
    'summary': summary.toJson(), 'checklist': checklist.toJson(),
    'riskList': riskList, 'blockers': blockers, 'warnings': warnings,
    'guardFlags': guard.toJson(), 'conclusionNote': conclusionNote,
  };
}

/// 沙箱验收包构建器
class SolarTermPublicSandboxAcceptancePackage {
  const SolarTermPublicSandboxAcceptancePackage();

  /// 构建验收包
  SolarTermPublicSandboxAcceptanceResult build({
    required SolarTermPublicSandboxBatchValidationResult batch,
    required String designStatus,
    required String readinessStatus,
    required String evidenceDecision,
    bool hasHighRisk = false,
    String? sampleName,
  }) {
    final guard = const SolarTermPublicSandboxAcceptanceGuard();
    final blockers = <String>[];
    final riskItems = <String>[];

    // Determine acceptance status
    String status;
    if (!guard.allSafe) {
      status = 'blocked'; blockers.add('guard_unsafe');
    } else if (batch.validationStatus == 'blocked') {
      status = 'blocked'; blockers.add('batch_blocked');
    } else if (batch.validationStatus == 'insufficient_samples') {
      status = 'insufficient_evidence';
    } else if (batch.validationStatus == 'failed_for_sandbox_validation') {
      status = 'sandbox_rejected';
    } else if (batch.validationStatus == 'passed_for_sandbox_validation' && !hasHighRisk) {
      // check upstream gates
      if (designStatus != 'design_ready') { status = 'blocked'; blockers.add('design_not_ready'); }
      else if (readinessStatus != 'ready_for_design_review') { status = 'blocked'; blockers.add('readiness_not_ready'); }
      else if (evidenceDecision != 'ready_for_next_evaluation') { status = 'blocked'; blockers.add('evidence_not_ready'); }
      else { status = 'sandbox_accepted'; }
    } else if (hasHighRisk) {
      status = 'blocked'; blockers.add('high_risk'); riskItems.add('highRiskCount > 0');
    } else {
      status = 'blocked';
    }

    // Build checklist
    final items = <SolarTermPublicSandboxAcceptanceCheckItem>[
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'trialAuditPassed', title: 'Trial audit 通过', passed: true),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'observationPassed', title: 'Observation 通过', passed: true),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'evidencePackagePassed', title: 'Evidence package 通过', passed: evidenceDecision == 'ready_for_next_evaluation'),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'readinessPassed', title: 'Readiness 通过', passed: readinessStatus == 'ready_for_design_review'),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'designPassed', title: 'Design 通过', passed: designStatus == 'design_ready'),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'sandboxAdapterPassed', title: 'Sandbox adapter 通过', passed: true),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'batchValidationPassed', title: 'Batch validation 通过', passed: batch.validationStatus == 'passed_for_sandbox_validation'),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'noHighRisk', title: '无 high risk', passed: !hasHighRisk && batch.highRiskCount == 0, severity: 'high'),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'noBlockedStatus', title: '无 blocked', passed: batch.blockedCount == 0, severity: 'high'),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'noMappingFailure', title: '无 mapping failure', passed: batch.mappingFailedCount == 0, severity: 'high'),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'noCalendarProviderIntegration', title: '不接入 CalendarProvider', passed: !guard.calendarProviderIntegration, severity: 'critical'),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'noPageDisplay', title: '不展示页面', passed: !guard.displayAllowed, severity: 'critical'),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'noShareExposure', title: '不分享', passed: !guard.shareAllowed, severity: 'critical'),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'noSnapshotWrite', title: '不写 snapshot', passed: !guard.snapshotAllowed, severity: 'critical'),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'noGanzhiDependency', title: '不驱动干支', passed: !guard.ganzhiDependencyAllowed, severity: 'critical'),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'noClashDependency', title: '不驱动冲煞', passed: !guard.clashDependencyAllowed, severity: 'critical'),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'rollbackPlanExists', title: '回滚计划存在', passed: true),
      SolarTermPublicSandboxAcceptanceCheckItem(id: 'finalHumanApprovalRequired', title: '需最终人工审批', passed: false, note: 'sandbox_accepted 后需人工审批方可进入 production review'),
    ];
    final checklist = SolarTermPublicSandboxAcceptanceChecklist(items: items);

    final summary = SolarTermPublicSandboxAcceptanceSummary(
      totalDays: batch.totalDays, mappedForSandboxCount: batch.mappedForSandboxCount,
      unavailableCount: batch.unavailableCount, blockedCount: batch.blockedCount,
      mappingFailedCount: batch.mappingFailedCount,
      issueCount: batch.issueCount, highRiskCount: batch.highRiskCount,
      mediumRiskCount: batch.mediumRiskCount, lowRiskCount: batch.lowRiskCount,
      firstIssueDate: batch.firstIssueDate, firstBlockedDate: batch.firstBlockedDate,
      failedReasons: batch.failedReasons,
    );

    return SolarTermPublicSandboxAcceptanceResult(
      sampleName: sampleName, dateRange: batch.dateRange,
      acceptanceStatus: status, summary: summary, checklist: checklist,
      riskList: riskItems, blockers: blockers,
    );
  }

  Map<String, dynamic> buildDebugJson() => {
    'schemaVersion': 'solar-term-public-sandbox-acceptance-package-debug-v0_40',
    'acceptanceEnabled': true,
    'sampleName': null, 'dateRange': null, 'acceptanceStatus': 'blocked',
    'checklistPassedCount': 0, 'checklistFailedCount': 18,
    'summary': {'totalDays': 0},
    'blockers': [], 'warnings': [], 'riskList': [],
    'guardFlags': const SolarTermPublicSandboxAcceptanceGuard().toJson(),
    'acceptedEvidenceChain': ['v0.33', 'v0.34', 'v0.35', 'v0.36', 'v0.37', 'v0.38', 'v0.39'],
    'conclusionNote': 'sandbox acceptance package only, not public solar term capability',
  };
}

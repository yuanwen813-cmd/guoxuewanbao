/// 节气正式接入沙箱批量验证器 v0.39
///
/// 批量验证 sandbox adapter 的字段映射质量、状态分布、失败原因和 guard 安全性。
/// passed_for_sandbox_validation ≠ productionReady ≠ publicExposure。
/// 所有 guard flags 必须 false。

import 'solar_term_public_sandbox_adapter.dart';
import 'solar_term_trial_engine.dart';

/// 批量验证 guard（固定 false）
class SolarTermPublicSandboxBatchValidationGuard {
  final bool productionReady, publicExposure, calendarProviderIntegration;
  final bool displayAllowed, shareAllowed, snapshotAllowed;
  final bool ganzhiDependencyAllowed, clashDependencyAllowed;

  const SolarTermPublicSandboxBatchValidationGuard()
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

/// 批量验证结果
class SolarTermPublicSandboxBatchValidationResult {
  final String schemaVersion;
  final String? sampleName;
  final String dateRange;
  final int totalDays;
  final int mappedForSandboxCount;
  final int unavailableCount;
  final int blockedCount;
  final int mappingFailedCount;
  final Map<String, int> statusDistribution;
  final int issueCount;
  final int highRiskCount;
  final int mediumRiskCount;
  final int lowRiskCount;
  final String? firstIssueDate;
  final String? firstBlockedDate;
  final List<String> failedReasons;
  final List<SolarTermPublicSandboxMappingIssue> issues;
  final List<String> riskList;
  final SolarTermPublicSandboxBatchValidationGuard guard;
  final String validationStatus;
  final String conclusionNote;

  const SolarTermPublicSandboxBatchValidationResult({
    this.schemaVersion = 'solar-term-public-sandbox-batch-validation-v0_39',
    this.sampleName, required this.dateRange, required this.totalDays,
    required this.mappedForSandboxCount, required this.unavailableCount,
    required this.blockedCount, required this.mappingFailedCount,
    this.statusDistribution = const {}, required this.issueCount,
    required this.highRiskCount, required this.mediumRiskCount, required this.lowRiskCount,
    this.firstIssueDate, this.firstBlockedDate,
    this.failedReasons = const [], this.issues = const [], this.riskList = const [],
    this.guard = const SolarTermPublicSandboxBatchValidationGuard(),
    required this.validationStatus,
    this.conclusionNote = 'sandbox batch validation only, not public solar term capability',
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    if (sampleName != null) 'sampleName': sampleName,
    'dateRange': dateRange, 'totalDays': totalDays,
    'mappedForSandboxCount': mappedForSandboxCount, 'unavailableCount': unavailableCount,
    'blockedCount': blockedCount, 'mappingFailedCount': mappingFailedCount,
    'statusDistribution': statusDistribution, 'issueCount': issueCount,
    'highRiskCount': highRiskCount, 'mediumRiskCount': mediumRiskCount, 'lowRiskCount': lowRiskCount,
    if (firstIssueDate != null) 'firstIssueDate': firstIssueDate,
    if (firstBlockedDate != null) 'firstBlockedDate': firstBlockedDate,
    'failedReasons': failedReasons, 'riskList': riskList,
    'guardFlags': guard.toJson(), 'validationStatus': validationStatus,
    'conclusionNote': conclusionNote,
  };
}

/// 批量验证器
class SolarTermPublicSandboxBatchValidator {
  final SolarTermTrialEngine engine;
  final SolarTermPublicSandboxAdapter adapter;

  const SolarTermPublicSandboxBatchValidator({this.engine = const SolarTermTrialEngine(), this.adapter = const SolarTermPublicSandboxAdapter()});

  /// 批量验证日期范围
  Future<SolarTermPublicSandboxBatchValidationResult> validate({
    required String designStatus,
    required DateTime startDate,
    required DateTime endDate,
    String? sampleName,
  }) async {
    final guard = const SolarTermPublicSandboxBatchValidationGuard();
    final statusDist = <String, int>{};
    final allIssues = <SolarTermPublicSandboxMappingIssue>[];
    final failedReasons = <String>{};
    final riskItems = <String>[];
    String? firstIssue, firstBlocked;

    int total = 0, mapped = 0, unavailable = 0, blocked = 0, mappingFailed = 0;
    int highRisk = 0, mediumRisk = 0, lowRisk = 0;

    for (var d = startDate; !d.isAfter(endDate); d = d.add(const Duration(days: 1))) {
      total++;
      final trial = await engine.getTrialSolarTermForDate(d);
      final dateKey = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final sandbox = adapter.adapt(trial: trial, designStatus: designStatus, date: dateKey);

      statusDist[sandbox.sandboxStatus] = (statusDist[sandbox.sandboxStatus] ?? 0) + 1;

      switch (sandbox.sandboxStatus) {
        case 'mapped_for_sandbox': mapped++; break;
        case 'unavailable': unavailable++; break;
        case 'blocked': blocked++; firstBlocked ??= dateKey; break;
        case 'mapping_failed': mappingFailed++; break;
      }

      for (final issue in sandbox.mappingIssues) {
        allIssues.add(issue);
        firstIssue ??= dateKey;
        switch (issue.severity) {
          case 'high': highRisk++; riskItems.add('${issue.field}: ${issue.reason}'); break;
          case 'medium': mediumRisk++; break;
          default: lowRisk++; break;
        }
      }
      for (final b in sandbox.blockers) {
        failedReasons.add(b);
      }
    }

    // Determine validation status
    String vStatus;
    if (total <= 0) {
      vStatus = 'insufficient_samples';
    } else if (designStatus != 'design_ready') {
      vStatus = 'blocked';
    } else if (!guard.allSafe) {
      vStatus = 'blocked';
    } else if (blocked > 0) {
      vStatus = 'blocked';
    } else if (highRisk > 0) {
      vStatus = 'blocked';
    } else if (mappingFailed > 0) {
      vStatus = 'failed_for_sandbox_validation';
    } else if (mapped > 0) {
      vStatus = 'passed_for_sandbox_validation';
    } else {
      vStatus = 'insufficient_samples';
    }

    return SolarTermPublicSandboxBatchValidationResult(
      sampleName: sampleName,
      dateRange: '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}'
          ' ~ ${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}',
      totalDays: total,
      mappedForSandboxCount: mapped, unavailableCount: unavailable,
      blockedCount: blocked, mappingFailedCount: mappingFailed,
      statusDistribution: statusDist,
      issueCount: allIssues.length,
      highRiskCount: highRisk, mediumRiskCount: mediumRisk, lowRiskCount: lowRisk,
      firstIssueDate: firstIssue, firstBlockedDate: firstBlocked,
      failedReasons: failedReasons.toList(),
      issues: allIssues, riskList: riskItems,
      validationStatus: vStatus,
    );
  }

  Map<String, dynamic> buildDebugJson() => {
    'schemaVersion': 'solar-term-public-sandbox-batch-validation-debug-v0_39',
    'batchValidationEnabled': true,
    'sampleName': null, 'dateRange': null, 'validationStatus': 'insufficient_samples',
    'totalDays': 0,
    'mappedForSandboxCount': 0, 'unavailableCount': 0, 'blockedCount': 0, 'mappingFailedCount': 0,
    'issueCount': 0, 'riskList': [], 'failedReasons': [],
    'guardFlags': const SolarTermPublicSandboxBatchValidationGuard().toJson(),
    'conclusionNote': 'sandbox batch validation only, not public solar term capability',
  };
}

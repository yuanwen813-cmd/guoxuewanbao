/// 节气试运行样本观测器 v0.34
///
/// 批量观测指定日期范围内的 trial result 和 audit result。
/// 只读、不公开、不驱动任何正式能力。

import 'solar_term_trial_engine.dart';
import 'solar_term_trial_result_auditor.dart';

/// 单日观测记录
class SolarTermTrialObservation {
  final DateTime date;
  final SolarTermTrialResult trialResult;
  final SolarTermTrialResultAuditOutput auditResult;

  const SolarTermTrialObservation({
    required this.date,
    required this.trialResult,
    required this.auditResult,
  });

  bool get hasTrial => trialResult.available;
  bool get auditOk => auditResult.passed;
}

/// 观测问题记录
class SolarTermTrialObservationIssue {
  final DateTime date;
  final String reason;
  final String severity; // violation | warning

  const SolarTermTrialObservationIssue({required this.date, required this.reason, this.severity = 'violation'});
}

/// 观测汇总
class SolarTermTrialObservationSummary {
  final String schemaVersion;
  final String? sampleName;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final int trialAvailableCount;
  final int trialUnavailableCount;
  final int blockedCount;
  final int auditPassedCount;
  final int auditFailedCount;
  final Map<String, int> statusDistribution;
  final List<String> failedReasons;
  final DateTime? firstFailedDate;
  final List<SolarTermTrialObservationIssue> issues;
  final bool productionReady;
  final bool publicExposure;
  final bool calendarProviderIntegration;
  final bool displayAllowed;
  final bool shareAllowed;
  final bool snapshotAllowed;
  final bool ganzhiDependencyAllowed;
  final bool clashDependencyAllowed;
  final List<SolarTermTrialObservation> observations;

  const SolarTermTrialObservationSummary({
    this.schemaVersion = 'solar-term-trial-observation-v0_34',
    this.sampleName,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.trialAvailableCount,
    required this.trialUnavailableCount,
    required this.blockedCount,
    required this.auditPassedCount,
    required this.auditFailedCount,
    this.statusDistribution = const {},
    this.failedReasons = const [],
    this.firstFailedDate,
    this.issues = const [],
    this.productionReady = false,
    this.publicExposure = false,
    this.calendarProviderIntegration = false,
    this.displayAllowed = false,
    this.shareAllowed = false,
    this.snapshotAllowed = false,
    this.ganzhiDependencyAllowed = false,
    this.clashDependencyAllowed = false,
    this.observations = const [],
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    if (sampleName != null) 'sampleName': sampleName,
    'startDate': '${startDate.year}-${startDate.month.toString().padLeft(2,'0')}-${startDate.day.toString().padLeft(2,'0')}',
    'endDate': '${endDate.year}-${endDate.month.toString().padLeft(2,'0')}-${endDate.day.toString().padLeft(2,'0')}',
    'totalDays': totalDays,
    'trialAvailableCount': trialAvailableCount,
    'trialUnavailableCount': trialUnavailableCount,
    'blockedCount': blockedCount,
    'auditPassedCount': auditPassedCount,
    'auditFailedCount': auditFailedCount,
    'statusDistribution': statusDistribution,
    'failedReasons': failedReasons,
    if (firstFailedDate != null) 'firstFailedDate': firstFailedDate!.toIso8601String(),
    'issueCount': issues.length,
    'productionReady': productionReady,
    'publicExposure': publicExposure,
    'calendarProviderIntegration': calendarProviderIntegration,
    'displayAllowed': displayAllowed,
    'shareAllowed': shareAllowed,
    'snapshotAllowed': snapshotAllowed,
    'ganzhiDependencyAllowed': ganzhiDependencyAllowed,
    'clashDependencyAllowed': clashDependencyAllowed,
  };
}

class SolarTermTrialObserver {
  final SolarTermTrialEngine engine;
  final SolarTermTrialResultAuditor auditor;

  const SolarTermTrialObserver({required this.engine, this.auditor = const SolarTermTrialResultAuditor()});

  /// 批量观测日期范围
  Future<SolarTermTrialObservationSummary> observe(DateTime startDate, DateTime endDate, {String? sampleName}) async {
    final observations = <SolarTermTrialObservation>[];
    final issues = <SolarTermTrialObservationIssue>[];
    final statusDist = <String, int>{};
    final failedReasons = <String>{};
    DateTime? firstFailed;

    int available = 0, unavailable = 0, blocked = 0, auditPassed = 0, auditFailed = 0;
    int total = 0;

    for (var d = startDate; !d.isAfter(endDate); d = d.add(const Duration(days: 1))) {
      total++;
      final trial = await engine.getTrialSolarTermForDate(d);
      final audit = auditor.audit(trial);

      observations.add(SolarTermTrialObservation(date: d, trialResult: trial, auditResult: audit));

      // status distribution
      statusDist[trial.status] = (statusDist[trial.status] ?? 0) + 1;

      if (trial.available) {
        available++;
      } else {
        unavailable++;
        if (trial.status == 'blocked') blocked++;
      }

      if (audit.passed) {
        auditPassed++;
      } else {
        auditFailed++;
        firstFailed ??= d;
        for (final v in audit.findings.violations) {
          failedReasons.add(v);
          issues.add(SolarTermTrialObservationIssue(date: d, reason: v, severity: 'violation'));
        }
        for (final w in audit.findings.warnings) {
          issues.add(SolarTermTrialObservationIssue(date: d, reason: w, severity: 'warning'));
        }
      }
    }

    return SolarTermTrialObservationSummary(
      sampleName: sampleName,
      startDate: startDate, endDate: endDate,
      totalDays: total,
      trialAvailableCount: available,
      trialUnavailableCount: unavailable,
      blockedCount: blocked,
      auditPassedCount: auditPassed,
      auditFailedCount: auditFailed,
      statusDistribution: statusDist,
      failedReasons: failedReasons.toList(),
      firstFailedDate: firstFailed,
      issues: issues,
      observations: observations,
    );
  }

  Map<String, dynamic> buildDebugJson() => {
    'schemaVersion': 'solar-term-trial-observation-debug-v0_34',
    'trialObservationEnabled': true,
    'sampleName': null,
    'dateRange': null,
    'totalDays': 0,
    'auditPassedCount': 0,
    'auditFailedCount': 0,
    'failedReasons': [],
    'productionReady': false,
    'publicExposure': false,
    'calendarProviderIntegration': false,
    'displayAllowed': false,
    'shareAllowed': false,
    'snapshotAllowed': false,
    'ganzhiDependencyAllowed': false,
    'clashDependencyAllowed': false,
    'calendarProviderSupportsSolarTerm': false,
    'pageDisplaysSolarTerm': false,
    'shareDisplaysSolarTerm': false,
    'note': 'trial observation only, not public solar term capability',
  };
}

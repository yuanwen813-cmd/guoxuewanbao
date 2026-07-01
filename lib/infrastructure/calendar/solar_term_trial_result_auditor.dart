/// 节气试运行结果审计器 v0.33
///
/// 对 SolarTermTrialResult 进行安全审计，确保 trial 结果不会被误用。

import 'solar_term_trial_engine.dart';

enum TrialAuditStatus { audit_passed, audit_failed }

class TrialAuditFindings {
  final List<String> violations;
  final List<String> warnings;
  bool get hasViolations => violations.isNotEmpty;

  const TrialAuditFindings({this.violations = const [], this.warnings = const []});
}

class SolarTermTrialResultAuditOutput {
  final String schemaVersion;
  final String status; // audit_passed | audit_failed
  final bool passed;
  final TrialAuditFindings findings;
  final SolarTermTrialResult result;

  const SolarTermTrialResultAuditOutput({
    this.schemaVersion = 'solar-term-trial-result-audit-v0_33',
    required this.status,
    required this.passed,
    required this.findings,
    required this.result,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'status': status, 'passed': passed,
    'violations': findings.violations, 'warnings': findings.warnings,
    'result': result.toJson(),
  };
}

class SolarTermTrialResultAuditor {
  static const forbiddenSources = ['production', 'public', 'official_enabled'];
  static const requiredSourcePatterns = ['trial', 'candidate'];

  const SolarTermTrialResultAuditor();

  TrialAuditFindings auditResult(SolarTermTrialResult r) {
    final v = <String>[];

    // status checks
    if (r.available && r.status != 'trial_only') {
      v.add('available=true 但 status 不是 trial_only: ${r.status}');
    }
    if (!r.available && !['unavailable', 'blocked', 'none'].contains(r.status)) {
      v.add('available=false 但 status 非法: ${r.status}');
    }

    // safety flag checks
    if (r.productionReady) v.add('productionReady=true，trial result 禁止设为 true');
    if (r.publicExposure) v.add('publicExposure=true，trial result 禁止设为 true');
    if (r.calendarProviderIntegration) v.add('calendarProviderIntegration=true，trial result 禁止设为 true');
    if (r.displayAllowed) v.add('displayAllowed=true，trial result 禁止页面展示');
    if (r.shareAllowed) v.add('shareAllowed=true，trial result 禁止分享展示');
    if (r.snapshotAllowed) v.add('snapshotAllowed=true，trial result 禁止写入 snapshot');
    if (r.ganzhiDependencyAllowed) v.add('ganzhiDependencyAllowed=true，trial result 禁止驱动干支');
    if (r.clashDependencyAllowed) v.add('clashDependencyAllowed=true，trial result 禁止驱动冲煞');

    // source checks
    final srcLower = r.source.toLowerCase();
    for (final f in forbiddenSources) {
      if (srcLower.contains(f)) v.add('source 包含禁止标识: $f');
    }
    bool hasRequired = false;
    for (final p in requiredSourcePatterns) {
      if (srcLower.contains(p)) { hasRequired = true; break; }
    }
    if (!hasRequired) v.add('source 缺少 trial/candidate 标识: ${r.source}');

    return TrialAuditFindings(violations: v);
  }

  SolarTermTrialResultAuditOutput audit(SolarTermTrialResult r) {
    final f = auditResult(r);
    final passed = !f.hasViolations;
    return SolarTermTrialResultAuditOutput(
      status: passed ? 'audit_passed' : 'audit_failed',
      passed: passed, findings: f, result: r,
    );
  }

  Map<String, dynamic> buildDebugJson() => {
    'schemaVersion': 'solar-term-trial-result-audit-debug-v0_33',
    'trialResultAuditEnabled': true,
    'auditPassed': false,
    'productionReady': false,
    'publicExposure': false,
    'calendarProviderIntegration': false,
    'calendarProviderSupportsSolarTerm': false,
    'pageDisplaysSolarTerm': false,
    'shareDisplaysSolarTerm': false,
    'blockedReasons': {
      'solarTerm': 'v0.33 仅审计节气试运行结果，不公开节气能力',
      'monthGanzhi': '月干支仍依赖正式验收后的节气能力',
      'clash': '冲煞依赖更完整传统历法规则',
    },
  };
}

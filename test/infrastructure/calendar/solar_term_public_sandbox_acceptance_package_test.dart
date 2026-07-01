import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_sandbox_acceptance_package.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_sandbox_batch_validator.dart';

void main() {
  final pkg = const SolarTermPublicSandboxAcceptancePackage();

  SolarTermPublicSandboxBatchValidationResult _batch(String vStatus, {int blocked = 0, int mapped = 3, int highRisk = 0, int mappingFailed = 0}) {
    return SolarTermPublicSandboxBatchValidationResult(
      dateRange: '2026-06-22 ~ 2026-06-24', totalDays: 3,
      mappedForSandboxCount: mapped, unavailableCount: 0, blockedCount: blocked,
      mappingFailedCount: mappingFailed, issueCount: 0,
      highRiskCount: highRisk, mediumRiskCount: 0, lowRiskCount: 0,
      statusDistribution: {}, validationStatus: vStatus,
    );
  }

  group('acceptance generation', () {
    test('can generate acceptance package', () {
      final r = pkg.build(batch: _batch('passed_for_sandbox_validation'), designStatus: 'design_ready', readinessStatus: 'ready_for_design_review', evidenceDecision: 'ready_for_next_evaluation', sampleName: 'test');
      expect(r.schemaVersion, 'solar-term-public-sandbox-acceptance-package-v0_40');
      expect(r.sampleName, 'test');
    });
    test('dateRange correct', () {
      final r = pkg.build(batch: _batch('passed_for_sandbox_validation'), designStatus: 'design_ready', readinessStatus: 'ready_for_design_review', evidenceDecision: 'ready_for_next_evaluation');
      expect(r.dateRange, '2026-06-22 ~ 2026-06-24');
    });
  });

  group('acceptanceStatus rules', () {
    test('batch blocked → blocked', () {
      final r = pkg.build(batch: _batch('blocked'), designStatus: 'design_ready', readinessStatus: 'ready_for_design_review', evidenceDecision: 'ready_for_next_evaluation');
      expect(r.acceptanceStatus, 'blocked');
    });
    test('batch insufficient → insufficient_evidence', () {
      final r = pkg.build(batch: _batch('insufficient_samples'), designStatus: 'design_ready', readinessStatus: 'ready_for_design_review', evidenceDecision: 'ready_for_next_evaluation');
      expect(r.acceptanceStatus, 'insufficient_evidence');
    });
    test('batch failed → sandbox_rejected', () {
      final r = pkg.build(batch: _batch('failed_for_sandbox_validation'), designStatus: 'design_ready', readinessStatus: 'ready_for_design_review', evidenceDecision: 'ready_for_next_evaluation');
      expect(r.acceptanceStatus, 'sandbox_rejected');
    });
    test('batch passed + gates ok → sandbox_accepted', () {
      final r = pkg.build(batch: _batch('passed_for_sandbox_validation'), designStatus: 'design_ready', readinessStatus: 'ready_for_design_review', evidenceDecision: 'ready_for_next_evaluation');
      expect(r.acceptanceStatus, 'sandbox_accepted');
    });
    test('design not ready → blocked', () {
      final r = pkg.build(batch: _batch('passed_for_sandbox_validation'), designStatus: 'blocked', readinessStatus: 'ready_for_design_review', evidenceDecision: 'ready_for_next_evaluation');
      expect(r.acceptanceStatus, 'blocked');
    });
    test('readiness not ready → blocked', () {
      final r = pkg.build(batch: _batch('passed_for_sandbox_validation'), designStatus: 'design_ready', readinessStatus: 'blocked', evidenceDecision: 'ready_for_next_evaluation');
      expect(r.acceptanceStatus, 'blocked');
    });
    test('evidence not ready → blocked', () {
      final r = pkg.build(batch: _batch('passed_for_sandbox_validation'), designStatus: 'design_ready', readinessStatus: 'ready_for_design_review', evidenceDecision: 'blocked');
      expect(r.acceptanceStatus, 'blocked');
    });
    test('highRisk → blocked', () {
      final r = pkg.build(batch: _batch('passed_for_sandbox_validation'), designStatus: 'design_ready', readinessStatus: 'ready_for_design_review', evidenceDecision: 'ready_for_next_evaluation', hasHighRisk: true);
      expect(r.acceptanceStatus, 'blocked');
    });
  });

  group('checklist', () {
    final r = pkg.build(batch: _batch('passed_for_sandbox_validation'), designStatus: 'design_ready', readinessStatus: 'ready_for_design_review', evidenceDecision: 'ready_for_next_evaluation');
    final ids = r.checklist.items.map((i) => i.id).toSet();
    test('trialAuditPassed', () => expect(ids.contains('trialAuditPassed'), true));
    test('observationPassed', () => expect(ids.contains('observationPassed'), true));
    test('evidencePackagePassed', () => expect(ids.contains('evidencePackagePassed'), true));
    test('readinessPassed', () => expect(ids.contains('readinessPassed'), true));
    test('designPassed', () => expect(ids.contains('designPassed'), true));
    test('sandboxAdapterPassed', () => expect(ids.contains('sandboxAdapterPassed'), true));
    test('batchValidationPassed', () => expect(ids.contains('batchValidationPassed'), true));
    test('noCalendarProviderIntegration', () => expect(ids.contains('noCalendarProviderIntegration'), true));
    test('noPageDisplay', () => expect(ids.contains('noPageDisplay'), true));
    test('noShareExposure', () => expect(ids.contains('noShareExposure'), true));
    test('noSnapshotWrite', () => expect(ids.contains('noSnapshotWrite'), true));
    test('noGanzhiDependency', () => expect(ids.contains('noGanzhiDependency'), true));
    test('noClashDependency', () => expect(ids.contains('noClashDependency'), true));
    test('rollbackPlanExists', () => expect(ids.contains('rollbackPlanExists'), true));
    test('finalHumanApprovalRequired', () => expect(ids.contains('finalHumanApprovalRequired'), true));
    test('18 items total', () => expect(r.checklist.items.length, 18));
  });

  group('summary', () {
    final r = pkg.build(batch: _batch('passed_for_sandbox_validation'), designStatus: 'design_ready', readinessStatus: 'ready_for_design_review', evidenceDecision: 'ready_for_next_evaluation');
    test('totalDays', () => expect(r.summary.totalDays, 3));
    test('mappedForSandboxCount', () => expect(r.summary.mappedForSandboxCount, 3));
    test('issueCount', () => expect(r.summary.issueCount, 0));
    test('evidence chain has 7 items', () => expect(r.summary.acceptedEvidenceChain.length, 7));
    test('v0.33 in chain', () => expect(r.summary.acceptedEvidenceChain.any((e) => e.contains('v0.33')), true));
    test('v0.34 in chain', () => expect(r.summary.acceptedEvidenceChain.any((e) => e.contains('v0.34')), true));
    test('v0.35 in chain', () => expect(r.summary.acceptedEvidenceChain.any((e) => e.contains('v0.35')), true));
    test('v0.36 in chain', () => expect(r.summary.acceptedEvidenceChain.any((e) => e.contains('v0.36')), true));
    test('v0.37 in chain', () => expect(r.summary.acceptedEvidenceChain.any((e) => e.contains('v0.37')), true));
    test('v0.38 in chain', () => expect(r.summary.acceptedEvidenceChain.any((e) => e.contains('v0.38')), true));
    test('v0.39 in chain', () => expect(r.summary.acceptedEvidenceChain.any((e) => e.contains('v0.39')), true));
  });

  group('guard flags', () {
    final r = pkg.build(batch: _batch('passed_for_sandbox_validation'), designStatus: 'design_ready', readinessStatus: 'ready_for_design_review', evidenceDecision: 'ready_for_next_evaluation');
    test('productionReady', () => expect(r.guard.productionReady, false));
    test('publicExposure', () => expect(r.guard.publicExposure, false));
    test('calProvider', () => expect(r.guard.calendarProviderIntegration, false));
    test('display', () => expect(r.guard.displayAllowed, false));
    test('share', () => expect(r.guard.shareAllowed, false));
    test('snapshot', () => expect(r.guard.snapshotAllowed, false));
    test('ganzhi', () => expect(r.guard.ganzhiDependencyAllowed, false));
    test('clash', () => expect(r.guard.clashDependencyAllowed, false));
  });

  group('sandbox_accepted guards', () {
    final r = pkg.build(batch: _batch('passed_for_sandbox_validation'), designStatus: 'design_ready', readinessStatus: 'ready_for_design_review', evidenceDecision: 'ready_for_next_evaluation');
    test('status is sandbox_accepted', () => expect(r.acceptanceStatus, 'sandbox_accepted'));
    test('prodReady false', () => expect(r.guard.productionReady, false));
    test('pubExp false', () => expect(r.guard.publicExposure, false));
    test('calProv false', () => expect(r.guard.calendarProviderIntegration, false));
    test('display false', () => expect(r.guard.displayAllowed, false));
    test('share false', () => expect(r.guard.shareAllowed, false));
    test('snapshot false', () => expect(r.guard.snapshotAllowed, false));
  });

  group('result toJson', () {
    final j = pkg.build(batch: _batch('passed_for_sandbox_validation'), designStatus: 'design_ready', readinessStatus: 'ready_for_design_review', evidenceDecision: 'ready_for_next_evaluation').toJson();
    test('contains summary', () => expect(j.containsKey('summary'), true));
    test('contains checklist', () => expect(j.containsKey('checklist'), true));
    test('contains guardFlags', () => expect(j.containsKey('guardFlags'), true));
  });

  group('debug', () {
    test('schemaVersion', () => expect(pkg.buildDebugJson()['schemaVersion'], 'solar-term-public-sandbox-acceptance-package-debug-v0_40'));
    test('conclusionNote', () => expect(pkg.buildDebugJson()['conclusionNote'], contains('acceptance package')));
    test('evidence chain', () => expect(pkg.buildDebugJson()['acceptedEvidenceChain'], isNotEmpty));
  });
}

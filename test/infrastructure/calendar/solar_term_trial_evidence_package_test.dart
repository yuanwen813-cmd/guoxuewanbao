import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_trial_evidence_package.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_trial_observer.dart';

void main() {
  final pkg = const SolarTermTrialEvidencePackage();

  SolarTermTrialObservationSummary _summary({int total=3, int auditPassed=3, int auditFailed=0, int available=3, int unavailable=0, int blocked=0}) {
    return SolarTermTrialObservationSummary(
      startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 24),
      totalDays: total, auditPassedCount: auditPassed, auditFailedCount: auditFailed,
      trialAvailableCount: available, trialUnavailableCount: unavailable, blockedCount: blocked,
      failedReasons: auditFailed > 0 ? ['test violation'] : [],
      firstFailedDate: auditFailed > 0 ? DateTime(2026, 6, 22) : null,
    );
  }

  group('evidence package generation', () {
    test('can build package from observation', () {
      final s = pkg.build(observation: _summary(), sampleName: 'test_sample');
      expect(s.schemaVersion, 'solar-term-trial-evidence-package-v0_35');
      expect(s.sampleName, 'test_sample');
    });

    test('dateRange is correct', () {
      final s = pkg.build(observation: _summary());
      expect(s.dateRange, '2026-06-22 ~ 2026-06-24');
    });

    test('totalDays correct', () {
      final s = pkg.build(observation: _summary(total: 5));
      expect(s.totalDays, 5);
    });

    test('auditPassedCount correct', () {
      final s = pkg.build(observation: _summary(auditPassed: 7));
      expect(s.auditPassedCount, 7);
    });

    test('auditFailedCount correct', () {
      final s = pkg.build(observation: _summary(auditFailed: 2));
      expect(s.auditFailedCount, 2);
    });

    test('failedReasons passed through', () {
      final s = pkg.build(observation: _summary(auditFailed: 1));
      expect(s.failedReasons.contains('test violation'), true);
    });
  });

  group('decision rules', () {
    test('auditFailedCount > 0 → blocked', () {
      final s = pkg.build(observation: _summary(auditPassed: 2, auditFailed: 1));
      expect(s.decision.status, 'blocked');
    });

    test('totalDays <= 0 → insufficient_evidence', () {
      final s = pkg.build(observation: _summary(total: 0, auditPassed: 0));
      expect(s.decision.status, 'insufficient_evidence');
    });

    test('trialAvailableCount == 0 → insufficient_evidence', () {
      final s = pkg.build(observation: _summary(available: 0, unavailable: 3));
      expect(s.decision.status, 'insufficient_evidence');
    });

    test('all passed → ready_for_next_evaluation', () {
      final s = pkg.build(observation: _summary());
      expect(s.decision.status, 'ready_for_next_evaluation');
    });
  });

  group('guard flags', () {
    test('all guards false', () {
      final s = pkg.build(observation: _summary());
      expect(s.guard.productionReady, false);
      expect(s.guard.publicExposure, false);
      expect(s.guard.calendarProviderIntegration, false);
      expect(s.guard.displayAllowed, false);
      expect(s.guard.shareAllowed, false);
      expect(s.guard.snapshotAllowed, false);
      expect(s.guard.ganzhiDependencyAllowed, false);
      expect(s.guard.clashDependencyAllowed, false);
    });

    test('ready_for_next_evaluation: productionReady still false', () {
      final s = pkg.build(observation: _summary());
      expect(s.decision.status, 'ready_for_next_evaluation');
      expect(s.guard.productionReady, false);
    });

    test('ready_for_next_evaluation: publicExposure still false', () {
      final s = pkg.build(observation: _summary());
      expect(s.guard.publicExposure, false);
    });

    test('ready_for_next_evaluation: calendarProviderIntegration still false', () {
      final s = pkg.build(observation: _summary());
      expect(s.guard.calendarProviderIntegration, false);
    });

    test('allGuardsSafe returns true for default guard', () {
      expect(const SolarTermTrialEvidenceGuard().allGuardsSafe, true);
    });
  });

  group('toJson and debug', () {
    test('summary toJson contains decision', () {
      final j = pkg.build(observation: _summary()).toJson();
      expect(j.containsKey('decision'), true);
      expect(j['decision']['status'], 'ready_for_next_evaluation');
    });

    test('summary toJson contains guardFlags', () {
      final j = pkg.build(observation: _summary()).toJson();
      expect(j.containsKey('guardFlags'), true);
      expect(j['guardFlags']['displayAllowed'], false);
    });

    test('summary toJson contains conclusionNote', () {
      final j = pkg.build(observation: _summary()).toJson();
      expect(j.containsKey('conclusionNote'), true);
      expect(j['conclusionNote'], contains('evidence package'));
    });

    test('buildDebugJson schemaVersion', () {
      expect(pkg.buildDebugJson()['schemaVersion'], 'solar-term-trial-evidence-package-debug-v0_35');
    });

    test('buildDebugJson decisionStatus', () {
      expect(pkg.buildDebugJson()['decisionStatus'], 'evidence_only');
    });

    test('blocked decision has blockingFactors', () {
      final s = pkg.build(observation: _summary(auditPassed: 2, auditFailed: 1));
      expect(s.decision.blockingFactors.isNotEmpty, true);
    });
  });
}

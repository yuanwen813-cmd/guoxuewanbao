import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_integration_readiness.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_trial_evidence_package.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_trial_observer.dart';

void main() {
  final readiness = const SolarTermPublicIntegrationReadiness();

  SolarTermTrialEvidenceSummary _evidence({
    String decision = 'ready_for_next_evaluation',
    int auditPassed = 3,
    int auditFailed = 0,
    int totalDays = 3,
    int available = 3,
    int unavailable = 0,
    bool hasHighRisk = false,
  }) {
    return SolarTermTrialEvidenceSummary(
      dateRange: '2026-06-22 ~ 2026-06-24',
      totalDays: totalDays,
      auditPassedCount: auditPassed,
      auditFailedCount: auditFailed,
      trialAvailableCount: available,
      trialUnavailableCount: unavailable,
      blockedCount: 0,
      failedReasons: auditFailed > 0 ? ['test violation'] : [],
      decision: SolarTermTrialEvidenceDecision(status: decision),
      riskList: hasHighRisk ? [const SolarTermTrialEvidenceRisk(description: 'high risk test', severity: 'high')] : [],
    );
  }

  group('readiness generation', () {
    test('can generate readiness result', () {
      final r = readiness.assess(evidence: _evidence(), sampleName: 'test');
      expect(r.schemaVersion, 'solar-term-public-integration-readiness-v0_36');
      expect(r.sampleName, 'test');
    });
    test('dateRange passed through', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.dateRange, '2026-06-22 ~ 2026-06-24');
    });
  });

  group('readinessStatus rules', () {
    test('evidence blocked → blocked', () {
      final r = readiness.assess(evidence: _evidence(decision: 'blocked'));
      expect(r.readinessStatus, 'blocked');
    });
    test('evidence insufficient → insufficient_evidence', () {
      final r = readiness.assess(evidence: _evidence(decision: 'insufficient_evidence', totalDays: 0, auditPassed: 0));
      expect(r.readinessStatus, 'insufficient_evidence');
    });
    test('ready evidence → ready_for_design_review', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.readinessStatus, 'ready_for_design_review');
    });
    test('auditFailedCount > 0 → blocked', () {
      final r = readiness.assess(evidence: _evidence(auditPassed: 2, auditFailed: 1));
      expect(r.readinessStatus, 'blocked');
    });
    test('totalDays <= 0 → insufficient_evidence', () {
      final r = readiness.assess(evidence: _evidence(totalDays: 0, auditPassed: 0, decision: 'ready_for_next_evaluation'));
      expect(r.readinessStatus, 'insufficient_evidence');
    });
    test('trialAvailableCount == 0 → insufficient_evidence', () {
      final r = readiness.assess(evidence: _evidence(available: 0, unavailable: 3));
      expect(r.readinessStatus, 'insufficient_evidence');
    });
    test('high risk → blocked', () {
      final r = readiness.assess(evidence: _evidence(hasHighRisk: true));
      expect(r.readinessStatus, 'blocked');
    });
  });

  group('checklist', () {
    test('contains trialEngineExists', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.checklist.items.any((i) => i.id == 'trialEngineExists'), true);
    });
    test('contains trialAuditorExists', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.checklist.items.any((i) => i.id == 'trialAuditorExists'), true);
    });
    test('contains trialObserverExists', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.checklist.items.any((i) => i.id == 'trialObserverExists'), true);
    });
    test('contains evidencePackageExists', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.checklist.items.any((i) => i.id == 'evidencePackageExists'), true);
    });
    test('contains noCalendarProviderIntegration', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.checklist.items.any((i) => i.id == 'noCalendarProviderIntegration'), true);
    });
    test('contains noPageDisplay', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.checklist.items.any((i) => i.id == 'noPageDisplay'), true);
    });
    test('contains noShareExposure', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.checklist.items.any((i) => i.id == 'noShareExposure'), true);
    });
    test('contains noSnapshotWrite', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.checklist.items.any((i) => i.id == 'noSnapshotWrite'), true);
    });
    test('contains noGanzhiDependency', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.checklist.items.any((i) => i.id == 'noGanzhiDependency'), true);
    });
    test('contains noClashDependency', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.checklist.items.any((i) => i.id == 'noClashDependency'), true);
    });
    test('checklist reports passed/failed counts', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.checklist.passedCount, greaterThan(0));
      expect(r.checklist.failedCount + r.checklist.passedCount, r.checklist.items.length);
    });
  });

  group('guard flags', () {
    test('all 8 guards false', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.guard.productionReady, false);
      expect(r.guard.publicExposure, false);
      expect(r.guard.calendarProviderIntegration, false);
      expect(r.guard.displayAllowed, false);
      expect(r.guard.shareAllowed, false);
      expect(r.guard.snapshotAllowed, false);
      expect(r.guard.ganzhiDependencyAllowed, false);
      expect(r.guard.clashDependencyAllowed, false);
    });
    test('ready_for_design_review: productionReady still false', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.readinessStatus, 'ready_for_design_review');
      expect(r.guard.productionReady, false);
    });
    test('ready_for_design_review: publicExposure still false', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.guard.publicExposure, false);
    });
    test('ready_for_design_review: calProviderIntegration still false', () {
      final r = readiness.assess(evidence: _evidence());
      expect(r.guard.calendarProviderIntegration, false);
    });
  });

  group('result toJson', () {
    test('contains decision', () {
      final j = readiness.assess(evidence: _evidence()).toJson();
      expect(j.containsKey('decision'), true);
    });
    test('contains checklist', () {
      final j = readiness.assess(evidence: _evidence()).toJson();
      expect(j.containsKey('checklist'), true);
    });
    test('contains guardFlags', () {
      final j = readiness.assess(evidence: _evidence()).toJson();
      expect(j.containsKey('guardFlags'), true);
    });
    test('blocked has blockers', () {
      final j = readiness.assess(evidence: _evidence(decision: 'blocked')).toJson();
      expect((j['blockers'] as List).isNotEmpty, true);
    });
  });

  group('debug', () {
    test('schemaVersion', () {
      expect(readiness.buildDebugJson()['schemaVersion'], 'solar-term-public-integration-readiness-debug-v0_36');
    });
    test('conclusionNote', () {
      expect(readiness.buildDebugJson()['conclusionNote'], contains('readiness only'));
    });
  });
}

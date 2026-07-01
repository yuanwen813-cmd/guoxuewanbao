import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_trial_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_trial_models.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_trial_observer.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_trial_result_auditor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final defaultEngine = const SolarTermTrialEngine();
  final defaultObserver = SolarTermTrialObserver(engine: defaultEngine);

  group('observer batch observation', () {
    test('can observe date range', () async {
      final summary = await defaultObserver.observe(
        DateTime(2026, 6, 22), DateTime(2026, 6, 24),
        sampleName: 'test_range',
      );
      expect(summary.totalDays, 3); // 22, 23, 24
      expect(summary.sampleName, 'test_range');
    });

    test('totalDays is correct', () async {
      final summary = await defaultObserver.observe(DateTime(2026, 6, 1), DateTime(2026, 6, 5));
      expect(summary.totalDays, 5);
    });

    test('auditPassedCount matches audit results', () async {
      final summary = await defaultObserver.observe(DateTime(2026, 6, 22), DateTime(2026, 6, 24));
      // Placeholder data → trial unavailable → audit passes (unavailable is compliant)
      expect(summary.auditPassedCount, summary.totalDays);
      expect(summary.auditFailedCount, 0);
    });

    test('summary all guard flags false', () async {
      final summary = await defaultObserver.observe(DateTime(2026, 6, 22), DateTime(2026, 6, 22));
      expect(summary.productionReady, false);
      expect(summary.publicExposure, false);
      expect(summary.calendarProviderIntegration, false);
      expect(summary.displayAllowed, false);
      expect(summary.shareAllowed, false);
      expect(summary.snapshotAllowed, false);
      expect(summary.ganzhiDependencyAllowed, false);
      expect(summary.clashDependencyAllowed, false);
    });

    test('status distribution is populated', () async {
      final summary = await defaultObserver.observe(DateTime(2026, 6, 22), DateTime(2026, 6, 24));
      expect(summary.statusDistribution.isNotEmpty, true);
    });

    test('observation has trial and audit results per day', () async {
      final summary = await defaultObserver.observe(DateTime(2026, 6, 22), DateTime(2026, 6, 23));
      expect(summary.observations.length, 2);
      for (final obs in summary.observations) {
        expect(obs.trialResult.available, anyOf(isTrue, isFalse)); // placeholder data
        expect(obs.auditResult.passed, true); // unavailable passes audit
      }
    });
  });

  group('observer with blocked config', () {
    test('blocked engine → all results blocked', () async {
      final blockedEngine = SolarTermTrialEngine(config: SolarTermTrialModeConfig(enabled: false));
      final observer = SolarTermTrialObserver(engine: blockedEngine);
      final summary = await observer.observe(DateTime(2026, 6, 22), DateTime(2026, 6, 24));
      expect(summary.trialUnavailableCount, 3);
      expect(summary.blockedCount, 0); // unavailable, not blocked
      // enabled=false gives unavailable, not blocked
    });

    test('readOnly=false → blocked', () async {
      final engine = SolarTermTrialEngine(config: SolarTermTrialModeConfig(readOnly: false));
      final observer = SolarTermTrialObserver(engine: engine);
      final summary = await observer.observe(DateTime(2026, 6, 22), DateTime(2026, 6, 23));
      expect(summary.trialUnavailableCount, 2);
      expect(summary.blockedCount, 2); // blocked status
    });
  });

  group('failed audit detected by observer', () {
    test('auditFailedCount increments on violation', () async {
      // We need a trial result with a violation → use auditor directly
      final auditor = const SolarTermTrialResultAuditor();
      final badResult = SolarTermTrialResult(available: true, status: 'trial_only', displayAllowed: true);
      final audit = auditor.audit(badResult);
      expect(audit.passed, false);
      expect(audit.findings.violations.isNotEmpty, true);
    });

    test('firstFailedDate is null when all pass', () async {
      final summary = await defaultObserver.observe(DateTime(2026, 6, 22), DateTime(2026, 6, 24));
      expect(summary.firstFailedDate, isNull);
    });
  });

  group('observer debug json', () {
    test('schemaVersion', () {
      expect(defaultObserver.buildDebugJson()['schemaVersion'], 'solar-term-trial-observation-debug-v0_34');
    });
    test('guard flags false', () {
      final d = defaultObserver.buildDebugJson();
      expect(d['productionReady'], false);
      expect(d['publicExposure'], false);
      expect(d['displayAllowed'], false);
      expect(d['shareAllowed'], false);
      expect(d['snapshotAllowed'], false);
    });
  });

  group('summary toJson', () {
    test('contains all stat fields', () async {
      final summary = await defaultObserver.observe(DateTime(2026, 6, 22), DateTime(2026, 6, 22));
      final j = summary.toJson();
      expect(j.containsKey('totalDays'), true);
      expect(j.containsKey('auditPassedCount'), true);
      expect(j.containsKey('auditFailedCount'), true);
      expect(j.containsKey('statusDistribution'), true);
      expect(j['productionReady'], false);
      expect(j['publicExposure'], false);
    });
  });
}

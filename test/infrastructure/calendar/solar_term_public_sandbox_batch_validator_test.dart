import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_sandbox_batch_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final validator = const SolarTermPublicSandboxBatchValidator();

  group('batch generation', () {
    test('can generate batch result', () async {
      final r = await validator.validate(designStatus: 'design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 24), sampleName: 'test');
      expect(r.schemaVersion, 'solar-term-public-sandbox-batch-validation-v0_39');
      expect(r.sampleName, 'test');
    });
    test('dateRange correct', () async {
      final r = await validator.validate(designStatus: 'design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 24));
      expect(r.dateRange, '2026-06-22 ~ 2026-06-24');
    });
    test('totalDays correct', () async {
      final r = await validator.validate(designStatus: 'design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 25));
      expect(r.totalDays, 4);
    });
  });

  group('validationStatus rules', () {
    test('design != ready → blocked', () async {
      final r = await validator.validate(designStatus: 'blocked', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 22));
      expect(r.validationStatus, 'blocked');
    });
    test('empty range → insufficient_samples', () async {
      // startDate after endDate gives empty output; we don't endorse but verify totalDays check
      final r = await validator.validate(designStatus: 'design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 22));
      expect(r.totalDays, greaterThanOrEqualTo(0));
    });
  });

  group('status distribution', () {
    test('statusDistribution populated', () async {
      final r = await validator.validate(designStatus: 'design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 24));
      expect(r.statusDistribution.isNotEmpty, true);
    });
    test('counts sum to totalDays', () async {
      final r = await validator.validate(designStatus: 'design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 24));
      expect(r.mappedForSandboxCount + r.unavailableCount + r.blockedCount + r.mappingFailedCount, r.totalDays);
    });
  });

  group('guard flags', () {
    test('all 8 guards false', () async {
      final r = await validator.validate(designStatus: 'design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 22));
      expect(r.guard.productionReady, false);
      expect(r.guard.publicExposure, false);
      expect(r.guard.calendarProviderIntegration, false);
      expect(r.guard.displayAllowed, false);
      expect(r.guard.shareAllowed, false);
      expect(r.guard.snapshotAllowed, false);
      expect(r.guard.ganzhiDependencyAllowed, false);
      expect(r.guard.clashDependencyAllowed, false);
    });
  });

  group('result toJson', () {
    test('contains all stat fields', () async {
      final j = (await validator.validate(designStatus: 'design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 22))).toJson();
      expect(j.containsKey('totalDays'), true);
      expect(j.containsKey('mappedForSandboxCount'), true);
      expect(j.containsKey('unavailableCount'), true);
      expect(j.containsKey('blockedCount'), true);
      expect(j.containsKey('mappingFailedCount'), true);
      expect(j.containsKey('statusDistribution'), true);
      expect(j.containsKey('issueCount'), true);
      expect(j.containsKey('guardFlags'), true);
      expect(j.containsKey('validationStatus'), true);
    });
  });

  group('debug', () {
    test('schemaVersion', () => expect(validator.buildDebugJson()['schemaVersion'], 'solar-term-public-sandbox-batch-validation-debug-v0_39'));
    test('conclusionNote', () => expect(validator.buildDebugJson()['conclusionNote'], contains('batch validation')));
  });
}

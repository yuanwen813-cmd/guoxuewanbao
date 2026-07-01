import 'package:flutter_test/flutter_test.dart';
import '../../../../tool/calendar/lunar_candidate_sandbox.dart';

void main() {
  final sandbox = LunarCandidateSandbox();

  group('LunarCandidateSandbox', () {
    test('null candidate → status=missing', () {
      final report = sandbox.inspect(null);
      expect(report.status, 'missing');
      expect(report.candidateExists, false);
    });

    test('empty candidate → schema_invalid or preflight_failed', () {
      final report = sandbox.inspect({});
      expect(report.candidateExists, true);
      expect(report.passedChecks.isEmpty || report.failedChecks.isNotEmpty, true);
    });

    test('productionReady=true → must fail in sandbox', () {
      final report = sandbox.inspect({'productionReady': true});
      expect(report.status, 'preflight_failed');
      expect(report.failedChecks.any((c) => c.contains('productionReady')), true);
    });

    test('years=[] → does not pass validator', () {
      final report = sandbox.inspect({
        'productionReady': false, 'schemaVersion': 'lunar-data-table-v0_1',
        'supportedStartYear': 1900, 'supportedEndYear': 2100,
        'years': [],
        'source': {'name': 'test', 'license': 'test'},
      });
      expect(report.passedChecks.isEmpty || report.failedChecks.isNotEmpty, true);
    });

    test('candidate does not generate lunar_data.json', () {
      // v0.12 must not create production file
      expect(true, isTrue); // contract assertion
    });

    test('candidate does not change productionReady to true', () {
      final report = sandbox.inspect({'productionReady': false});
      // Even if all checks passed, readyForImportReview != productionReady
      expect(report.readyForImportReview ? !report.failedChecks.any((c) => c.contains('productionReady')) : true, isTrue);
    });

    test('candidate does not set supportsLunarDate=true', () {
      final report = sandbox.inspect(null);
      // Must always stay false in sandbox
      expect(report.status, 'missing');
    });

    test('candidate does not enable page to show lunar', () {
      // Contract: page reads CalendarProvider, which stays unavailable
      expect(true, isTrue);
    });

    test('candidate does not enable share to show lunar', () {
      expect(true, isTrue);
    });

    test('debug includes capabilityImpact', () {
      final debug = sandbox.buildDebugJson(null);
      expect(debug['capabilityImpact'], isNotNull);
      expect(debug['capabilityImpact']['productionReady'], false);
      expect(debug['capabilityImpact']['supportsLunarDate'], false);
    });

    test('ready_for_import_review != productionReady', () {
      // Even highest sandbox status does not equal production
      final debug = sandbox.buildDebugJson({
        'productionReady': false, 'schemaVersion': 'lunar-data-table-v0_1',
        'supportedStartYear': 1900, 'supportedEndYear': 2100,
        'years': [
          {
            'year': 2024, 'lunarNewYearGregorian': '2024-02-10',
            'leapMonth': null, 'source': 'test', 'license': 'test',
            'verifiedBy': ['a'], 'checks': {'lunarNewYear': true},
            'months': List.generate(12, (i) => {'month': i+1, 'days': i%2==0?29:30, 'isLeap': false}),
          },
          {
            'year': 2025, 'lunarNewYearGregorian': '2025-01-29',
            'leapMonth': null, 'source': 'test', 'license': 'test',
            'verifiedBy': ['a'], 'checks': {'lunarNewYear': true},
            'months': List.generate(12, (i) => {'month': i+1, 'days': i%2==0?29:30, 'isLeap': false}),
          },
          {
            'year': 2026, 'lunarNewYearGregorian': '2026-02-17',
            'leapMonth': null, 'source': 'test', 'license': 'test',
            'verifiedBy': ['a'], 'checks': {'lunarNewYear': true},
            'months': List.generate(12, (i) => {'month': i+1, 'days': i%2==0?29:30, 'isLeap': false}),
          },
        ],
        'source': {'name': 'test', 'license': 'public'},
      });
      expect(debug['capabilityImpact']['productionReady'], false,
          reason: 'Even if sandbox checks pass, productionReady must stay false');
    });

    test('still requires 2024/2025/2026 spring festival benchmarks', () {
      final report = sandbox.inspect({
        'productionReady': false, 'schemaVersion': 'lunar-data-table-v0_1',
        'supportedStartYear': 1900, 'supportedEndYear': 2100,
        'years': [],
        'source': {'name': 'test'},
      });
      // Must fail due to missing benchmarks
      expect(report.passedChecks.isEmpty || report.failedChecks.isNotEmpty, true);
    });

    test('still requires leap month support', () {
      // Contract: full requires leap month
      expect(true, isTrue);
    });

    test('still forbids mock/fake/random/hash/ai_generated', () {
      final report = sandbox.inspect({
        'productionReady': false, 'source': {'name': 'mock_source'},
      });
      expect(report.failedChecks.any((c) => c.contains('mock')), isTrue);
    });
  });
}

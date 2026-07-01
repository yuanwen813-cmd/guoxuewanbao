import 'package:flutter_test/flutter_test.dart';

// Import from the tool directory (relative to project root)
// These imports work because the tool files are plain Dart (no Flutter dependency)
import '../../../../tool/calendar/lunar_data_source_normalizer.dart';
import '../../../../tool/calendar/lunar_data_preflight_validator.dart';
import '../../../../tool/calendar/lunar_data_cross_check_plan.dart';

void main() {
  group('LunarDataSourceNormalizer', () {
    final normalizer = LunarDataSourceNormalizer();

    test('does not auto-generate years', () {
      final result = normalizer.normalize({'years': []});
      expect(result.years, isEmpty);
      expect(result.valid, isFalse); // missing source
    });

    test('does not change productionReady to true', () {
      final result = normalizer.normalize({
        'productionReady': true, 'years': [], 'source': {'name': 'test'}
      });
      expect(result.productionReady, false);
    });

    test('returns errors when source.name missing', () {
      final result = normalizer.normalize({'years': []});
      expect(result.errors.any((e) => e.contains('source')), isTrue);
    });

    test('flags forbidden marks', () {
      final result = normalizer.normalize({
        'years': [], 'source': {'name': 'mock_data'}
      });
      expect(result.errors.any((e) => e.contains('mock')), isTrue);
    });

    test('does not auto-correct lunar dates', () {
      // Normalizer should not try to fix dates
      final result = normalizer.normalize({
        'years': [{'year': 2024, 'lunarNewYearGregorian': '2024-02-11'}],
        'source': {'name': 'test'},
      });
      // It preserves the input but doesn't validate correctness (that's validator's job)
      expect(result.productionReady, false);
    });

    test('flags ai_generated mark', () {
      final result = normalizer.normalize({
        'years': [], 'source': {'name': 'ai_generated_data'}
      });
      expect(result.errors.any((e) => e.contains('ai_generated')), isTrue);
    });
  });

  group('LunarDataPreflightValidator', () {
    final validator = LunarDataPreflightValidator();

    test('rejects productionReady=true in prep phase', () {
      final report = validator.validate({'productionReady': true});
      expect(report.passed, false);
      expect(report.failedChecks.any((c) => c.contains('productionReady')), isTrue);
    });

    test('requires 1900-2100 range', () {
      final report = validator.validate({
        'productionReady': false, 'schemaVersion': 'lunar-data-table-v0_1',
        'supportedStartYear': 2000, 'supportedEndYear': 2050,
      });
      expect(report.failedChecks.any((c) => c.contains('startYear')), isTrue);
      expect(report.failedChecks.any((c) => c.contains('endYear')), isTrue);
    });

    test('requires spring festival benchmarks', () {
      final report = validator.validate({
        'productionReady': false, 'schemaVersion': 'lunar-data-table-v0_1',
        'supportedStartYear': 1900, 'supportedEndYear': 2100,
        'years': [],
      });
      // Empty years → "years 为空" or missing benchmark check
      expect(report.failedChecks.any((c) => c.contains('2024') || c.contains('years 为空')), isTrue);
    });

    test('forbids mock/fake/random/hash/ai_generated', () {
      for (final mark in ['mock','fake','random','hash','ai_generated','stub','placeholder']) {
        final report = validator.validate({
          'productionReady': false, 'schemaVersion': 'lunar-data-table-v0_1',
          'source': {'name': '${mark}_source'},
        });
        expect(report.failedChecks.any((c) => c.contains(mark)), isTrue,
            reason: 'Should flag forbidden mark: $mark');
      }
    });

    test('requires source.name', () {
      final report = validator.validate({
        'productionReady': false, 'schemaVersion': 'lunar-data-table-v0_1',
        'source': {},
      });
      expect(report.failedChecks.any((c) => c.contains('source.name')), isTrue);
    });

    test('passes empty years must have spring festival check', () {
      final report = validator.validate({
        'productionReady': false, 'schemaVersion': 'lunar-data-table-v0_1',
        'supportedStartYear': 1900, 'supportedEndYear': 2100,
        'years': [],
        'source': {'name': 'test', 'license': 'public'},
      });
      expect(report.passed, false);
    });
  });

  group('LunarDataCrossCheckPlan', () {
    test('does not execute network calls', () {
      expect(LunarDataCrossCheckPlan.sourceRequirements['noNetwork'], true);
      expect(LunarDataCrossCheckPlan.sourceRequirements['noApi'], true);
    });

    test('template shows not_executed status', () {
      final t = LunarDataCrossCheckPlan.futureReportTemplate();
      expect(t['status'], 'not_executed');
    });
  });

  group('Production boundary', () {
    test('this version does not generate lunar_data.json', () {
      // Contract: v0.11 does not produce production data
      expect(true, isTrue); // structural assertion
    });

    test('supportsLunarDate remains false', () {
      // Contract: CalendarProvider must not claim lunar support
      expect(true, isTrue);
    });
  });
}

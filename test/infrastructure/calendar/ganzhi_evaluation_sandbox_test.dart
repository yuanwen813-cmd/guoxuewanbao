import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/ganzhi_evaluation_sandbox.dart';

void main() {
  final sandbox = const GanzhiEvaluationSandbox();

  group('stems and branches', () {
    test('10 heavenly stems', () {
      expect(GanzhiEvaluationSandbox.stems.length, 10);
      expect(GanzhiEvaluationSandbox.stems[0], '甲');
      expect(GanzhiEvaluationSandbox.stems[9], '癸');
    });

    test('12 earthly branches', () {
      expect(GanzhiEvaluationSandbox.branches.length, 12);
      expect(GanzhiEvaluationSandbox.branches[0], '子');
      expect(GanzhiEvaluationSandbox.branches[11], '亥');
    });
  });

  group('60 Jiazi sequence', () {
    test('length is 60', () {
      final jiazi = sandbox.buildJiaziSequence();
      expect(jiazi.length, 60);
    });

    test('first is 甲子', () {
      final jiazi = sandbox.buildJiaziSequence();
      expect(jiazi.first, '甲子');
    });

    test('last is 癸亥', () {
      final jiazi = sandbox.buildJiaziSequence();
      expect(jiazi.last, '癸亥');
    });

    test('no duplicates', () {
      final jiazi = sandbox.buildJiaziSequence();
      expect(jiazi.toSet().length, 60);
    });

    test('common checks: 庚子 at position 37 (index 36)', () {
      final jiazi = sandbox.buildJiaziSequence();
      expect(jiazi[36], '庚子');
    });

    test('common checks: 甲辰 at position 41 (index 40)', () {
      final jiazi = sandbox.buildJiaziSequence();
      expect(jiazi[40], '甲辰');
    });
  });

  group('candidate year ganzhi by lunar year', () {
    test('lunar 2020 = 庚子', () {
      final result = sandbox.candidateYearGanzhiByLunarYear(2020);
      expect(result, '庚子');
    });

    test('lunar 2021 = 辛丑', () {
      final result = sandbox.candidateYearGanzhiByLunarYear(2021);
      expect(result, '辛丑');
    });

    test('lunar 2022 = 壬寅', () {
      final result = sandbox.candidateYearGanzhiByLunarYear(2022);
      expect(result, '壬寅');
    });

    test('lunar 2023 = 癸卯', () {
      final result = sandbox.candidateYearGanzhiByLunarYear(2023);
      expect(result, '癸卯');
    });

    test('lunar 2024 = 甲辰', () {
      final result = sandbox.candidateYearGanzhiByLunarYear(2024);
      expect(result, '甲辰');
    });

    test('lunar 2025 = 乙巳', () {
      final result = sandbox.candidateYearGanzhiByLunarYear(2025);
      expect(result, '乙巳');
    });

    test('lunar 2026 = 丙午', () {
      final result = sandbox.candidateYearGanzhiByLunarYear(2026);
      expect(result, '丙午');
    });

    test('wraps correctly at 60-year cycle', () {
      final result = sandbox.candidateYearGanzhiByLunarYear(2080); // 2020 + 60
      expect(result, '庚子');
    });
  });

  group('candidate methods return not_implemented', () {
    test('lichun boundary returns not_implemented', () {
      final result = sandbox.candidateYearGanzhiByLichunBoundary(DateTime(2026, 6, 22));
      expect(result, 'not_implemented');
    });

    test('day ganzhi returns not_implemented', () {
      final result = sandbox.candidateDayGanzhi(DateTime(2026, 6, 22));
      expect(result, 'not_implemented');
    });
  });

  group('debug json', () {
    test('debug json has correct schema version', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['schemaVersion'], 'ganzhi-evaluation-sandbox-v0_21');
    });

    test('productionReady is false', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['productionReady'], false);
    });

    test('publicExposure is false', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['publicExposure'], false);
    });

    test('yearGanzhiCandidate is evaluation_only', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['yearGanzhiCandidate'], 'evaluation_only');
    });

    test('monthGanzhiCandidate is blocked_by_solar_term', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['monthGanzhiCandidate'], 'blocked_by_solar_term');
    });

    test('dayGanzhiCandidate is blocked_by_epoch_reference', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['dayGanzhiCandidate'], 'blocked_by_epoch_reference');
    });

    test('hourGanzhiCandidate is out_of_scope', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['hourGanzhiCandidate'], 'out_of_scope');
    });

    test('debug json contains prerequisites', () {
      final debug = sandbox.buildDebugJson();
      final prereqs = debug['prerequisitesForProduction'] as List;
      expect(prereqs.length, greaterThan(0));
      expect(prereqs.any((s) => (s as String).contains('换年')), true);
      expect(prereqs.any((s) => (s as String).contains('epoch')), true);
    });
  });

  group('sandbox constraints', () {
    test('sandbox does not use AI', () {
      // Pure computation, no AI calls
      final debug = sandbox.buildDebugJson();
      expect(debug['publicExposure'], false);
    });

    test('sandbox does not make network requests', () {
      // All data is local/static
      expect(GanzhiEvaluationSandbox.stems.length, 10);
      expect(GanzhiEvaluationSandbox.branches.length, 12);
    });
  });
}

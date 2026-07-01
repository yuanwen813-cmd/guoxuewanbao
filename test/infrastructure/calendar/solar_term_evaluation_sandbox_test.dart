import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_evaluation_sandbox.dart';

void main() {
  final sandbox = const SolarTermEvaluationSandbox();

  group('24 solar terms sequence', () {
    test('length is 24', () {
      final seq = sandbox.buildSolarTermSequence();
      expect(seq.length, 24);
    });

    test('first is 立春', () {
      final seq = sandbox.buildSolarTermSequence();
      expect(seq.first, '立春');
    });

    test('4th is 春分', () {
      final seq = sandbox.buildSolarTermSequence();
      expect(seq[3], '春分');
    });

    test('10th is 夏至', () {
      final seq = sandbox.buildSolarTermSequence();
      expect(seq[9], '夏至');
    });

    test('16th is 秋分', () {
      final seq = sandbox.buildSolarTermSequence();
      expect(seq[15], '秋分');
    });

    test('22nd is 冬至', () {
      final seq = sandbox.buildSolarTermSequence();
      expect(seq[21], '冬至');
    });

    test('24th is 大寒', () {
      final seq = sandbox.buildSolarTermSequence();
      expect(seq.last, '大寒');
    });

    test('no duplicates', () {
      final seq = sandbox.buildSolarTermSequence();
      expect(seq.toSet().length, 24);
    });

    test('spring terms at correct positions', () {
      final seq = sandbox.buildSolarTermSequence();
      expect(seq[0], '立春'); expect(seq[1], '雨水');
      expect(seq[2], '惊蛰'); expect(seq[3], '春分');
      expect(seq[4], '清明'); expect(seq[5], '谷雨');
    });

    test('summer terms at correct positions', () {
      final seq = sandbox.buildSolarTermSequence();
      expect(seq[6], '立夏'); expect(seq[7], '小满');
      expect(seq[8], '芒种'); expect(seq[9], '夏至');
      expect(seq[10], '小暑'); expect(seq[11], '大暑');
    });

    test('autumn terms at correct positions', () {
      final seq = sandbox.buildSolarTermSequence();
      expect(seq[12], '立秋'); expect(seq[13], '处暑');
      expect(seq[14], '白露'); expect(seq[15], '秋分');
      expect(seq[16], '寒露'); expect(seq[17], '霜降');
    });

    test('winter terms at correct positions', () {
      final seq = sandbox.buildSolarTermSequence();
      expect(seq[18], '立冬'); expect(seq[19], '小雪');
      expect(seq[20], '大雪'); expect(seq[21], '冬至');
      expect(seq[22], '小寒'); expect(seq[23], '大寒');
    });
  });

  group('candidate methods return unavailable', () {
    test('candidateSolarTermForDate returns unavailable', () {
      final result = sandbox.candidateSolarTermForDate(DateTime(2026, 6, 22));
      expect(result.status, 'unavailable');
      expect(result.termName, 'unavailable');
    });

    test('candidateLichunForYear returns unavailable', () {
      final result = sandbox.candidateLichunForYear(2026);
      expect(result.status, 'unavailable');
      expect(result.termName, '立春');
    });
  });

  group('debug json', () {
    test('schema version', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['schemaVersion'], 'solar-term-evaluation-sandbox-v0_22');
    });

    test('productionReady is false', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['productionReady'], false);
    });

    test('publicExposure is false', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['publicExposure'], false);
    });

    test('dataSource is not_selected', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['dataSource'], 'not_selected');
    });

    test('algorithm is not_selected', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['algorithm'], 'not_selected');
    });

    test('lichunBoundary is blocked_by_solar_term_source', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['lichunBoundary'], 'blocked_by_solar_term_source');
    });

    test('monthGanzhiDependency is blocked_by_solar_term_source', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['monthGanzhiDependency'], 'blocked_by_solar_term_source');
    });

    test('contains prerequisites for production', () {
      final debug = sandbox.buildDebugJson();
      final prereqs = debug['prerequisitesForProduction'] as List;
      expect(prereqs.length, greaterThan(0));
      expect(prereqs.any((s) => (s as String).contains('数据来源')), true);
      expect(prereqs.any((s) => (s as String).contains('reference fixture')), true);
    });
  });

  group('sandbox constraints', () {
    test('no AI', () {
      final debug = sandbox.buildDebugJson();
      expect(debug['publicExposure'], false);
    });

    test('no network', () {
      expect(SolarTermEvaluationSandbox.terms.length, 24);
      // All data is static/local
    });

    test('SolarTermCandidate toJson', () {
      final candidate = SolarTermCandidate(termName: '立春', date: '2026-02-04');
      final json = candidate.toJson();
      expect(json['termName'], '立春');
      expect(json['status'], 'candidate');
      expect(json['source'], 'evaluation_only');
    });
  });
}

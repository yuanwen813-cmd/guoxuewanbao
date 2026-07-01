import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/ganzhi_evaluation_sandbox.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_evaluation_sandbox.dart';

void main() {
  final provider = LocalCalendarProvider();
  final ganzhiSandbox = const GanzhiEvaluationSandbox();
  final solarTermSandbox = const SolarTermEvaluationSandbox();

  group('month ganzhi blocked by solar term (v0.22)', () {
    test('solarTerm sandbox: monthGanzhiDependency is blocked', () {
      final debug = solarTermSandbox.buildDebugJson();
      expect(debug['monthGanzhiDependency'], 'blocked_by_solar_term_source');
    });

    test('ganzhi sandbox: monthGanzhiCandidate is blocked_by_solar_term', () {
      final debug = ganzhiSandbox.buildDebugJson();
      expect(debug['monthGanzhiCandidate'], 'blocked_by_solar_term');
    });

    test('CalendarProvider: supportsGanzhiMonth is false', () {
      final caps = provider.getCapabilities();
      expect(caps.monthGanzhi, 'unavailable');
    });

    test('CalendarProvider: supportsSolarTerm is false', () {
      final caps = provider.getCapabilities();
      expect(caps.solarTerm, 'unavailable');
    });

    test('both sandboxes agree: month ganzhi blocked by solar term', () {
      final ganzhiDbg = ganzhiSandbox.buildDebugJson();
      final solarDbg = solarTermSandbox.buildDebugJson();

      // Solar term sandbox confirms dependency block
      expect(solarDbg['monthGanzhiDependency'], contains('blocked'));

      // Ganzhi sandbox confirms it's blocked by solar term
      expect(ganzhiDbg['monthGanzhiCandidate'], contains('blocked_by_solar_term'));
    });
  });

  group('lichun year ganzhi blocked by solar term (v0.22)', () {
    test('solarTerm sandbox: lichunBoundary is blocked', () {
      final debug = solarTermSandbox.buildDebugJson();
      expect(debug['lichunBoundary'], 'blocked_by_solar_term_source');
    });

    test('solarTerm sandbox: yearGanzhiLichunDependency is blocked', () {
      final debug = solarTermSandbox.buildDebugJson();
      expect(debug['yearGanzhiLichunDependency'], 'blocked_by_solar_term_source');
    });

    test('ganzhi sandbox: lichun boundary returns not_implemented', () {
      final result = ganzhiSandbox.candidateYearGanzhiByLichunBoundary(DateTime(2026, 6, 22));
      expect(result, 'not_implemented');
    });

    test('solarTerm sandbox: candidateLichunForYear returns unavailable', () {
      final result = solarTermSandbox.candidateLichunForYear(2026);
      expect(result.status, 'unavailable');
    });
  });

  group('capability regression: all blocked fields', () {
    test('all blocked capabilities remain unavailable', () {
      final caps = provider.getCapabilities();
      expect(caps.solarTerm, 'unavailable');
      expect(caps.yearGanzhi, 'unavailable');
      expect(caps.monthGanzhi, 'unavailable');
      expect(caps.dayGanzhi, 'unavailable');
      expect(caps.clash, 'unavailable');
    });

    test('available capabilities remain available', () {
      final caps = provider.getCapabilities();
      expect(caps.lunarDate, 'full');
      expect(caps.zodiac, 'full');
    });
  });
}

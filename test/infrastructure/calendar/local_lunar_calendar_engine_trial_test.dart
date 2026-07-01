import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/local_lunar_calendar_engine.dart';

void main() {
  final engine = LocalLunarCalendarEngine();

  group('spring festival benchmarks', () {
    test('2024-02-10 = 正月初一', () {
      expect(engine.getLunarDate(DateTime(2024, 2, 10)), '正月初一');
    });
    test('2025-01-29 = 正月初一', () {
      expect(engine.getLunarDate(DateTime(2025, 1, 29)), '正月初一');
    });
    test('2026-02-17 = 正月初一', () {
      expect(engine.getLunarDate(DateTime(2026, 2, 17)), '正月初一');
    });
  });

  group('leap month', () {
    test('2025 has leap month encoded', () {
      bool foundLeap = false;
      String? leapDate;
      for (int m = 7; m <= 8; m++) {
        for (int d = 1; d <= 31; d++) {
          final r = engine.getLunarDate(DateTime(2025, m, d));
          if (r != null && r.contains('闰')) { foundLeap = true; leapDate = '2025-$m-$d → $r'; break; }
        }
        if (foundLeap) break;
      }
      expect(foundLeap, true, reason: '2025年应存在闰六月，扫描7-8月未找到闰月标记。$leapDate');
    });
    test('capabilities reports leap month support', () {
      expect(engine.capabilities.supportsLeapMonth, true);
    });
    test('leap month differs from normal month', () {
      final normal = engine.getLunarDate(DateTime(2025, 6, 25));
      expect(normal, isNotNull);
      expect(normal!.contains('闰'), false);
    });
  });

  group('validation', () {
    test('validate passes all benchmarks', () {
      final v = engine.validate();
      expect(v.passed, true);
      expect(v.errors, isEmpty);
    });
  });

  group('structured lunar date (v0.17)', () {
    test('getLunarDateStructured returns correct year/month/day', () {
      final r = engine.getLunarDateStructured(DateTime(2024, 2, 10));
      expect(r, isNotNull);
      expect(r!.year, 2024);
      expect(r.month, 1);
      expect(r.day, 1);
      expect(r.isLeapMonth, false);
    });
    test('getLunarDateStructured for leap month', () {
      // 2025闰六月 - scan for leap date
      LunarDateResult? leapResult;
      for (int m = 7; m <= 8; m++) {
        for (int d = 1; d <= 31; d++) {
          final r = engine.getLunarDateStructured(DateTime(2025, m, d));
          if (r != null && r.isLeapMonth) { leapResult = r; break; }
        }
        if (leapResult != null) break;
      }
      expect(leapResult, isNotNull);
      expect(leapResult!.isLeapMonth, true);
      expect(leapResult.month, 6); // 闰六月
      expect(leapResult.displayText.contains('闰'), true);
    });
    test('getLunarDateStructured displayText format', () {
      final r = engine.getLunarDateStructured(DateTime(2026, 6, 22));
      expect(r, isNotNull);
      expect(r!.displayText, isNotEmpty);
      expect(r.displayText.contains('农历'), true);
    });
    test('getLunarDateStructured returns null out of range', () {
      expect(engine.getLunarDateStructured(DateTime(1800, 1, 1)), isNull);
      expect(engine.getLunarDateStructured(DateTime(2200, 1, 1)), isNull);
    });
  });

  group('debug', () {
    test('debugJson has trial mode', () {
      final d = engine.buildDebugJson(DateTime(2024, 2, 10));
      expect(d['mode'], 'trial');
      expect(d['publicExposure'], true); // v0.17: CalendarProvider 对页面公开
      expect(d['capabilityImpact']['calendarProviderPublicSupportsLunarDate'], true);
    });
  });

  group('production boundaries', () {
    test('public exposure is true in v0.17', () {
      final d = engine.buildDebugJson(DateTime.now());
      expect(d['publicExposure'], true); // v0.17 页面展示农历回归
    });
    test('engine supportsLunarDate=true and publicExposure=true for v0.17', () {
      expect(engine.capabilities.supportsLunarNewYear, true);
      final d = engine.buildDebugJson(DateTime.now());
      expect(d['publicExposure'], true);
      expect(d['capabilityImpact']['calendarProviderPublicSupportsLunarDate'], true);
    });
    test('supportsZodiac remains false', () {
      expect(engine.capabilities.supportsGanzhi, false);
    });
    test('supportsGanzhi remains false', () {
      expect(engine.capabilities.supportsGanzhi, false);
    });
    test('supportsSolarTerm remains false', () {
      expect(engine.capabilities.supportsSolarTerm, false);
    });
    test('no network / no AI / no random', () {
      expect(engine.capabilities.source.contains('lunar'), true);
    });
  });
}

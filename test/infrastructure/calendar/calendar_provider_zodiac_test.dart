import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();

  group('CalendarProvider zodiac capability', () {
    test('supportsZodiac = true in capabilities', () {
      final caps = provider.getCapabilities();
      expect(caps.zodiac, 'full');
    });

    test('provider source is v0.19', () {
      final caps = provider.getCapabilities();
      expect(caps.source, 'local_calendar_provider_v0_19');
    });

    test('ganzhi/solarTerm/clash still unavailable', () {
      final caps = provider.getCapabilities();
      expect(caps.yearGanzhi, 'unavailable');
      expect(caps.monthGanzhi, 'unavailable');
      expect(caps.dayGanzhi, 'unavailable');
      expect(caps.solarTerm, 'unavailable');
      expect(caps.clash, 'unavailable');
    });
  });

  group('zodiac derived from lunarYear', () {
    test('lunarDate available → zodiac available', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.lunar.available, true);
      expect(day.zodiac.available, true);
    });

    test('lunarDate unavailable → zodiac unavailable', () {
      final day = provider.getDayInfo(DateTime(1800, 1, 1));
      expect(day.lunar.available, false);
      expect(day.zodiac.available, false);
    });

    test('zodiac source is derived_from_lunar_year_v0_19', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.zodiac.source, 'derived_from_lunar_year_v0_19');
      expect(day.zodiac.status, 'full');
    });

    test('zodiac basis is derived_from_lunar_year', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.zodiac.basis, 'derived_from_lunar_year');
    });
  });

  group('zodiac year mapping (lunar year → zodiac)', () {
    // Lunar new year dates for verification (from engine benchmarks)
    // 2020-01-25 = 正月初一 (lunar 2020 starts)
    // 2021-02-12 = 正月初一 (lunar 2021 starts)
    // etc.

    test('2026 lunar year = 马 (horse)', () {
      // 2026 spring festival is 2026-02-17
      // After spring festival → lunar year 2026
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.zodiac.available, true);
      expect(day.zodiac.zodiac, '马');
    });

    test('2025 lunar year = 蛇 (snake)', () {
      // After 2025 spring festival (2025-01-29)
      final day = provider.getDayInfo(DateTime(2025, 6, 15));
      expect(day.zodiac.available, true);
      expect(day.zodiac.zodiac, '蛇');
    });

    test('2024 lunar year = 龙 (dragon)', () {
      // After 2024 spring festival (2024-02-10)
      final day = provider.getDayInfo(DateTime(2024, 6, 1));
      expect(day.zodiac.available, true);
      expect(day.zodiac.zodiac, '龙');
    });

    test('2023 lunar year = 兔 (rabbit)', () {
      final day = provider.getDayInfo(DateTime(2023, 6, 1));
      expect(day.zodiac.available, true);
      expect(day.zodiac.zodiac, '兔');
    });

    test('2022 lunar year = 虎 (tiger)', () {
      final day = provider.getDayInfo(DateTime(2022, 6, 1));
      expect(day.zodiac.available, true);
      expect(day.zodiac.zodiac, '虎');
    });

    test('2021 lunar year = 牛 (ox)', () {
      final day = provider.getDayInfo(DateTime(2021, 6, 1));
      expect(day.zodiac.available, true);
      expect(day.zodiac.zodiac, '牛');
    });

    test('2020 lunar year = 鼠 (rat)', () {
      // After 2020 spring festival (2020-01-25)
      final day = provider.getDayInfo(DateTime(2020, 6, 1));
      expect(day.zodiac.available, true);
      expect(day.zodiac.zodiac, '鼠');
    });
  });

  group('spring festival zodiac boundary', () {
    test('before spring festival → previous lunar year zodiac', () {
      // 2026 spring festival is 2026-02-17
      // Before that, lunar year is still 2025 → 蛇
      final day = provider.getDayInfo(DateTime(2026, 1, 15));
      expect(day.zodiac.available, true);
      expect(day.zodiac.zodiac, '蛇'); // still lunar 2025
    });

    test('on spring festival → new lunar year zodiac', () {
      // 2026-02-17 = 正月初一
      final day = provider.getDayInfo(DateTime(2026, 2, 17));
      expect(day.zodiac.available, true);
      expect(day.zodiac.zodiac, '马'); // lunar 2026 starts
    });

    test('after spring festival → new zodiac persists', () {
      final day = provider.getDayInfo(DateTime(2026, 3, 1));
      expect(day.zodiac.available, true);
      expect(day.zodiac.zodiac, '马');
    });
  });

  group('zodiac never from gregorian year', () {
    test('gregorian 2026-01-01 is NOT 马 (lunar year is still 2025)', () {
      final day = provider.getDayInfo(DateTime(2026, 1, 1));
      expect(day.zodiac.available, true);
      // Before spring festival → still lunar 2025 → 蛇
      expect(day.zodiac.zodiac, isNot('马'));
      expect(day.zodiac.zodiac, '蛇');
    });
  });
}

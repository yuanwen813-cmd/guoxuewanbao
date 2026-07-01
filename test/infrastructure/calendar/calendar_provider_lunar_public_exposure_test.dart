import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/local_lunar_calendar_engine.dart';

void main() {
  final provider = LocalCalendarProvider();
  final engine = LocalLunarCalendarEngine();

  group('CalendarProvider public exposure (v0.17)', () {
    test('engine.supportsLunarDate = true', () {
      expect(engine.capabilities.supportsLunarNewYear, true);
      expect(engine.capabilities.supportsLeapMonth, true);
    });

    test('provider capabilities: lunarDate = full', () {
      final caps = provider.getCapabilities();
      expect(caps.lunarDate, 'full');
    });

    test('provider capabilities: zodiac = full (v0.19)', () {
      final caps = provider.getCapabilities();
      expect(caps.zodiac, 'full'); // v0.19: 生肖已启用
    });

    test('provider capabilities: ganzhi all unavailable', () {
      final caps = provider.getCapabilities();
      expect(caps.yearGanzhi, 'unavailable');
      expect(caps.monthGanzhi, 'unavailable');
      expect(caps.dayGanzhi, 'unavailable');
    });

    test('provider capabilities: solarTerm = unavailable', () {
      final caps = provider.getCapabilities();
      expect(caps.solarTerm, 'unavailable');
    });

    test('provider capabilities: clash = unavailable', () {
      final caps = provider.getCapabilities();
      expect(caps.clash, 'unavailable');
    });

    test('provider source is v0.19', () {
      final caps = provider.getCapabilities();
      expect(caps.source, 'local_calendar_provider_v0_19'); // v0.19
    });

    test('provider notes mention v0.19 zodiac', () {
      final caps = provider.getCapabilities();
      final notesJoined = caps.notes.join(' ');
      expect(notesJoined.contains('v0.19'), true);
      expect(notesJoined.contains('生肖'), true);
    });

    test('getDayInfo returns lunarDate with available=true', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.lunar.available, true);
    });

    test('getDayInfo lunarDate.status=full (via dataQuality)', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.dataQuality['lunar'], 'full');
    });

    test('getDayInfo lunarDate has displayText', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.lunar.displayText, isNotEmpty);
      expect(day.lunar.displayText.contains('农历'), true);
    });

    test('getDayInfo lunarDate has structured fields', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.lunar.lunarYear, greaterThan(0));
      expect(day.lunar.lunarMonth, greaterThan(0));
      expect(day.lunar.lunarDay, greaterThan(0));
    });

    test('getDayInfo zodiac is available (v0.19)', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.zodiac.available, true); // v0.19: 生肖已启用
      expect(day.zodiac.status, 'full');
    });

    test('getDayInfo ganzhi still unavailable', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.ganzhi.available, false);
    });

    test('getDayInfo solarTerm still unavailable', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.available, false);
    });

    test('getDayInfo clash still unavailable', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.clash.available, false);
    });

    test('out of range date returns unavailable lunar', () {
      final day = provider.getDayInfo(DateTime(1800, 1, 1));
      expect(day.lunar.available, false);
    });

    test('leap month date has isLeapMonth=true in lunarDate', () {
      // 2025 闰六月 - scan for leap date
      for (int m = 7; m <= 8; m++) {
        for (int d = 1; d <= 31; d++) {
          final day = provider.getDayInfo(DateTime(2025, m, d));
          if (day.lunar.isLeapMonth) {
            expect(day.lunar.isLeapMonth, true);
            expect(day.lunar.displayText.contains('闰'), true);
            return;
          }
        }
      }
      fail('2025年应存在闰六月日期');
    });
  });
}

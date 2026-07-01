import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();

  group('CalendarProvider ganzhi capabilities remain unavailable (v0.21)', () {
    test('supportsGanzhiYear = false', () {
      final caps = provider.getCapabilities();
      expect(caps.yearGanzhi, 'unavailable');
    });

    test('supportsGanzhiMonth = false', () {
      final caps = provider.getCapabilities();
      expect(caps.monthGanzhi, 'unavailable');
    });

    test('supportsGanzhiDay = false', () {
      final caps = provider.getCapabilities();
      expect(caps.dayGanzhi, 'unavailable');
    });

    test('lunarDate still available', () {
      final caps = provider.getCapabilities();
      expect(caps.lunarDate, 'full');
    });

    test('zodiac still available', () {
      final caps = provider.getCapabilities();
      expect(caps.zodiac, 'full');
    });

    test('solarTerm still unavailable', () {
      final caps = provider.getCapabilities();
      expect(caps.solarTerm, 'unavailable');
    });

    test('clash still unavailable', () {
      final caps = provider.getCapabilities();
      expect(caps.clash, 'unavailable');
    });
  });

  group('getDayInfo ganzhi still unavailable (v0.21)', () {
    test('ganzhi.available = false', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.ganzhi.available, false);
    });

    test('ganzhi.displayText = 干支信息暂未启用', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.ganzhi.displayText, '干支信息暂未启用');
    });

    test('lunar still available', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.lunar.available, true);
    });

    test('zodiac still available', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.zodiac.available, true);
    });

    test('solarTerm still unavailable', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.available, false);
    });

    test('clash still unavailable', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.clash.available, false);
    });
  });
}

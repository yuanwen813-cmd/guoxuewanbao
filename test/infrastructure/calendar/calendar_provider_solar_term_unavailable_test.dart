import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();

  group('CalendarProvider solarTerm capability remains unavailable (v0.22)', () {
    test('supportsSolarTerm = false', () {
      final caps = provider.getCapabilities();
      expect(caps.solarTerm, 'unavailable');
    });

    test('lunarDate still full', () {
      final caps = provider.getCapabilities();
      expect(caps.lunarDate, 'full');
    });

    test('zodiac still full', () {
      final caps = provider.getCapabilities();
      expect(caps.zodiac, 'full');
    });

    test('ganzhi all still unavailable', () {
      final caps = provider.getCapabilities();
      expect(caps.yearGanzhi, 'unavailable');
      expect(caps.monthGanzhi, 'unavailable');
      expect(caps.dayGanzhi, 'unavailable');
    });

    test('clash still unavailable', () {
      final caps = provider.getCapabilities();
      expect(caps.clash, 'unavailable');
    });
  });

  group('getDayInfo solarTerm still unavailable (v0.22)', () {
    test('solarTerm.available = false', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.available, false);
    });

    test('solarTerm.displayText = 节气信息暂未启用', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.displayText, '节气信息暂未启用');
    });

    test('lunar still available', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.lunar.available, true);
    });

    test('zodiac still available', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.zodiac.available, true);
    });

    test('ganzhi still unavailable', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.ganzhi.available, false);
    });

    test('clash still unavailable', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.clash.available, false);
    });
  });
}

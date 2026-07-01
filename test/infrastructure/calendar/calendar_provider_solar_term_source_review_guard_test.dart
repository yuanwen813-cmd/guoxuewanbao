import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();

  group('CalendarProvider guards during source review (v0.23)', () {
    test('supportsSolarTerm = false', () {
      final caps = provider.getCapabilities();
      expect(caps.solarTerm, 'unavailable');
    });

    test('supportsGanzhiMonth = false', () {
      final caps = provider.getCapabilities();
      expect(caps.monthGanzhi, 'unavailable');
    });

    test('lunarDate still full', () {
      final caps = provider.getCapabilities();
      expect(caps.lunarDate, 'full');
    });

    test('zodiac still full', () {
      final caps = provider.getCapabilities();
      expect(caps.zodiac, 'full');
    });

    test('clash still unavailable', () {
      final caps = provider.getCapabilities();
      expect(caps.clash, 'unavailable');
    });
  });

  group('getDayInfo guards during source review', () {
    test('solarTerm.available = false', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.available, false);
    });

    test('ganzhi.available = false', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.ganzhi.available, false);
    });

    test('lunar available', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.lunar.available, true);
    });

    test('zodiac available', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.zodiac.available, true);
    });
  });
}

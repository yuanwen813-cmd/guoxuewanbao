import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();

  group('CalendarProvider during preparation (v0.24)', () {
    test('supportsSolarTerm = false', () {
      expect(provider.getCapabilities().solarTerm, 'unavailable');
    });
    test('supportsGanzhiMonth = false', () {
      expect(provider.getCapabilities().monthGanzhi, 'unavailable');
    });
    test('lunarDate full', () {
      expect(provider.getCapabilities().lunarDate, 'full');
    });
    test('zodiac full', () {
      expect(provider.getCapabilities().zodiac, 'full');
    });
    test('clash unavailable', () {
      expect(provider.getCapabilities().clash, 'unavailable');
    });
  });

  group('getDayInfo during preparation', () {
    test('solarTerm unavailable', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.available, false);
    });
    test('ganzhi unavailable', () {
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

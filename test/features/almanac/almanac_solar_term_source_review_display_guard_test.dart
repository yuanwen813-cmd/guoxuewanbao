import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();

  group('page display guards during source review (v0.23)', () {
    test('solarTerm displayText = 节气信息暂未启用', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.displayText, '节气信息暂未启用');
    });

    test('ganzhi displayText = 干支信息暂未启用', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.ganzhi.displayText, '干支信息暂未启用');
    });

    test('lunar date displayed', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.lunar.available, true);
      expect(day.lunar.displayText, isNotEmpty);
    });

    test('zodiac displayed', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.zodiac.available, true);
      expect(day.zodiac.zodiac, isNotEmpty);
    });

    test('clash displayText = 冲煞信息暂未启用', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.clash.displayText, '冲煞信息暂未启用');
    });

    test('no solarTerm in page — only in CalendarDayInfo as unavailable', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.available, false);
      expect(day.solarTerm.currentTerm, '');
      expect(day.solarTerm.nextTerm, '');
    });
  });
}

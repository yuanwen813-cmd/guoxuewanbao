import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();

  group('page guards during preparation (v0.24)', () {
    test('solarTerm displayText = 暂未启用', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.displayText, '节气信息暂未启用');
    });
    test('ganzhi displayText = 暂未启用', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.ganzhi.displayText, '干支信息暂未启用');
    });
    test('lunar displayed', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.lunar.available, true);
    });
    test('zodiac displayed', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.zodiac.available, true);
    });
    test('clash unavailable', () {
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.clash.displayText, '冲煞信息暂未启用');
    });
  });
}

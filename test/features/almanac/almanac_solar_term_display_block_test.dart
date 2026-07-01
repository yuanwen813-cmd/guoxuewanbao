import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/features/almanac/almanac_display_policy.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();
  final displayPolicy = AlmanacDisplayPolicy();

  group('page does NOT display solarTerm (v0.22 block)', () {
    test('solarTerm.available = false', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.solarTerm.available, false);
    });

    test('solarTerm displayText is 暂未启用', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.solarTerm.displayText, '节气信息暂未启用');
    });

    test('display policy marks solarTerm as unavailable', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final state = displayPolicy.build(calDay);
      expect(state.solarTerm.available, false);
    });

    test('display policy unavailableReasons includes solarTerm', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final state = displayPolicy.build(calDay);
      expect(state.unavailableReasons.containsKey('solarTerm'), true);
    });

    test('lunar date still displayed', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.lunar.available, true);
    });

    test('zodiac still displayed', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.zodiac.available, true);
    });

    test('ganzhi still unavailable', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.ganzhi.available, false);
    });

    test('clash still unavailable', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.clash.available, false);
    });
  });
}

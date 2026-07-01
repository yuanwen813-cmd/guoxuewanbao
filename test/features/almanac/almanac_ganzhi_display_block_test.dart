import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/calendar/calendar_models.dart';
import 'package:guoxueapp/features/almanac/almanac_display_policy.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();
  final displayPolicy = AlmanacDisplayPolicy();

  group('page does NOT display ganzhi (v0.21 block)', () {
    test('ganzhi.available = false', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.ganzhi.available, false);
    });

    test('ganzhi displayText is 暂未启用', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.ganzhi.displayText, '干支信息暂未启用');
    });

    test('display policy marks ganzhi as unavailable', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final state = displayPolicy.build(calDay);
      expect(state.ganzhi.available, false);
      expect(state.ganzhi.displayText, '干支信息暂未启用');
    });

    test('display policy unavailableReasons includes ganzhi', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final state = displayPolicy.build(calDay);
      expect(state.unavailableReasons.containsKey('ganzhi'), true);
    });

    test('lunar date still displayed', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.lunar.available, true);
    });

    test('zodiac still displayed', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.zodiac.available, true);
    });

    test('solarTerm still unavailable', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.solarTerm.available, false);
    });

    test('clash still unavailable', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.clash.available, false);
    });
  });
}

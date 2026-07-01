import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/domain/calendar/calendar_models.dart';
import 'package:guoxueapp/features/almanac/almanac_display_policy.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();
  final engine = AlmanacEngine();
  final displayPolicy = AlmanacDisplayPolicy();

  group('page displays zodiac (v0.19)', () {
    test('zodiac is available when lunar is available', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.zodiac.available, true);
      expect(calDay.zodiac.zodiac, isNotEmpty);
      expect(calDay.zodiac.displayText, isNotEmpty);
    });

    test('zodiac displayText is the animal name', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.zodiac.zodiac, '马');
      expect(calDay.zodiac.displayText, '马');
    });

    test('lunar date still displayed', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.lunar.available, true);
      expect(calDay.lunar.displayText, isNotEmpty);
    });

    test('ganzhi still unavailable', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.ganzhi.available, false);
      expect(calDay.ganzhi.displayText, '干支信息暂未启用');
    });

    test('solarTerm still unavailable', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.solarTerm.available, false);
      expect(calDay.solarTerm.displayText, '节气信息暂未启用');
    });

    test('clash still unavailable', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.clash.available, false);
      expect(calDay.clash.displayText, '冲煞信息暂未启用');
    });
  });

  group('display policy with zodiac (v0.19)', () {
    test('display policy marks zodiac as available', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final state = displayPolicy.build(calDay);
      expect(state.zodiac.available, true);
      expect(state.zodiac.displayText, isNotEmpty);
    });

    test('display policy still marks ganzhi/solarTerm/clash unavailable', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final state = displayPolicy.build(calDay);
      expect(state.ganzhi.available, false);
      expect(state.solarTerm.available, false);
      expect(state.clash.available, false);
    });

    test('display policy unavailableReasons still has ganzhi/solarTerm/clash', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final state = displayPolicy.build(calDay);
      expect(state.unavailableReasons.containsKey('ganzhi'), true);
      expect(state.unavailableReasons.containsKey('solarTerm'), true);
      expect(state.unavailableReasons.containsKey('clash'), true);
    });

    test('display policy does not mark zodiac as unavailable', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final state = displayPolicy.build(calDay);
      expect(state.unavailableReasons.containsKey('zodiac'), false);
    });

    test('beta notice is included', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final state = displayPolicy.build(calDay);
      expect(state.betaNotices.isNotEmpty, true);
      expect(state.betaNotices.first.contains('黄历 Beta'), true);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/domain/calendar/calendar_models.dart';
import 'package:guoxueapp/features/almanac/almanac_display_policy.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();
  final engine = AlmanacEngine();
  final displayPolicy = AlmanacDisplayPolicy();

  group('page displays lunar date (v0.17)', () {
    test('almanac page shows real lunar date', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.lunar.available, true);
      expect(calDay.lunar.displayText, isNotEmpty);
    });

    test('lunar displayText is not empty for in-range dates', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.lunar.displayText, isNotEmpty);
      expect(calDay.lunar.displayText, isNot('农历信息暂未启用'));
    });

    test('leap month date displays 闰 character', () {
      // 2025 闰六月
      bool foundLeap = false;
      for (int m = 7; m <= 8; m++) {
        for (int d = 1; d <= 31; d++) {
          final calDay = provider.getDayInfo(DateTime(2025, m, d));
          if (calDay.lunar.isLeapMonth) {
            foundLeap = true;
            expect(calDay.lunar.displayText.contains('闰'), true);
            break;
          }
        }
        if (foundLeap) break;
      }
      expect(foundLeap, true, reason: 'Should find leap month date in 2025');
    });

    test('zodiac is available (v0.19)', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.zodiac.available, true); // v0.19: 生肖已启用
      expect(calDay.zodiac.zodiac, isNotEmpty);
    });

    test('ganzhi still shows unavailable', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.ganzhi.available, false);
      expect(calDay.ganzhi.displayText, '干支信息暂未启用');
    });

    test('solarTerm still shows unavailable', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.solarTerm.available, false);
      expect(calDay.solarTerm.displayText, '节气信息暂未启用');
    });

    test('clash still shows unavailable', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.clash.available, false);
      expect(calDay.clash.displayText, '冲煞信息暂未启用');
    });
  });

  group('display policy (v0.17)', () {
    test('display policy marks lunarDate as available when lunar is active', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final state = displayPolicy.build(calDay);
      expect(state.lunar.available, true);
      expect(state.lunar.displayText, isNotEmpty);
      expect(state.visibleFieldKeys.contains('lunarDate'), true);
    });

    test('display policy marks ganzhi/solarTerm/clash as unavailable, zodiac available', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final state = displayPolicy.build(calDay);
      expect(state.zodiac.available, true); // v0.19: 生肖已启用
      expect(state.ganzhi.available, false);
      expect(state.solarTerm.available, false);
      expect(state.clash.available, false);
    });

    test('display policy unavailableReasons includes non-lunar fields (no zodiac)', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final state = displayPolicy.build(calDay);
      expect(state.unavailableReasons.containsKey('ganzhi'), true);
      expect(state.unavailableReasons.containsKey('zodiac'), false); // v0.19: zodiac is available
      expect(state.unavailableReasons.containsKey('solarTerm'), true);
      expect(state.unavailableReasons.containsKey('clash'), true);
    });

    test('beta notice is included', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final state = displayPolicy.build(calDay);
      expect(state.betaNotices.isNotEmpty, true);
      expect(state.betaNotices.first.contains('黄历 Beta'), true);
    });
  });

  group('AlmanacEngine includes lunar data in snapshot (v0.17)', () {
    test('AlmanacDay includes lunarData when provided', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final lunarSnapshot = calDay.lunar.available ? <String, dynamic>{
        'available': calDay.lunar.available,
        'lunarYear': calDay.lunar.lunarYear,
        'lunarMonth': calDay.lunar.lunarMonth,
        'lunarDay': calDay.lunar.lunarDay,
        'isLeapMonth': calDay.lunar.isLeapMonth,
        'displayText': calDay.lunar.displayText,
        'source': 'local_lunar_calendar_engine_v0_16',
        'status': 'full',
      } : null;

      final almanacDay = engine.getDay(
        DateTime(2026, 6, 22),
        lunarDateDisplay: calDay.lunar.available ? calDay.lunar.displayText : null,
        lunarDataSnapshot: lunarSnapshot,
      );

      expect(almanacDay.lunarDate, isNot('农历信息暂未启用'));
      expect(almanacDay.lunarData, isNotNull);
      expect(almanacDay.lunarData!['available'], true);
      expect(almanacDay.lunarData!['lunarYear'], greaterThan(0));
      expect(almanacDay.lunarData!['lunarMonth'], greaterThan(0));
      expect(almanacDay.lunarData!['lunarDay'], greaterThan(0));
      expect(almanacDay.lunarData!['displayText'], isNotEmpty);
      expect(almanacDay.lunarData!['source'], 'local_lunar_calendar_engine_v0_16');
      expect(almanacDay.lunarData!['status'], 'full');
    });

    test('toJson includes lunarData when present', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final lunarSnapshot = <String, dynamic>{
        'available': true,
        'lunarYear': 2026,
        'lunarMonth': 5,
        'lunarDay': 8,
        'isLeapMonth': false,
        'displayText': '农历五月初八',
        'source': 'local_lunar_calendar_engine_v0_16',
        'status': 'full',
      };
      final almanacDay = engine.getDay(
        DateTime(2026, 6, 22),
        lunarDateDisplay: '农历五月初八',
        lunarDataSnapshot: lunarSnapshot,
      );
      final json = almanacDay.toJson();
      expect(json.containsKey('lunarData'), true);
      expect(json['lunarData']['lunarYear'], 2026);
      expect(json['lunarData']['lunarMonth'], 5);
      expect(json['lunarData']['lunarDay'], 8);
    });
  });
}

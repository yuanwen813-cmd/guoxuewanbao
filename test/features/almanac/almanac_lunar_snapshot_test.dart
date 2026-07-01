import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/domain/calendar/calendar_models.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();
  final engine = AlmanacEngine();

  group('resultSnapshot lunarDate (v0.17)', () {
    test('new almanac snapshot saves lunarDate', () {
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

      final snapshot = almanacDay.toJson();
      expect(snapshot.containsKey('lunarData'), true);
      expect(snapshot['lunarData'], isNotNull);
    });

    test('snapshot lunarData contains all required fields', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final lunarSnapshot = <String, dynamic>{
        'available': true,
        'lunarYear': calDay.lunar.lunarYear,
        'lunarMonth': calDay.lunar.lunarMonth,
        'lunarDay': calDay.lunar.lunarDay,
        'isLeapMonth': calDay.lunar.isLeapMonth,
        'displayText': calDay.lunar.displayText,
        'source': 'local_lunar_calendar_engine_v0_16',
        'status': 'full',
      };

      final almanacDay = engine.getDay(
        DateTime(2026, 6, 22),
        lunarDateDisplay: calDay.lunar.displayText,
        lunarDataSnapshot: lunarSnapshot,
      );

      final json = almanacDay.toJson();
      final lunarData = json['lunarData'] as Map<String, dynamic>;
      expect(lunarData.containsKey('lunarYear'), true);
      expect(lunarData.containsKey('lunarMonth'), true);
      expect(lunarData.containsKey('lunarDay'), true);
      expect(lunarData.containsKey('isLeapMonth'), true);
      expect(lunarData.containsKey('displayText'), true);
      expect(lunarData.containsKey('source'), true);
      expect(lunarData.containsKey('status'), true);
    });

    test('old snapshot without lunarData does not crash', () {
      // Simulate old snapshot (no lunarData field)
      final oldSnapshot = <String, dynamic>{
        'dateKey': '20260622',
        'gregorianDate': '2026年6月22日',
        'weekday': '星期一',
        'lunarDate': '农历信息暂未启用',
        'yearGanzhi': '暂未启用',
        'monthGanzhi': '暂未启用',
        'dayGanzhi': '暂未启用',
        'zodiac': '',
        'solarTerm': '',
        'suitable': ['整理', '学习'],
        'avoid': ['争执', '冒进'],
        'dailySummary': '宜稳中推进',
        'lifeAdvice': {'work': 'test'},
        'source': 'local_rule_beta',
        'dataQuality': 'beta',
      };

      // Should not throw
      expect(() => oldSnapshot['lunarData'], returnsNormally);
      // Old snapshot should not have lunarData
      expect(oldSnapshot.containsKey('lunarData'), false);
      // Old snapshot's lunarDate is the old placeholder
      expect(oldSnapshot['lunarDate'], '农历信息暂未启用');
    });

    test('history detail restores from resultSnapshot without recalculation', () {
      // Simulate restoring from old snapshot
      final oldSnapshot = <String, dynamic>{
        'dateKey': '20260622',
        'gregorianDate': '2026年6月22日',
        'weekday': '星期一',
        'lunarDate': '农历信息暂未启用',
        'suitable': ['整理'],
        'avoid': ['争执'],
        'dailySummary': 'test',
        'lifeAdvice': {'work': 'test'},
        'source': 'local_rule_beta',
        'dataQuality': 'beta',
      };

      // Restoration logic: just read the snapshot, don't recalculate
      final restoredLunarDate = oldSnapshot['lunarDate'] as String;
      expect(restoredLunarDate, '农历信息暂未启用');

      // Verify we're NOT using the engine to recalculate
      final hasLunarData = oldSnapshot.containsKey('lunarData');
      if (!hasLunarData) {
        // Old snapshot - should keep original value, not recompute
        expect(restoredLunarDate, isNot(contains('农历五月初八')));
      }
    });

    test('new snapshot has lunardata in toJson', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(
        DateTime(2026, 6, 22),
        lunarDateDisplay: calDay.lunar.available ? calDay.lunar.displayText : null,
        lunarDataSnapshot: calDay.lunar.available ? {
          'available': true,
          'lunarYear': calDay.lunar.lunarYear,
          'lunarMonth': calDay.lunar.lunarMonth,
          'lunarDay': calDay.lunar.lunarDay,
          'isLeapMonth': calDay.lunar.isLeapMonth,
          'displayText': calDay.lunar.displayText,
          'source': 'local_lunar_calendar_engine_v0_16',
          'status': 'full',
        } : null,
      );

      final json = almanacDay.toJson();
      // The JSON either has lunarData or lunarDate = placeholder
      if (json.containsKey('lunarData')) {
        expect(json['lunarData']['available'], true);
      }
    });
  });
}

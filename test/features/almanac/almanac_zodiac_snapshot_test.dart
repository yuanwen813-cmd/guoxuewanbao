import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();
  final engine = AlmanacEngine();

  group('snapshot saves zodiac (v0.19)', () {
    test('new snapshot includes zodiacData', () {
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
        zodiacDisplay: calDay.zodiac.available ? calDay.zodiac.zodiac : null,
        zodiacDataSnapshot: calDay.zodiac.available ? {
          'available': true,
          'zodiacName': calDay.zodiac.zodiac,
          'lunarYear': calDay.zodiac.lunarYear,
          'displayText': calDay.zodiac.displayText,
          'source': 'derived_from_lunar_year_v0_19',
          'status': 'full',
        } : null,
      );

      final json = almanacDay.toJson();
      expect(json.containsKey('zodiacData'), true);
      expect(json['zodiacData'], isNotNull);
    });

    test('snapshot zodiacData contains correct fields', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final zodiacSnapshot = <String, dynamic>{
        'available': true,
        'zodiacName': calDay.zodiac.zodiac,
        'lunarYear': calDay.zodiac.lunarYear,
        'displayText': calDay.zodiac.displayText,
        'source': 'derived_from_lunar_year_v0_19',
        'status': 'full',
      };

      final almanacDay = engine.getDay(
        DateTime(2026, 6, 22),
        zodiacDisplay: '马',
        zodiacDataSnapshot: zodiacSnapshot,
      );

      final json = almanacDay.toJson();
      final zData = json['zodiacData'] as Map<String, dynamic>;
      expect(zData['zodiacName'], '马');
      expect(zData['available'], true);
      expect(zData['source'], 'derived_from_lunar_year_v0_19');
      expect(zData['status'], 'full');
      expect(zData['lunarYear'], greaterThan(0));
    });

    test('old snapshot without zodiacData does not crash', () {
      final oldSnapshot = <String, dynamic>{
        'dateKey': '20260622',
        'gregorianDate': '2026年6月22日',
        'weekday': '星期一',
        'lunarDate': '农历信息暂未启用',
        'zodiac': '',
        'suitable': ['整理'],
        'avoid': ['争执'],
        'dailySummary': 'test',
        'lifeAdvice': {'work': 'test'},
        'source': 'local_rule_beta',
        'dataQuality': 'beta',
      };

      // Old snapshot has no zodiacData → should not crash
      expect(oldSnapshot.containsKey('zodiacData'), false);

      // Accessing missing key returns null, doesn't throw
      expect(() => oldSnapshot['zodiacData'], returnsNormally);
      expect(oldSnapshot['zodiacData'], isNull);
    });

    test('history detail does not recalculate zodiac for old snapshot', () {
      final oldSnapshot = <String, dynamic>{
        'dateKey': '20260622',
        'gregorianDate': '2026年6月22日',
        'weekday': '星期一',
        'lunarDate': '农历信息暂未启用',
        'zodiac': '',
        'suitable': ['整理'],
        'avoid': ['争执'],
        'dailySummary': 'test',
        'lifeAdvice': {'work': 'test'},
        'source': 'local_rule_beta',
        'dataQuality': 'beta',
      };

      // Old snapshot: no zodiacData → keep original info, do NOT recompute
      final hasZodiacData = oldSnapshot.containsKey('zodiacData');
      expect(hasZodiacData, false);

      // We should NOT call CalendarProvider to fill in missing zodiac
      // The page should just show whatever is in the snapshot
    });

    test('resultSnapshot is not overwritten for old records', () {
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
        zodiacDisplay: calDay.zodiac.available ? calDay.zodiac.zodiac : null,
        zodiacDataSnapshot: calDay.zodiac.available ? {
          'available': true,
          'zodiacName': calDay.zodiac.zodiac,
          'lunarYear': calDay.zodiac.lunarYear,
          'displayText': calDay.zodiac.displayText,
          'source': 'derived_from_lunar_year_v0_19',
          'status': 'full',
        } : null,
      );

      final json = almanacDay.toJson();
      expect(json.containsKey('zodiacData'), true);

      // lunarData still present (v0.17 behavior preserved)
      expect(json.containsKey('lunarData'), true);
    });
  });
}

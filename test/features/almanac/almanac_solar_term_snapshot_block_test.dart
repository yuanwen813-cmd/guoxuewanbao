import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();

  group('snapshot does NOT formally write solarTermData (v0.22 block)', () {
    test('snapshot has no solarTermData key', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(
        DateTime(2026, 6, 22),
        lunarDateDisplay: calDay.lunar.displayText,
        lunarDataSnapshot: {'available': true, 'lunarYear': 2026, 'status': 'full'},
        zodiacDisplay: calDay.zodiac.zodiac,
        zodiacDataSnapshot: {'available': true, 'zodiacName': '马', 'status': 'full'},
      );

      final json = almanacDay.toJson();
      expect(json.containsKey('solarTermData'), false);
    });

    test('no ganzhiData in snapshot either', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(
        DateTime(2026, 6, 22),
        lunarDateDisplay: calDay.lunar.displayText,
        zodiacDisplay: calDay.zodiac.zodiac,
      );

      final json = almanacDay.toJson();
      expect(json.containsKey('ganzhiData'), false);
    });

    test('lunarData still present', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(
        DateTime(2026, 6, 22),
        lunarDateDisplay: calDay.lunar.displayText,
        lunarDataSnapshot: {'available': true, 'lunarYear': 2026, 'status': 'full'},
        zodiacDisplay: calDay.zodiac.zodiac,
        zodiacDataSnapshot: {'available': true, 'zodiacName': '马', 'status': 'full'},
      );

      final json = almanacDay.toJson();
      expect(json.containsKey('lunarData'), true);
    });

    test('zodiacData still present', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(
        DateTime(2026, 6, 22),
        lunarDateDisplay: calDay.lunar.displayText,
        zodiacDisplay: calDay.zodiac.zodiac,
        zodiacDataSnapshot: {'available': true, 'zodiacName': '马', 'status': 'full'},
      );

      final json = almanacDay.toJson();
      expect(json.containsKey('zodiacData'), true);
    });

    test('old snapshot without solarTermData compatible', () {
      final oldSnapshot = <String, dynamic>{
        'dateKey': '20260622',
        'gregorianDate': '2026年6月22日',
        'weekday': '星期一',
        'lunarDate': '农历信息暂未启用',
        'zodiac': '',
        'solarTerm': '',
        'suitable': ['整理'],
        'avoid': ['争执'],
        'dailySummary': 'test',
        'lifeAdvice': {'work': 'test'},
        'source': 'local_rule_beta',
        'dataQuality': 'beta',
      };

      expect(oldSnapshot.containsKey('solarTermData'), false);
      expect(() => oldSnapshot['solarTermData'], returnsNormally);
    });

    test('old history does not recalculate solarTerm', () {
      final oldSnapshot = <String, dynamic>{
        'dateKey': '20260622',
        'gregorianDate': '2026年6月22日',
        'weekday': '星期一',
        'lunarDate': '农历信息暂未启用',
        'zodiac': '',
        'solarTerm': '',
        'suitable': ['整理'],
        'avoid': ['争执'],
        'dailySummary': 'test',
        'lifeAdvice': {'work': 'test'},
        'source': 'local_rule_beta',
        'dataQuality': 'beta',
      };

      expect(oldSnapshot.containsKey('solarTermData'), false);
      expect(oldSnapshot['solarTerm'], '');
    });
  });
}

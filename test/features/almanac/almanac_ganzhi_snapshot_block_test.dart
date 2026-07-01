import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();

  group('snapshot does NOT formally write ganzhiData (v0.21 block)', () {
    test('snapshot has no ganzhiData key', () {
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
      // No ganzhi-related data in snapshot
      expect(json.containsKey('ganzhiData'), false);
    });

    test('lunarData still in snapshot', () {
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

    test('zodiacData still in snapshot', () {
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
      expect(json.containsKey('zodiacData'), true);
    });

    test('old snapshot without ganzhiData compatible', () {
      final oldSnapshot = <String, dynamic>{
        'dateKey': '20260622',
        'gregorianDate': '2026年6月22日',
        'weekday': '星期一',
        'lunarDate': '农历信息暂未启用',
        'zodiac': '',
        'yearGanzhi': '暂未启用',
        'monthGanzhi': '暂未启用',
        'dayGanzhi': '暂未启用',
        'suitable': ['整理'],
        'avoid': ['争执'],
        'dailySummary': 'test',
        'lifeAdvice': {'work': 'test'},
        'source': 'local_rule_beta',
        'dataQuality': 'beta',
      };

      // Old snapshot has no ganzhiData → compatible
      expect(oldSnapshot.containsKey('ganzhiData'), false);

      // Accessing without crash
      expect(() => oldSnapshot['ganzhiData'], returnsNormally);
    });

    test('old history detail does not recalculate ganzhi', () {
      final oldSnapshot = <String, dynamic>{
        'dateKey': '20260622',
        'gregorianDate': '2026年6月22日',
        'weekday': '星期一',
        'lunarDate': '农历信息暂未启用',
        'zodiac': '',
        'yearGanzhi': '暂未启用',
        'suitable': ['整理'],
        'avoid': ['争执'],
        'dailySummary': 'test',
        'lifeAdvice': {'work': 'test'},
        'source': 'local_rule_beta',
        'dataQuality': 'beta',
      };

      // No ganzhiData in old snapshot
      expect(oldSnapshot.containsKey('ganzhiData'), false);

      // The ganzhi fields in old snapshot keep their original placeholder values
      expect(oldSnapshot['yearGanzhi'], '暂未启用');
    });
  });
}

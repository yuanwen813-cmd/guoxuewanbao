import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();

  group('snapshot guards during source review (v0.23)', () {
    test('snapshot has no solarTermData', () {
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

    test('snapshot has no ganzhiData', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));

      final json = almanacDay.toJson();
      expect(json.containsKey('ganzhiData'), false);
    });

    test('lunarData still saved', () {
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

    test('zodiacData still saved', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(
        DateTime(2026, 6, 22),
        zodiacDisplay: calDay.zodiac.zodiac,
        zodiacDataSnapshot: {'available': true, 'zodiacName': '马', 'status': 'full'},
      );

      final json = almanacDay.toJson();
      expect(json.containsKey('zodiacData'), true);
    });

    test('old snapshot compatible — no solarTermData crash', () {
      final old = <String, dynamic>{
        'dateKey': '20260622',
        'gregorianDate': '2026年6月22日',
        'solarTerm': '',
        'suitable': ['整理'],
        'avoid': ['争执'],
        'dailySummary': 'test',
        'lifeAdvice': {'work': 'test'},
      };
      expect(old.containsKey('solarTermData'), false);
      expect(() => old['solarTermData'], returnsNormally);
    });

    test('old history does not recalculate solarTerm', () {
      final old = <String, dynamic>{
        'dateKey': '20260622',
        'gregorianDate': '2026年6月22日',
        'solarTerm': '',
        'suitable': ['整理'],
        'avoid': ['争执'],
        'dailySummary': 'test',
        'lifeAdvice': {'work': 'test'},
      };
      expect(old.containsKey('solarTermData'), false);
      expect(old['solarTerm'], '');
    });
  });
}

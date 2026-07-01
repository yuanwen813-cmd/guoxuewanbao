import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final p = LocalCalendarProvider();
  final e = AlmanacEngine();

  group('snapshot guards during preparation (v0.24)', () {
    test('no solarTermData', () {
      final d = p.getDayInfo(DateTime(2026, 6, 22));
      final a = e.getDay(DateTime(2026, 6, 22),
        lunarDateDisplay: d.lunar.displayText,
        lunarDataSnapshot: {'available': true},
        zodiacDisplay: d.zodiac.zodiac,
        zodiacDataSnapshot: {'available': true},
      );
      expect(a.toJson().containsKey('solarTermData'), false);
    });
    test('no ganzhiData', () {
      expect(e.getDay(DateTime(2026, 6, 22)).toJson().containsKey('ganzhiData'), false);
    });
    test('lunarData saved', () {
      final d = p.getDayInfo(DateTime(2026, 6, 22));
      final a = e.getDay(DateTime(2026, 6, 22), lunarDateDisplay: d.lunar.displayText, lunarDataSnapshot: {'available': true});
      expect(a.toJson().containsKey('lunarData'), true);
    });
    test('zodiacData saved', () {
      final a = e.getDay(DateTime(2026, 6, 22), zodiacDisplay: '马', zodiacDataSnapshot: {'available': true});
      expect(a.toJson().containsKey('zodiacData'), true);
    });
    test('old snapshot compatible', () {
      final old = <String, dynamic>{'dateKey': '20260622', 'solarTerm': '', 'suitable': []};
      expect(old.containsKey('solarTermData'), false);
      expect(() => old['solarTermData'], returnsNormally);
    });
    test('old history no recalc', () {
      final old = <String, dynamic>{'dateKey': '20260622', 'solarTerm': ''};
      expect(old.containsKey('solarTermData'), false);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
void main() {
  final e = AlmanacEngine();
  group('v0.52 snapshot: public fields can be saved', () {
    test('solarTermData can be saved', () {
      final a = e.getDay(DateTime(2026,6,22));
      // Snapshot structure supports solarTerm field but we test no crash
      expect(a.toJson().containsKey('solarTerm'), true);
    });
    test('ganzhi fields present in toJson', () {
      final a = e.getDay(DateTime(2026,6,22));
      expect(a.toJson().containsKey('yearGanzhi'), true);
      expect(a.toJson().containsKey('dayGanzhi'), true);
    });
    test('zodiac field present', () {
      final a = e.getDay(DateTime(2026,6,22));
      expect(a.toJson().containsKey('zodiac'), true);
    });
    test('no trialSolarTermData', () { expect(e.getDay(DateTime(2026,6,22)).toJson().containsKey('trialSolarTermData'), false); });
    test('no internalGanzhiData', () { expect(e.getDay(DateTime(2026,6,22)).toJson().containsKey('internalGanzhiData'), false); });
    test('no internalClashData', () { expect(e.getDay(DateTime(2026,6,22)).toJson().containsKey('internalClashData'), false); });
    test('no hourGanzhiData', () { expect(e.getDay(DateTime(2026,6,22)).toJson().containsKey('hourGanzhiData'), false); });
  });
}

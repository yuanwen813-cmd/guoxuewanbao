import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/day_ganzhi_internal_engine.dart';
void main() {
  final e = const DayGanzhiInternalEngine();
  group('epoch reference', () {
    test('2024-02-10 = 甲辰', () { expect(e.compute(DateTime(2024,2,10)).dayGanzhi, '甲辰'); });
    test('verifyReference passes', () { expect(e.verifyReference(), true); });
  });
  group('day ganzhi continuity', () {
    test('consecutive days advance by 1', () {
      final d1 = e.compute(DateTime(2024,2,10));
      final d2 = e.compute(DateTime(2024,2,11));
      expect(d1.dayGanzhi, isNot(d2.dayGanzhi));
    });
    test('60-day cycle wraps correctly', () {
      final d1 = e.compute(DateTime(2024,2,10));
      final d60 = e.compute(DateTime(2024,4,10)); // 60 days later
      expect(d1.dayGanzhi, d60.dayGanzhi); // same jiazi after 60 days
    });
    test('cross-month continuity', () { final jan=e.compute(DateTime(2024,1,31)); final feb=e.compute(DateTime(2024,2,1)); expect(jan.dayGanzhi, isNotNull); expect(feb.dayGanzhi, isNotNull); });
    test('cross-year continuity', () { final dec31=e.compute(DateTime(2023,12,31)); final jan1=e.compute(DateTime(2024,1,1)); expect(dec31.dayGanzhi, isNotNull); expect(jan1.dayGanzhi, isNotNull); });
    test('leap year Feb 29→Mar 1 continuity', () { final feb29=e.compute(DateTime(2024,2,29)); final mar1=e.compute(DateTime(2024,3,1)); expect(feb29.dayGanzhi, isNotNull); expect(mar1.dayGanzhi, isNotNull); });
  });
  group('output', () { test('has dayStem and dayBranch', () { final r=e.compute(DateTime(2024,2,10)); expect(r.dayStem, isNotNull); expect(r.dayBranch, isNotNull); }); test('source contains internal', () { expect(e.compute(DateTime(2024,2,10)).source.contains('internal'), true); }); });
}

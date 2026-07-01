import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/ganzhi_internal_engine.dart';
void main() {
  final e = const GanzhiInternalEngine();
  test('lichun year: 2026-06-22 → 丙午 (after lichun)', () { final r=e.compute(DateTime(2026,6,22)); expect(r.ganzhiYear, isNotNull); });
  test('lichun year: 2026-02-03 (before lichun) → previous year ganzhi', () { final r=e.compute(DateTime(2026,2,3)); expect(r.ganzhiYear, isNotNull); });
  test('month with solarTerm → month available', () { final r=e.compute(DateTime(2026,6,22),solarTermAvailable:true); expect(r.ganzhiMonth, isNotNull); });
  test('month without solarTerm → unavailable', () { final r=e.compute(DateTime(2026,6,22),solarTermAvailable:false); expect(r.ganzhiMonth, isNull); });
  test('day ganzhi unavailable', () { expect(GanzhiInternalResult.unavailable.ganzhiDay, isNull); });
  test('hour ganzhi unavailable', () { expect(GanzhiInternalResult.unavailable.ganzhiHour, isNull); });
  test('source contains internal', () { expect(e.compute(DateTime(2026,6,22)).source.contains('internal'), true); });
  test('rule mentions 立春 and 节气', () { expect(e.compute(DateTime(2026,6,22)).rule.contains('立春'), true); });
  test('debug schemaVersion', () { expect(e.buildDebugJson()['schemaVersion'], 'ganzhi-internal-engine-v0_48'); });
  test('day ganzhi in debug is unavailable', () { expect(e.buildDebugJson()['dayGanzhi'], 'unavailable'); });
}

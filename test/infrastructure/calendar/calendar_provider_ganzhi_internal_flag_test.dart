import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/ganzhi_internal_feature_flag.dart';
void main() {
  final p = LocalCalendarProvider();
  group('CalendarProvider ganzhi flag', () {
    test('default → yearGanzhi unavailable', () { p.setGanzhiFlag(GanzhiInternalFeatureFlag.defaultDisabled); expect(p.getCapabilities().yearGanzhi, 'unavailable'); });
    test('default → monthGanzhi unavailable', () { p.setGanzhiFlag(GanzhiInternalFeatureFlag.defaultDisabled); expect(p.getCapabilities().monthGanzhi, 'unavailable'); });
    test('debug → yearGanzhi internal', () { p.setGanzhiFlag(GanzhiInternalFeatureFlag.debugEnabled); expect(p.getCapabilities().yearGanzhi, 'internal'); });
    test('debug → monthGanzhi internal', () { p.setGanzhiFlag(GanzhiInternalFeatureFlag.debugEnabled); expect(p.getCapabilities().monthGanzhi, 'internal'); });
    test('debug → dayGanzhi still unavailable', () { p.setGanzhiFlag(GanzhiInternalFeatureFlag.debugEnabled); expect(p.getCapabilities().dayGanzhi, 'unavailable'); });
    test('debug → getDayInfo ganzhi available', () { p.setGanzhiFlag(GanzhiInternalFeatureFlag.debugEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.available, true); });
    test('default → getDayInfo ganzhi unavailable', () { p.setGanzhiFlag(GanzhiInternalFeatureFlag.defaultDisabled); expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.available, false); });
    test('lunar unaffected', () { p.setGanzhiFlag(GanzhiInternalFeatureFlag.debugEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).lunar.available, true); });
    test('zodiac unaffected', () { p.setGanzhiFlag(GanzhiInternalFeatureFlag.debugEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).zodiac.available, true); });
    test('clash still unavailable', () { p.setGanzhiFlag(GanzhiInternalFeatureFlag.debugEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).clash.available, false); });
  });
}

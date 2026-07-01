import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/day_ganzhi_internal_feature_flag.dart';
void main() {
  final p = LocalCalendarProvider();
  group('CalendarProvider day ganzhi/clash flag', () {
    test('default→dayGanzhi unavailable', () { p.setDayGanzhiClashFlag(DayGanzhiInternalFeatureFlag.defaultDisabled); expect(p.getCapabilities().dayGanzhi, 'unavailable'); });
    test('default→clash unavailable', () { p.setDayGanzhiClashFlag(DayGanzhiInternalFeatureFlag.defaultDisabled); expect(p.getCapabilities().clash, 'unavailable'); });
    test('debug→dayGanzhi=internal', () { p.setDayGanzhiClashFlag(DayGanzhiInternalFeatureFlag.debugEnabled); expect(p.getCapabilities().dayGanzhi, 'internal'); });
    test('debug→clash=internal', () { p.setDayGanzhiClashFlag(DayGanzhiInternalFeatureFlag.debugEnabled); expect(p.getCapabilities().clash, 'internal'); });
    test('debug→getDayInfo dayGanzhi populated', () { p.setDayGanzhiClashFlag(DayGanzhiInternalFeatureFlag.debugEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.dayGanzhi, isNotEmpty); });
    test('production→dayGanzhi unavailable', () { final f=DayGanzhiInternalFeatureFlag(enabled:true,environment:DayGanzhiFeatureEnvironment.production,dayGanzhiAllowed:true); p.setDayGanzhiClashFlag(f); expect(p.getCapabilities().dayGanzhi, 'unavailable'); });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/day_ganzhi_clash_public_feature_flag.dart';
void main() {
  final p = LocalCalendarProvider();
  group('flag', () {
    test('default disabled', () { expect(DayGanzhiClashPublicFeatureFlag.defaultDisabled.dayGanzhiPublicEnabled, false); });
    test('clash default false', () { expect(DayGanzhiClashPublicFeatureFlag.defaultDisabled.clashPublicEnabled, false); });
    test('share defaults false', () { expect(DayGanzhiClashPublicFeatureFlag.publicEnabled.dayGanzhiShareEnabled, false); });
    test('snapshot defaults false', () { expect(DayGanzhiClashPublicFeatureFlag.publicEnabled.clashSnapshotEnabled, false); });
    test('hour false', () { expect(DayGanzhiClashPublicFeatureFlag.publicEnabled.hourGanzhiEnabled, false); });
    test('sourceIsSafe', () { expect(DayGanzhiClashPublicFeatureFlag.publicEnabled.sourceIsSafe, true); });
    test('sourceIsSafe rejects internal', () { expect(DayGanzhiClashPublicFeatureFlag(dayGanzhiPublicEnabled:true,source:'internal_x').sourceIsSafe, false); });
  });
  group('CalendarProvider public', () {
    test('default→dayGanzhi unavailable', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.defaultDisabled); expect(p.getCapabilities().dayGanzhi, 'unavailable'); });
    test('public→dayGanzhi full', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.publicEnabled); expect(p.getCapabilities().dayGanzhi, 'full'); });
    test('public→clash full', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.publicEnabled); expect(p.getCapabilities().clash, 'full'); });
    test('dayGanzhi populated when public', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.dayGanzhi, isNotEmpty); });
    test('clash populated when public', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).clash.available, true); });
  });
}

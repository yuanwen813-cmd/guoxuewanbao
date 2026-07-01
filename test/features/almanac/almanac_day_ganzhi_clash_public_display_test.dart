import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/day_ganzhi_clash_public_feature_flag.dart';
void main() {
  final p = LocalCalendarProvider();
  group('v0.51 public display', () {
    test('public→dayGanzhi populated', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.dayGanzhi, isNotEmpty); });
    test('public→clash populated', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).clash.available, true); });
    test('public→clash has displayText', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).clash.displayText, isNotEmpty); });
    test('default→dayGanzhi empty', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.defaultDisabled); expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.dayGanzhi, ''); });
    test('default→clash unavailable', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.defaultDisabled); expect(p.getDayInfo(DateTime(2026,6,22)).clash.available, false); });
    test('lunar/zodiac ok', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.publicEnabled); final d=p.getDayInfo(DateTime(2026,6,22)); expect(d.lunar.available, true); expect(d.zodiac.available, true); });
  });
}

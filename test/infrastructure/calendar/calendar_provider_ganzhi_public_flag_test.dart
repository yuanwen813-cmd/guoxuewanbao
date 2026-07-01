import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/ganzhi_public_feature_flag.dart';
void main() {
  final p = LocalCalendarProvider();
  group('GanzhiPublicFeatureFlag', () {
    test('default disabled', () { expect(GanzhiPublicFeatureFlag.defaultDisabled.ganzhiPublicEnabled, false); });
    test('year disabled', () { expect(GanzhiPublicFeatureFlag.defaultDisabled.yearGanzhiEnabled, false); });
    test('month disabled', () { expect(GanzhiPublicFeatureFlag.defaultDisabled.monthGanzhiEnabled, false); });
    test('day forced false', () { expect(GanzhiPublicFeatureFlag.defaultDisabled.dayGanzhiEnabled, false); expect(GanzhiPublicFeatureFlag.publicEnabled.dayGanzhiEnabled, false); });
    test('hour forced false', () { expect(GanzhiPublicFeatureFlag.publicEnabled.hourGanzhiEnabled, false); });
    test('clash false', () { expect(GanzhiPublicFeatureFlag.publicEnabled.clashDependencyAllowed, false); });
    test('share default false', () { expect(GanzhiPublicFeatureFlag.publicEnabled.ganzhiShareEnabled, false); });
    test('snapshot default false', () { expect(GanzhiPublicFeatureFlag.publicEnabled.ganzhiSnapshotEnabled, false); });
    test('sourceIsSafe', () { expect(GanzhiPublicFeatureFlag.publicEnabled.sourceIsSafe, true); });
    test('sourceIsSafe rejects internal', () { expect(GanzhiPublicFeatureFlag(ganzhiPublicEnabled:true,source:'internal_src').sourceIsSafe, false); });
    test('sourceIsSafe rejects trial', () { expect(GanzhiPublicFeatureFlag(ganzhiPublicEnabled:true,source:'trial_v1').sourceIsSafe, false); });
  });
  group('CalendarProvider public ganzhi', () {
    test('default → yearGanzhi unavailable', () { p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.defaultDisabled); expect(p.getCapabilities().yearGanzhi, 'unavailable'); });
    test('publicEnabled → yearGanzhi full', () { p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.publicEnabled); expect(p.getCapabilities().yearGanzhi, 'full'); });
    test('publicEnabled → monthGanzhi full', () { p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.publicEnabled); expect(p.getCapabilities().monthGanzhi, 'full'); });
    test('dayGanzhi always unavailable', () { p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.publicEnabled); expect(p.getCapabilities().dayGanzhi, 'unavailable'); });
  });
}

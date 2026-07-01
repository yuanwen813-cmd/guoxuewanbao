import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/ganzhi_internal_feature_flag.dart';
void main() {
  test('default disabled', () { expect(GanzhiInternalFeatureFlag.defaultDisabled.internalGanzhiAllowed, false); });
  test('debug enabled → allowed', () { expect(GanzhiInternalFeatureFlag.debugEnabled.internalGanzhiAllowed, true); });
  test('internal enabled → allowed', () { expect(GanzhiInternalFeatureFlag.internalEnabled.internalGanzhiAllowed, true); });
  test('production enabled → still blocked', () { final f=GanzhiInternalFeatureFlag(enabled:true,environment:GanzhiFeatureEnvironment.production); expect(f.internalGanzhiAllowed, false); });
  test('yearGanzhiAllowed default true', () { expect(GanzhiInternalFeatureFlag.debugEnabled.yearGanzhiAllowed, true); });
  test('monthGanzhiAllowed default true', () { expect(GanzhiInternalFeatureFlag.debugEnabled.monthGanzhiAllowed, true); });
  test('dayGanzhiAllowed false', () { expect(GanzhiInternalFeatureFlag.debugEnabled.dayGanzhiAllowed, false); });
  test('hourGanzhiAllowed false', () { expect(GanzhiInternalFeatureFlag.debugEnabled.hourGanzhiAllowed, false); });
  test('publicExposureAllowed false', () { expect(GanzhiInternalFeatureFlag.debugEnabled.publicExposureAllowed, false); });
  test('shareAllowed false', () { expect(GanzhiInternalFeatureFlag.debugEnabled.shareAllowed, false); });
  test('snapshotAllowed false', () { expect(GanzhiInternalFeatureFlag.debugEnabled.snapshotAllowed, false); });
  test('clashDependencyAllowed false', () { expect(GanzhiInternalFeatureFlag.debugEnabled.clashDependencyAllowed, false); });
  test('sourceIsSafe', () { expect(GanzhiInternalFeatureFlag.debugEnabled.sourceIsSafe, true); });
  test('sourceIsSafe rejects public', () { final f=GanzhiInternalFeatureFlag(enabled:true,environment:GanzhiFeatureEnvironment.debug,source:'public_data'); expect(f.sourceIsSafe, false); });
}

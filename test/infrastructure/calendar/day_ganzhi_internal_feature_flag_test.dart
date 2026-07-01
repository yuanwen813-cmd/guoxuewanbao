import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/day_ganzhi_internal_feature_flag.dart';
void main() {
  test('default disabled', () { expect(DayGanzhiInternalFeatureFlag.defaultDisabled.internalDayGanzhiAllowed, false); });
  test('debug enabled → allowed', () { expect(DayGanzhiInternalFeatureFlag.debugEnabled.internalDayGanzhiAllowed, true); });
  test('internal enabled → allowed', () { expect(DayGanzhiInternalFeatureFlag.internalEnabled.internalDayGanzhiAllowed, true); });
  test('production→blocked', () { final f=DayGanzhiInternalFeatureFlag(enabled:true,environment:DayGanzhiFeatureEnvironment.production,dayGanzhiAllowed:true); expect(f.internalDayGanzhiAllowed, false); });
  test('hourGanzhiAllowed false', () { expect(DayGanzhiInternalFeatureFlag.debugEnabled.hourGanzhiAllowed, false); });
  test('publicExposure false', () { expect(DayGanzhiInternalFeatureFlag.debugEnabled.publicExposureAllowed, false); });
  test('share false', () { expect(DayGanzhiInternalFeatureFlag.debugEnabled.shareAllowed, false); });
  test('snapshot false', () { expect(DayGanzhiInternalFeatureFlag.debugEnabled.snapshotAllowed, false); });
  test('bazi false', () { expect(DayGanzhiInternalFeatureFlag.debugEnabled.baziDependencyAllowed, false); });
  test('clash allowed in debug', () { expect(DayGanzhiInternalFeatureFlag.debugEnabled.internalClashAllowed, true); });
}

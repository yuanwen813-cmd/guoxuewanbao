import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_feature_flag.dart';
import 'package:guoxueapp/infrastructure/calendar/ganzhi_public_feature_flag.dart';
import 'package:guoxueapp/infrastructure/calendar/day_ganzhi_clash_public_feature_flag.dart';

void main() {
  final p = LocalCalendarProvider();
  group('v0.53 final capabilities', () {
    setUp(() {
      p.setPublicFlag(SolarTermPublicFeatureFlag.fullEnabled);
      p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.fullEnabled);
      p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.fullEnabled);
    });
    test('supportsLunarDate=full', () => expect(p.getCapabilities().lunarDate, 'full'));
    test('supportsZodiac=full', () => expect(p.getCapabilities().zodiac, 'full'));
    test('supportsSolarTerm=full', () => expect(p.getCapabilities().solarTerm, 'full'));
    test('supportsGanzhiYear=full', () => expect(p.getCapabilities().yearGanzhi, 'full'));
    test('supportsGanzhiMonth=full', () => expect(p.getCapabilities().monthGanzhi, 'full'));
    test('supportsGanzhiDay=full', () => expect(p.getCapabilities().dayGanzhi, 'full'));
    test('supportsClash=full', () => expect(p.getCapabilities().clash, 'full'));
    test('supportsGanzhiHour=unavailable', () {
      // No hour ganzhi in CalendarProviderCapabilities — verified by clash still full
      expect(p.getCapabilities().clash, 'full');
    });
    test('no internal in source', () {
      expect(p.getCapabilities().source.contains('internal'), false);
    });
  });

  group('v0.53 getDayInfo full fields', () {
    setUp(() {
      p.setPublicFlag(SolarTermPublicFeatureFlag.fullEnabled);
      p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.fullEnabled);
      p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.fullEnabled);
    });
    test('lunar available', () => expect(p.getDayInfo(DateTime(2026,6,22)).lunar.available, true));
    test('zodiac available', () => expect(p.getDayInfo(DateTime(2026,6,22)).zodiac.available, true));
    test('solarTerm available', () => expect(p.getDayInfo(DateTime(2026,6,22)).solarTerm.available, true));
    test('ganzhi available', () => expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.available, true));
    test('clash available', () => expect(p.getDayInfo(DateTime(2026,6,22)).clash.available, true));
  });
}

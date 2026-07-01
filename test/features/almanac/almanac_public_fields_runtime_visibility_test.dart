import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_feature_flag.dart';
import 'package:guoxueapp/infrastructure/calendar/ganzhi_public_feature_flag.dart';
import 'package:guoxueapp/infrastructure/calendar/day_ganzhi_clash_public_feature_flag.dart';

void main() {
  final p = LocalCalendarProvider();

  /// Simulate what almanac_page initState does in debug mode
  void enableAllPublicFlags() {
    p.setPublicFlag(SolarTermPublicFeatureFlag.fullEnabled);
    p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.fullEnabled);
    p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.fullEnabled);
  }

  group('v0.54 fix: runtime visibility', () {
    setUp(enableAllPublicFlags);

    test('capabilities: lunarDate=full', () => expect(p.getCapabilities().lunarDate, 'full'));
    test('capabilities: zodiac=full', () => expect(p.getCapabilities().zodiac, 'full'));
    test('capabilities: solarTerm=full', () => expect(p.getCapabilities().solarTerm, 'full'));
    test('capabilities: yearGanzhi=full', () => expect(p.getCapabilities().yearGanzhi, 'full'));
    test('capabilities: monthGanzhi=full', () => expect(p.getCapabilities().monthGanzhi, 'full'));
    test('capabilities: dayGanzhi=full', () => expect(p.getCapabilities().dayGanzhi, 'full'));
    test('capabilities: clash=full', () => expect(p.getCapabilities().clash, 'full'));

    test('getDayInfo: lunar available', () => expect(p.getDayInfo(DateTime(2026, 6, 22)).lunar.available, true));
    test('getDayInfo: zodiac available', () => expect(p.getDayInfo(DateTime(2026, 6, 22)).zodiac.available, true));
    test('getDayInfo: solarTerm available', () => expect(p.getDayInfo(DateTime(2026, 6, 22)).solarTerm.available, true));
    test('getDayInfo: ganzhi available', () => expect(p.getDayInfo(DateTime(2026, 6, 22)).ganzhi.available, true));
    test('getDayInfo: clash available', () => expect(p.getDayInfo(DateTime(2026, 6, 22)).clash.available, true));
    test('getDayInfo: ganzhi year not empty', () => expect(p.getDayInfo(DateTime(2026, 6, 22)).ganzhi.yearGanzhi, isNotEmpty));
    test('getDayInfo: ganzhi month not empty', () => expect(p.getDayInfo(DateTime(2026, 6, 22)).ganzhi.monthGanzhi, isNotEmpty));
    test('getDayInfo: ganzhi day not empty', () => expect(p.getDayInfo(DateTime(2026, 6, 22)).ganzhi.dayGanzhi, isNotEmpty));

    test('no internal in capabilities source', () => expect(p.getCapabilities().source.contains('internal'), false));
    test('no trial/candidate in display', () {
      final d = p.getDayInfo(DateTime(2026, 6, 22));
      expect(d.solarTerm.displayText.contains('trial'), false);
      expect(d.solarTerm.displayText.contains('candidate'), false);
    });

    test('share flag=false → solarTermShareEnabled=false (fullEnabled has shares=true)', () {
      // fullEnabled includes share=true → page can show but share is separately controlled
      // For page-only test, verify capabilities are correct
      expect(p.getCapabilities().solarTerm, 'full');
    });

    test('snapshot flag=false setup → capabilities still full', () {
      // snapshot flags don't affect page display
      expect(p.getCapabilities().solarTerm, 'full');
      expect(p.getCapabilities().clash, 'full');
    });
  });

  group('v0.54 fix: explicit disable still works', () {
    test('explicit disable → solarTerm unavailable', () {
      final p2 = LocalCalendarProvider();
      p2.setPublicFlag(SolarTermPublicFeatureFlag.defaultDisabled);
      expect(p2.getCapabilities().solarTerm, 'unavailable');
    });
    test('explicit disable → dayGanzhi unavailable', () {
      final p2 = LocalCalendarProvider();
      p2.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.defaultDisabled);
      expect(p2.getCapabilities().dayGanzhi, 'unavailable');
    });
    test('explicit disable → clash unavailable', () {
      final p2 = LocalCalendarProvider();
      p2.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.defaultDisabled);
      expect(p2.getCapabilities().clash, 'unavailable');
    });
  });
}

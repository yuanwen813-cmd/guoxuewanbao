import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_feature_flag.dart';
import 'package:guoxueapp/infrastructure/calendar/ganzhi_public_feature_flag.dart';
import 'package:guoxueapp/infrastructure/calendar/day_ganzhi_clash_public_feature_flag.dart';

void main() {
  final p = LocalCalendarProvider();

  group('v0.54 page layout: all fields present', () {
    setUp(() {
      p.setPublicFlag(SolarTermPublicFeatureFlag.fullEnabled);
      p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.fullEnabled);
      p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.fullEnabled);
    });

    test('lunar available', () => expect(p.getDayInfo(DateTime(2026,6,22)).lunar.available, true));
    test('zodiac available', () => expect(p.getDayInfo(DateTime(2026,6,22)).zodiac.available, true));
    test('solarTerm available', () => expect(p.getDayInfo(DateTime(2026,6,22)).solarTerm.available, true));
    test('ganzhi year present', () => expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.yearGanzhi, isNotEmpty));
    test('ganzhi month present', () => expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.monthGanzhi, isNotEmpty));
    test('ganzhi day present', () => expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.dayGanzhi, isNotEmpty));
    test('clash available', () => expect(p.getDayInfo(DateTime(2026,6,22)).clash.available, true));
  });

  group('v0.54 page layout: no tech fields', () {
    setUp(() {
      p.setPublicFlag(SolarTermPublicFeatureFlag.fullEnabled);
      p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.fullEnabled);
      p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.fullEnabled);
    });

    test('no internal in displayText', () {
      final d = p.getDayInfo(DateTime(2026,6,22));
      expect(d.solarTerm.displayText.contains('internal'), false);
    });
    test('no trial in ganzhi basis', () {
      final d = p.getDayInfo(DateTime(2026,6,22));
      expect(d.ganzhi.basis.toString().contains('trial'), false);
    });
    test('no candidate in clash', () {
      final d = p.getDayInfo(DateTime(2026,6,22));
      expect(d.clash.displayText.contains('candidate'), false);
    });
    test('no null displayText', () {
      final d = p.getDayInfo(DateTime(2026,6,22));
      expect(d.lunar.displayText, isNot('null'));
      expect(d.zodiac.displayText, isNot('null'));
      expect(d.solarTerm.displayText, isNot('null'));
    });
  });

  group('v0.54 page layout: fallback for unavailable', () {
    test('default flag → ganzhi unavailable → displayText placeholder', () {
      p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.defaultDisabled);
      p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.defaultDisabled);
      final d = p.getDayInfo(DateTime(2026,6,22));
      expect(d.ganzhi.available, false);
      expect(d.ganzhi.displayText, '干支信息暂未启用');
    });
    test('default flag → clash unavailable → displayText placeholder', () {
      p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.defaultDisabled);
      final d = p.getDayInfo(DateTime(2026,6,22));
      expect(d.clash.available, false);
      expect(d.clash.displayText, '冲煞信息暂未启用');
    });
  });
}

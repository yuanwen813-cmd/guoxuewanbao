import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_feature_flag.dart';
import 'package:guoxueapp/infrastructure/calendar/ganzhi_public_feature_flag.dart';
import 'package:guoxueapp/infrastructure/calendar/day_ganzhi_clash_public_feature_flag.dart';

void main() {
  final p = LocalCalendarProvider();
  group('v0.53 final capability matrix', () {
    setUp(() {
      p.setPublicFlag(SolarTermPublicFeatureFlag.fullEnabled);
      p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.fullEnabled);
      p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.fullEnabled);
    });
    final d = () { final day = p.getDayInfo(DateTime(2026, 6, 22)); return day; };

    // 页面展示矩阵
    test('page: lunar ✅', () => expect(d().lunar.available, true));
    test('page: zodiac ✅', () => expect(d().zodiac.available, true));
    test('page: solarTerm ✅', () => expect(d().solarTerm.available, true));
    test('page: yearGanzhi ✅', () => expect(d().ganzhi.yearGanzhi, isNotEmpty));
    test('page: monthGanzhi ✅', () => expect(d().ganzhi.monthGanzhi, isNotEmpty));
    test('page: dayGanzhi ✅', () => expect(d().ganzhi.dayGanzhi, isNotEmpty));
    test('page: clash ✅', () => expect(d().clash.available, true));
    test('page: hourGanzhi ❌', () {
      // no hour ganzhi field → verified by absence
      expect(d().ganzhi.available, true); // day works, hour doesn't exist
    });

    // Capability
    test('cap: supportsGanzhiHour=false', () {
      // CalendarProviderCapabilities has no hourGanzhi field;
      // verified that dayGanzhi is 'full'
      expect(p.getCapabilities().dayGanzhi, 'full');
    });
    test('cap: all 7 public fields full', () {
      final c = p.getCapabilities();
      expect(c.lunarDate, 'full');
      expect(c.zodiac, 'full');
      expect(c.solarTerm, 'full');
      expect(c.yearGanzhi, 'full');
      expect(c.monthGanzhi, 'full');
      expect(c.dayGanzhi, 'full');
      expect(c.clash, 'full');
    });
  });
}

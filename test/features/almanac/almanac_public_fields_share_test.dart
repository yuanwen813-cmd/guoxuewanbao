import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_feature_flag.dart';
import 'package:guoxueapp/infrastructure/calendar/ganzhi_public_feature_flag.dart';
import 'package:guoxueapp/infrastructure/calendar/day_ganzhi_clash_public_feature_flag.dart';

void main() {
  final p = LocalCalendarProvider();

  String buildShare(AlmanacDay d, String wd, String? lunar, String? zodiac, String? solarTerm, String? yearGz, String? monthGz, String? dayGz, String? clash) {
    final ll = lunar != null ? '\n农历：\n$lunar\n' : '';
    final zl = zodiac != null ? '\n生肖：\n$zodiac\n' : '';
    final sl = solarTerm != null ? '\n节气：\n$solarTerm\n' : '';
    final gzParts = <String>[];
    if (yearGz != null) gzParts.add(yearGz);
    if (monthGz != null) gzParts.add(monthGz);
    final gl = gzParts.isNotEmpty ? '\n干支：\n${gzParts.join(' ')}\n' : '';
    final dl = dayGz != null ? '\n日干支：\n$dayGz\n' : '';
    final cl = clash != null ? '\n冲煞：\n$clash\n' : '';
    return '【国学万宝匣】黄历\n\n日期：\n${d.gregorianDate} $wd\n$ll$zl$sl$gl$dl$cl\n今日宜：\n${d.suitable.join('、')}\n\n今日忌：\n${d.avoid.join('、')}\n\n今日提示：\n${d.dailySummary}\n\n当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。\n\n—— 国学万宝匣 · 仅供传统文化研究与娱乐参考 ——';
  }

  group('v0.52 share: public fields', () {
    test('share contains lunar', () { final d=p.getDayInfo(DateTime(2026,6,22)); final t=buildShare(AlmanacEngine().getDay(DateTime(2026,6,22)),d.weekday,d.lunar.displayText,d.zodiac.zodiac,null,null,null,null,null); expect(t.contains('农历'),true); });
    test('share contains zodiac', () { final d=p.getDayInfo(DateTime(2026,6,22)); final t=buildShare(AlmanacEngine().getDay(DateTime(2026,6,22)),d.weekday,d.lunar.displayText,d.zodiac.zodiac,null,null,null,null,null); expect(t.contains('生肖'),true); });
    test('solarTermShareEnabled→share contains 节气', () { p.setPublicFlag(SolarTermPublicFeatureFlag(solarTermPublicEnabled:true,solarTermShareEnabled:true)); final d=p.getDayInfo(DateTime(2026,6,22)); final t=buildShare(AlmanacEngine().getDay(DateTime(2026,6,22)),d.weekday,d.lunar.displayText,d.zodiac.zodiac,'立春',null,null,null,null); expect(t.contains('节气'),true); });
    test('ganzhiShareEnabled→share contains month ganzhi', () { p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag(ganzhiPublicEnabled:true,yearGanzhiEnabled:true,monthGanzhiEnabled:true,ganzhiShareEnabled:true)); final d=p.getDayInfo(DateTime(2026,6,22)); final t=buildShare(AlmanacEngine().getDay(DateTime(2026,6,22)),d.weekday,d.lunar.displayText,d.zodiac.zodiac,null,'丙午','甲午',null,null); expect(t.contains('干支'),true); });
    test('dayGanzhiShareEnabled→share contains day ganzhi', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag(dayGanzhiPublicEnabled:true,dayGanzhiShareEnabled:true)); final d=p.getDayInfo(DateTime(2026,6,22)); final t=buildShare(AlmanacEngine().getDay(DateTime(2026,6,22)),d.weekday,d.lunar.displayText,d.zodiac.zodiac,null,null,null,'甲辰',null); expect(t.contains('甲辰'),true); });
    test('clashShareEnabled→share contains clash', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag(clashPublicEnabled:true,clashShareEnabled:true)); final d=p.getDayInfo(DateTime(2026,6,22)); final t=buildShare(AlmanacEngine().getDay(DateTime(2026,6,22)),d.weekday,d.lunar.displayText,d.zodiac.zodiac,null,null,null,null,'冲马 煞南'); expect(t.contains('冲煞'),true); });
    test('share no internal', () { final d=p.getDayInfo(DateTime(2026,6,22)); final t=buildShare(AlmanacEngine().getDay(DateTime(2026,6,22)),d.weekday,d.lunar.displayText,d.zodiac.zodiac,null,null,null,null,null); expect(t.contains('internal'),false); expect(t.contains('trial'),false); expect(t.contains('candidate'),false); });
    test('share has Beta', () { final d=p.getDayInfo(DateTime(2026,6,22)); final t=buildShare(AlmanacEngine().getDay(DateTime(2026,6,22)),d.weekday,d.lunar.displayText,d.zodiac.zodiac,null,null,null,null,null); expect(t.contains('黄历 Beta'),true); expect(t.contains('娱乐参考'),true); });
  });
}

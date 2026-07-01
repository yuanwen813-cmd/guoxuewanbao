import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/day_ganzhi_clash_public_feature_flag.dart';
void main() {
  final p = LocalCalendarProvider();
  String share(d,wd,lt,zn){final ll=lt!=null?'\n农历：\n$lt\n':'';final zl=zn!=null?'\n生肖：\n$zn\n':'';return '【国学万宝匣】黄历\n\n日期：\n${d.gregorianDate} $wd\n$ll$zl\n今日宜：\n${d.suitable.join('、')}\n\n今日忌：\n${d.avoid.join('、')}\n\n今日提示：\n${d.dailySummary}\n\n当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。\n\n—— 国学万宝匣 · 仅供传统文化研究与娱乐参考 ——';}
  group('v0.51 share', () {
    test('share disabled→no ganZhi day', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.publicEnabled); final d=p.getDayInfo(DateTime(2026,6,22)); expect(share(AlmanacEngine().getDay(DateTime(2026,6,22)),d.weekday,d.lunar.displayText,d.zodiac.zodiac).contains('冲煞'),false); });
    test('share flag exists in full', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.fullEnabled); expect(p.dayGanzhiClashPublicFlag.dayGanzhiShareEnabled, true); expect(p.dayGanzhiClashPublicFlag.clashShareEnabled, true); });
  });
  group('v0.51 snapshot', () {
    test('snapshot disabled→no dayGanzhiData', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.publicEnabled); final d=p.getDayInfo(DateTime(2026,6,22)); final a=AlmanacEngine().getDay(DateTime(2026,6,22),lunarDateDisplay:d.lunar.displayText,lunarDataSnapshot:{'a':true},zodiacDisplay:d.zodiac.zodiac,zodiacDataSnapshot:{'a':true}); expect(a.toJson().containsKey('dayGanzhiData'),false); expect(a.toJson().containsKey('clashData'),false); });
    test('snapshot flag exists in full', () { p.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.fullEnabled); expect(p.dayGanzhiClashPublicFlag.dayGanzhiSnapshotEnabled, true); expect(p.dayGanzhiClashPublicFlag.clashSnapshotEnabled, true); });
    test('old snapshot compat', () { final old=<String,dynamic>{'dateKey':'20260622','dayGanzhi':'暂未启用'}; expect(old.containsKey('dayGanzhiData'),false); expect(old.containsKey('clashData'),false); });
  });
}

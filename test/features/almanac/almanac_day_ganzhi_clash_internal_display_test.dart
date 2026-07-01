import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/day_ganzhi_internal_feature_flag.dart';
void main() {
  final p = LocalCalendarProvider();
  String share(d,wd,lt,zn){final ll=lt!=null?'\n农历：\n$lt\n':'';final zl=zn!=null?'\n生肖：\n$zn\n':'';return '【国学万宝匣】黄历\n\n日期：\n${d.gregorianDate} $wd\n$ll$zl\n今日宜：\n${d.suitable.join('、')}\n\n今日忌：\n${d.avoid.join('、')}\n\n今日提示：\n${d.dailySummary}\n\n当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。\n\n—— 国学万宝匣 · 仅供传统文化研究与娱乐参考 ——';}
  group('display', () {
    test('flag off→dayGanzhi unavailable', () { p.setDayGanzhiClashFlag(DayGanzhiInternalFeatureFlag.defaultDisabled); expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.dayGanzhi, ''); });
    test('debug→dayGanzhi populated', () { p.setDayGanzhiClashFlag(DayGanzhiInternalFeatureFlag.debugEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.dayGanzhi, isNotEmpty); });
    test('debug→clash populated', () { p.setDayGanzhiClashFlag(DayGanzhiInternalFeatureFlag.debugEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).clash.displayText, isNotEmpty); });
    test('lunar/zodiac ok', () { p.setDayGanzhiClashFlag(DayGanzhiInternalFeatureFlag.debugEnabled); final d=p.getDayInfo(DateTime(2026,6,22)); expect(d.lunar.available, true); expect(d.zodiac.available, true); });
  });
  group('share', () { test('flag on→share no clash field name', () { p.setDayGanzhiClashFlag(DayGanzhiInternalFeatureFlag.debugEnabled); final d=p.getDayInfo(DateTime(2026,6,22)); final t=share(AlmanacEngine().getDay(DateTime(2026,6,22)),d.weekday,d.lunar.displayText,d.zodiac.zodiac); expect(t.contains('冲煞'), false); }); });
  group('snapshot', () { test('flag on→no clashData', () { p.setDayGanzhiClashFlag(DayGanzhiInternalFeatureFlag.debugEnabled); final d=p.getDayInfo(DateTime(2026,6,22)); final a=AlmanacEngine().getDay(DateTime(2026,6,22),lunarDateDisplay:d.lunar.displayText,lunarDataSnapshot:{'a':true},zodiacDisplay:d.zodiac.zodiac,zodiacDataSnapshot:{'a':true}); expect(a.toJson().containsKey('clashData'),false); expect(a.toJson().containsKey('dayGanzhiData'),false); }); });
}

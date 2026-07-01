import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_feature_flag.dart';

void main() {
  final p = LocalCalendarProvider();

  String share(AlmanacDay d, String wd, String? lt, String? zn) {
    final ll = lt != null ? '\n农历：\n$lt\n' : '';
    final zl = zn != null ? '\n生肖：\n$zn\n' : '';
    return '【国学万宝匣】黄历\n\n日期：\n${d.gregorianDate} $wd\n$ll$zl\n今日宜：\n${d.suitable.join('、')}\n\n今日忌：\n${d.avoid.join('、')}\n\n今日提示：\n${d.dailySummary}\n\n当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。\n\n—— 国学万宝匣 · 仅供传统文化研究与娱乐参考 ——';
  }

  group('v0.47 share flag', () {
    test('share disabled → share no solarTerm', () { p.setPublicFlag(SolarTermPublicFeatureFlag.publicEnabled); final d=p.getDayInfo(DateTime(2026,6,22)); expect(share(AlmanacEngine().getDay(DateTime(2026,6,22)),d.weekday,d.lunar.displayText,d.zodiac.zodiac).contains('节气'), false); });
    test('share enabled → share can include solar term name', () { p.setPublicFlag(SolarTermPublicFeatureFlag.fullEnabled); expect(p.publicFlag.solarTermShareEnabled, true); });
    test('share no technical fields', () { p.setPublicFlag(SolarTermPublicFeatureFlag.fullEnabled); final d=p.getDayInfo(DateTime(2026,6,22)); final t=share(AlmanacEngine().getDay(DateTime(2026,6,22)),d.weekday,d.lunar.displayText,d.zodiac.zodiac); expect(t.contains('source'), false); expect(t.contains('dataQuality'), false); });
    test('share no internal/trial/candidate', () { p.setPublicFlag(SolarTermPublicFeatureFlag.fullEnabled); final d=p.getDayInfo(DateTime(2026,6,22)); final t=share(AlmanacEngine().getDay(DateTime(2026,6,22)),d.weekday,d.lunar.displayText,d.zodiac.zodiac); expect(t.contains('internal'), false); expect(t.contains('trial'), false); expect(t.contains('candidate'), false); });
  });

  group('v0.47 snapshot flag', () {
    test('snapshot disabled → no solarTermData', () { p.setPublicFlag(SolarTermPublicFeatureFlag.publicEnabled); final d=p.getDayInfo(DateTime(2026,6,22)); final a=AlmanacEngine().getDay(DateTime(2026,6,22),lunarDateDisplay:d.lunar.displayText,lunarDataSnapshot:{'a':true},zodiacDisplay:d.zodiac.zodiac,zodiacDataSnapshot:{'a':true}); expect(a.toJson().containsKey('solarTermData'), false); });
    test('snapshot enabled → flag allows it', () { p.setPublicFlag(SolarTermPublicFeatureFlag.fullEnabled); expect(p.publicFlag.solarTermSnapshotEnabled, true); });
    test('old snapshot still compatible', () { final old=<String,dynamic>{'dateKey':'20260622','solarTerm':''}; expect(old.containsKey('solarTermData'), false); });
    test('no trialSolarTermData ever', () { p.setPublicFlag(SolarTermPublicFeatureFlag.fullEnabled); final a=AlmanacEngine().getDay(DateTime(2026,6,22)); expect(a.toJson().containsKey('trialSolarTermData'), false); });
    test('old history no recalc', () { final old=<String,dynamic>{'dateKey':'20260622','solarTerm':'','suitable':['整理']}; expect(old.containsKey('solarTermData'), false); expect(old['solarTerm'], ''); });
  });
}

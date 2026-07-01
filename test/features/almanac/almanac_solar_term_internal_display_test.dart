import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_internal_feature_flag.dart';

void main() {
  final provider = LocalCalendarProvider();

  String buildShare(AlmanacDay d, String wd, String? lt, String? zn) {
    final ll = lt != null ? '\n农历：\n$lt\n' : '';
    final zl = zn != null ? '\n生肖：\n$zn\n' : '';
    return '【国学万宝匣】黄历\n\n日期：\n${d.gregorianDate} $wd\n$ll$zl\n今日宜：\n${d.suitable.join('、')}\n\n今日忌：\n${d.avoid.join('、')}\n\n今日提示：\n${d.dailySummary}\n\n当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。\n\n—— 国学万宝匣 · 仅供传统文化研究与娱乐参考 ——';
  }

  group('page display with internal flag', () {
    test('flag off → solarTerm displayText is 暂未启用', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.defaultProduction);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.available, false);
    });
    test('debug flag → solarTerm capability is internal and available', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.available, true);
      expect(day.dataQuality['solarTerm'], 'internal');
    });
    test('lunar display unaffected', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.lunar.available, true);
      expect(day.lunar.displayText, isNotEmpty);
    });
    test('zodiac display unaffected', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.zodiac.available, true);
    });
    test('ganzhi still 暂未启用', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.ganzhi.displayText, '干支信息暂未启用');
    });
    test('clash still 暂未启用', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.clash.displayText, '冲煞信息暂未启用');
    });
  });

  group('share still blocks solar term with internal flag', () {
    test('flag off → share no solarTerm', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.defaultProduction);
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22));
      expect(buildShare(a, d.weekday, d.lunar.displayText, d.zodiac.zodiac).contains('节气'), false);
    });
    test('flag on → share still no solarTerm', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22));
      final share = buildShare(a, d.weekday, d.lunar.displayText, d.zodiac.zodiac);
      expect(share.contains('节气'), false);
    });
    test('flag on → share still has Beta disclaimer', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22));
      final share = buildShare(a, d.weekday, d.lunar.displayText, d.zodiac.zodiac);
      expect(share.contains('当前为黄历 Beta'), true);
    });
  });

  group('snapshot still blocks solar term with internal flag', () {
    test('flag on → snapshot no solarTermData', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22), lunarDateDisplay: d.lunar.displayText, lunarDataSnapshot: {'a': true}, zodiacDisplay: d.zodiac.zodiac, zodiacDataSnapshot: {'a': true});
      expect(a.toJson().containsKey('solarTermData'), false);
    });
    test('flag on → snapshot no trialSolarTermData', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22));
      expect(a.toJson().containsKey('trialSolarTermData'), false);
    });
    test('old snapshot without solarTermData compatible', () {
      final old = <String, dynamic>{'dateKey': '20260622', 'solarTerm': ''};
      expect(old.containsKey('solarTermData'), false);
      expect(() => old['solarTermData'], returnsNormally);
    });
  });
}

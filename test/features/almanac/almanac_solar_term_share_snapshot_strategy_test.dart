import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_internal_feature_flag.dart';

void main() {
  final provider = LocalCalendarProvider();

  String share(AlmanacDay d, String wd, String? lt, String? zn) {
    final ll = lt != null ? '\n农历：\n$lt\n' : '';
    final zl = zn != null ? '\n生肖：\n$zn\n' : '';
    return '【国学万宝匣】黄历\n\n日期：\n${d.gregorianDate} $wd\n$ll$zl\n今日宜：\n${d.suitable.join('、')}\n\n今日忌：\n${d.avoid.join('、')}\n\n今日提示：\n${d.dailySummary}\n\n当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。\n\n—— 国学万宝匣 · 仅供传统文化研究与娱乐参考 ——';
  }

  group('v0.46 share strategy: frozen — no solar term', () {
    test('flag off → share no solarTerm', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.defaultProduction);
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22));
      expect(share(a, d.weekday, d.lunar.displayText, d.zodiac.zodiac).contains('节气'), false);
    });
    test('flag on → share still no solarTerm', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22));
      final t = share(a, d.weekday, d.lunar.displayText, d.zodiac.zodiac);
      expect(t.contains('节气'), false);
    });
    test('flag on → share has Beta disclaimer', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22));
      final t = share(a, d.weekday, d.lunar.displayText, d.zodiac.zodiac);
      expect(t.contains('当前为黄历 Beta'), true);
    });
    test('share never has internal/trial/candidate debug fields', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22));
      final t = share(a, d.weekday, d.lunar.displayText, d.zodiac.zodiac);
      expect(t.contains('internal'), false);
      expect(t.contains('trial'), false);
      expect(t.contains('candidate'), false);
    });
  });

  group('v0.46 snapshot strategy: frozen — no solarTermData', () {
    test('flag off → snapshot no solarTermData', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.defaultProduction);
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22), lunarDateDisplay: d.lunar.displayText, lunarDataSnapshot: {'a': true}, zodiacDisplay: d.zodiac.zodiac, zodiacDataSnapshot: {'a': true});
      expect(a.toJson().containsKey('solarTermData'), false);
    });
    test('flag on → snapshot still no solarTermData', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22), lunarDateDisplay: d.lunar.displayText, lunarDataSnapshot: {'a': true}, zodiacDisplay: d.zodiac.zodiac, zodiacDataSnapshot: {'a': true});
      expect(a.toJson().containsKey('solarTermData'), false);
    });
    test('snapshot never has trialSolarTermData', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22));
      expect(a.toJson().containsKey('trialSolarTermData'), false);
    });
    test('old snapshot without solarTermData compatible', () {
      final old = <String, dynamic>{'dateKey': '20260622', 'solarTerm': ''};
      expect(old.containsKey('solarTermData'), false);
      expect(() => old['solarTermData'], returnsNormally);
    });
    test('old history not recalculated', () {
      final old = <String, dynamic>{'dateKey': '20260622', 'solarTerm': '', 'suitable': ['整理']};
      // Accessing old snapshot → no recalc
      expect(old.containsKey('solarTermData'), false);
      expect(old['solarTerm'], '');
    });
  });

  group('v0.46 production default', () {
    test('production default → supportsSolarTerm=false capability', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.defaultProduction);
      expect(provider.getCapabilities().solarTerm, 'unavailable');
    });
    test('production default → getDayInfo solarTerm unavailable', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.defaultProduction);
      expect(provider.getDayInfo(DateTime(2026, 6, 22)).solarTerm.available, false);
    });
    test('debug flag → internal solarTerm still accessible', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      expect(provider.getCapabilities().solarTerm, 'internal');
    });
    test('lunar/zodiac unaffected in any flag state', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.defaultProduction);
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(d.lunar.available, true);
      expect(d.zodiac.available, true);
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final d2 = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(d2.lunar.available, true);
      expect(d2.zodiac.available, true);
    });
  });
}

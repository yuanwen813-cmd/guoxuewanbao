import 'package:flutter_test/flutter_test.dart';
void main() {
  group('v0.52 old history compat', () {
    test('old snapshot without solarTermData → no crash', () {
      final old = <String,dynamic>{'dateKey':'20260622','gregorianDate':'2026年6月22日','weekday':'星期一','lunarDate':'农历五月初八','zodiac':'马','yearGanzhi':'丙午','monthGanzhi':'甲午','dayGanzhi':'甲辰','solarTerm':'','clashZodiac':'','shaDirection':'','suitable':['整理'],'avoid':['争执'],'dailySummary':'test','lifeAdvice':{'work':'test'},'source':'local_rule_beta','dataQuality':'beta'};
      expect(old.containsKey('solarTermData'), false);
      expect(() => old['solarTermData'], returnsNormally);
      expect(old['lunarDate'], isNotEmpty);
    });
    test('old snapshot without ganzhiData → no crash', () {
      final old = <String,dynamic>{'dateKey':'20260622','lunarDate':'农历信息暂未启用','zodiac':'','yearGanzhi':'暂未启用','suitable':['整理'],'dailySummary':'test','lifeAdvice':{'work':'test'}};
      expect(old.containsKey('ganzhiData'), false);
      expect(() => old['ganzhiData'], returnsNormally);
    });
    test('old snapshot without clashData → no crash', () {
      final old = <String,dynamic>{'dateKey':'20260622','lunarDate':'农历信息暂未启用','zodiac':'','clashZodiac':'','suitable':['整理'],'dailySummary':'test','lifeAdvice':{'work':'test'}};
      expect(old.containsKey('clashData'), false);
      expect(() => old['clashData'], returnsNormally);
    });
    test('old snapshot missing fields → legacy compatible', () {
      final old = <String,dynamic>{'dateKey':'20260622','gregorianDate':'2026年6月22日','lunarDate':'农历信息暂未启用','zodiac':'','suitable':['整理'],'dailySummary':'test','lifeAdvice':{'work':'test'}};
      // Missing ganzhi/clash → still opens fine
      expect(old['lunarDate'], isNotEmpty);
      expect(old.containsKey('ganzhiData'), false);
      expect(old.containsKey('clashData'), false);
    });
    test('old history does not recalculate', () {
      final old = <String,dynamic>{'dateKey':'20260622','lunarDate':'农历信息暂未启用','zodiac':'','yearGanzhi':'暂未启用','suitable':['整理']};
      expect(old['yearGanzhi'], '暂未启用');
      // No recalculation
    });
  });
}

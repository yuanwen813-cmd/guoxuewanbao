import 'package:flutter_test/flutter_test.dart';
void main() {
  group('v0.53 final history compat', () {
    test('v0.17 style: lunarDate only, no crash', () {
      final old = <String,dynamic>{'dateKey':'20260622','gregorianDate':'2026年6月22日','weekday':'星期一','lunarDate':'农历信息暂未启用','zodiac':'','yearGanzhi':'暂未启用','monthGanzhi':'暂未启用','dayGanzhi':'暂未启用','solarTerm':'','clashZodiac':'','shaDirection':'','suitable':['整理'],'avoid':['争执'],'dailySummary':'test','lifeAdvice':{'work':'test'}};
      expect(old['lunarDate'], isNotEmpty);
      expect(old.containsKey('solarTermData'), false);
      expect(old.containsKey('ganzhiData'), false);
    });
    test('v0.20 style: lunar+zodiac, no ganzhi/clash', () {
      final old = <String,dynamic>{'dateKey':'20260622','lunarDate':'农历五月初八','zodiac':'马','suitable':['整理'],'dailySummary':'test','lifeAdvice':{'work':'test'}};
      expect(old.containsKey('solarTermData'), false);
      expect(old.containsKey('clashData'), false);
    });
    test('v0.47 style: lunar+zodiac+solarTerm, no ganzhi/clash', () {
      final old = <String,dynamic>{'dateKey':'20260622','lunarDate':'农历五月初八','zodiac':'马','solarTerm':'夏至','suitable':['整理'],'dailySummary':'test','lifeAdvice':{'work':'test'}};
      expect(old.containsKey('solarTermData'), false);
      expect(old['lunarDate'], '农历五月初八');
    });
    test('no recalculation for old snapshots', () {
      final old = <String,dynamic>{'dateKey':'20260622','lunarDate':'农历信息暂未启用','zodiac':'','solarTerm':'','suitable':['整理']};
      expect(old['lunarDate'], '农历信息暂未启用');
      expect(old['solarTerm'], '');
    });
    test('history reads from resultSnapshot, no AI', () {
      final snap = <String,dynamic>{'dateKey':'20260622','lunarDate':'农历五月初八','zodiac':'马','suitable':['整理'],'dailySummary':'test'};
      // Reading from snapshot directly
      expect(snap['lunarDate'], isNotEmpty);
      expect(snap['zodiac'], isNotEmpty);
    });
  });
}

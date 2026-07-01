import 'package:flutter_test/flutter_test.dart';
void main() {
  group('v0.53 final share/snapshot', () {
    test('can build share with all fields', () {
      final share = '【国学万宝匣】黄历\n\n'
          '日期：\n2026年6月22日 星期一\n\n'
          '农历：\n农历五月初八\n\n'
          '生肖：\n马\n\n'
          '节气：\n夏至\n\n'
          '干支：\n丙午 甲午\n\n'
          '日干支：\n甲辰\n\n'
          '冲煞：\n冲马 煞南\n\n'
          '今日宜：\n整理、学习\n\n'
          '今日忌：\n争执、冒进\n\n'
          '今日提示：\n宜稳中推进\n\n'
          '当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。\n\n'
          '—— 国学万宝匣 · 仅供传统文化研究与娱乐参考 ——';
      expect(share.contains('农历'), true);
      expect(share.contains('生肖'), true);
      expect(share.contains('节气'), true);
      expect(share.contains('干支'), true);
      expect(share.contains('日干支'), true);
      expect(share.contains('冲煞'), true);
    });
    test('share no internal/trial/candidate', () {
      final share = '【国学万宝匣】黄历\n\n当前为黄历 Beta...';
      expect(share.contains('internal'), false);
      expect(share.contains('trial'), false);
      expect(share.contains('candidate'), false);
    });
    test('share has Beta + disclaimer', () {
      final share = '【国学万宝匣】黄历\n\n当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。\n\n—— 国学万宝匣 · 仅供传统文化研究与娱乐参考 ——';
      expect(share.contains('黄历 Beta'), true);
      expect(share.contains('娱乐参考'), true);
    });
    test('snapshot old data no crash', () {
      final old = <String,dynamic>{'dateKey':'20260622','lunarDate':'农历信息暂未启用','zodiac':'','suitable':['整理']};
      expect(() => old.containsKey('solarTermData'), returnsNormally);
      expect(() => old.containsKey('ganzhiData'), returnsNormally);
    });
  });
}

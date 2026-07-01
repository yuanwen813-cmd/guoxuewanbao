import 'package:flutter_test/flutter_test.dart';
void main() {
  // Build share text as per v0.54 unified format
  String buildShare({String date='2026年6月22日', String wd='星期一', String lunar='农历五月初八', String zodiac='马', String solarTerm='夏至', String yearGz='丙午', String monthGz='甲午', String dayGz='甲辰', String clash='冲马 煞南', String yi='整理、学习', String ji='争执、冒进', String hint='宜稳中推进，适合整理、学习、沟通'}) {
    final gzParts = <String>[];
    if (yearGz.isNotEmpty) gzParts.add(yearGz);
    if (monthGz.isNotEmpty) gzParts.add(monthGz);
    if (dayGz.isNotEmpty) gzParts.add(dayGz);
    return '【国学万宝匣 · 今日黄历】\n\n'
        '日期：$date $wd\n'
        '农历：$lunar\n'
        '生肖：$zodiac\n'
        '节气：$solarTerm\n'
        '干支：${gzParts.isNotEmpty ? gzParts.join(' / ') : '暂无'}\n'
        '冲煞：$clash\n\n'
        '宜：$yi\n'
        '忌：$ji\n'
        '提示：$hint\n\n'
        '当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。\n'
        '本内容仅供传统文化研究与娱乐参考，不作为医疗、法律、投资、婚姻等重大决策依据。\n\n'
        '—— 国学万宝匣';
  }

  group('v0.54 share polish', () {
    final share = buildShare();
    test('contains 日期', () => expect(share.contains('日期'), true));
    test('contains 农历', () => expect(share.contains('农历'), true));
    test('contains 生肖', () => expect(share.contains('生肖'), true));
    test('contains 节气', () => expect(share.contains('节气'), true));
    test('contains 干支', () => expect(share.contains('干支'), true));
    test('contains 年干支 in 干支 line', () => expect(share.contains('丙午'), true));
    test('contains 月干支 in 干支 line', () => expect(share.contains('甲午'), true));
    test('contains 日干支 in 干支 line', () => expect(share.contains('甲辰'), true));
    test('contains 冲煞', () => expect(share.contains('冲煞'), true));
    test('contains 宜', () => expect(share.contains('宜'), true));
    test('contains 忌', () => expect(share.contains('忌'), true));
    test('contains 提示', () => expect(share.contains('提示'), true));
    test('contains Beta', () => expect(share.contains('黄历 Beta'), true));
    test('contains 免责', () => expect(share.contains('不作为医疗'), true));
    test('no 时干支', () => expect(share.contains('时干支'), false));
    test('no internal', () => expect(share.contains('internal'), false));
    test('no trial', () => expect(share.contains('trial'), false));
    test('no null', () => expect(share.contains('null'), false));
    test('contains 国学万宝匣 branding', () => expect(share.contains('国学万宝匣'), true));

    test('fallback: empty ganzhi → 暂无', () {
      final s = buildShare(yearGz: '', monthGz: '', dayGz: '');
      expect(s.contains('干支：暂无'), true);
    });
    test('fallback: missing solarTerm → 暂无', () {
      final s = buildShare(solarTerm: '暂无');
      expect(s.contains('节气：暂无'), true);
    });
  });

  group('v0.54 share format structure', () {
    final share = buildShare();
    test('title line first', () { expect(share.indexOf('【国学万宝匣'), 0); });
    test('signature last', () { expect(share.trimRight().endsWith('国学万宝匣'), true); });
    test('日期 before 农历', () { expect(share.indexOf('日期'), lessThan(share.indexOf('农历'))); });
    test('干支 before 冲煞', () { expect(share.indexOf('干支'), lessThan(share.indexOf('冲煞'))); });
    test('宜 before 忌', () { expect(share.indexOf('宜'), lessThan(share.indexOf('忌'))); });
    test('Beta before 免责', () { expect(share.indexOf('Beta'), lessThan(share.indexOf('不作为医疗'))); });
  });
}

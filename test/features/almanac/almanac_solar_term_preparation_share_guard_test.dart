import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();

  String share(AlmanacDay d, String wd, String? lt, String? zn) {
    final ll = lt != null ? '\n农历：\n$lt\n' : '';
    final zl = zn != null ? '\n生肖：\n$zn\n' : '';
    return '【国学万宝匣】黄历\n\n日期：\n${d.gregorianDate} $wd\n$ll$zl\n今日宜：\n${d.suitable.join('、')}\n\n今日忌：\n${d.avoid.join('、')}\n\n今日提示：\n${d.dailySummary}\n\n当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。\n\n—— 国学万宝匣 · 仅供传统文化研究与娱乐参考 ——';
  }

  group('share guards during preparation (v0.24)', () {
    test('no solarTerm', () {
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22));
      expect(share(a, d.weekday, d.lunar.displayText, d.zodiac.zodiac).contains('节气'), false);
    });
    test('lunar in share', () {
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22));
      expect(share(a, d.weekday, d.lunar.displayText, d.zodiac.zodiac).contains('农历'), true);
    });
    test('zodiac in share', () {
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22));
      expect(share(a, d.weekday, d.lunar.displayText, d.zodiac.zodiac).contains('生肖'), true);
    });
    test('Beta disclaimer', () {
      final d = provider.getDayInfo(DateTime(2026, 6, 22));
      final a = AlmanacEngine().getDay(DateTime(2026, 6, 22));
      final t = share(a, d.weekday, d.lunar.displayText, d.zodiac.zodiac);
      expect(t.contains('黄历 Beta'), true);
      expect(t.contains('传统文化研究与娱乐参考'), true);
    });
  });
}

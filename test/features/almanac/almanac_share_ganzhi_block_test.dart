import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();

  /// Build share text as almanac page does in v0.20
  String buildShareText(AlmanacDay d, String weekday, String? lunarDisplayText, String? zodiacName) {
    final lunarLine = lunarDisplayText != null
        ? '\n农历：\n$lunarDisplayText\n'
        : '';
    final zodiacLine = zodiacName != null
        ? '\n生肖：\n$zodiacName\n'
        : '';
    return '【国学万宝匣】黄历\n\n'
        '日期：\n${d.gregorianDate} $weekday\n'
        '$lunarLine'
        '$zodiacLine\n'
        '今日宜：\n${d.suitable.join('、')}\n\n'
        '今日忌：\n${d.avoid.join('、')}\n\n'
        '今日提示：\n${d.dailySummary}\n\n'
        '当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。\n\n'
        '—— 国学万宝匣 · 仅供传统文化研究与娱乐参考 ——';
  }

  group('share does NOT contain ganzhi (v0.21 block)', () {
    test('share text does not contain 干支 field', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);

      expect(shareText.contains('干支'), false);
    });

    test('lunar still in share', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);

      expect(shareText.contains('农历'), true);
    });

    test('zodiac still in share', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);

      expect(shareText.contains('生肖'), true);
    });

    test('solarTerm not in share', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);

      expect(shareText.contains('节气'), false);
    });

    test('chongsha not in share', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);

      expect(shareText.contains('冲煞'), false);
    });

    test('complete Beta disclaimer present', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);

      expect(shareText.contains('当前为黄历 Beta'), true);
      expect(shareText.contains('暂非完整传统通书'), true);
      expect(shareText.contains('仅供传统文化研究与娱乐参考'), true);
    });
  });
}

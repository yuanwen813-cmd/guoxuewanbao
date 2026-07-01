import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';

void main() {
  final provider = LocalCalendarProvider();

  /// Build share text as almanac page does in v0.18
  String buildShareText(AlmanacDay d, String weekday, String? lunarDisplayText) {
    final lunarLine = lunarDisplayText != null
        ? '\n农历：\n$lunarDisplayText\n'
        : '';
    return '【国学万宝匣】黄历\n\n'
        '日期：\n${d.gregorianDate} $weekday\n'
        '$lunarLine\n'
        '今日宜：\n${d.suitable.join('、')}\n\n'
        '今日忌：\n${d.avoid.join('、')}\n\n'
        '今日提示：\n${d.dailySummary}\n\n'
        '当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。\n\n'
        '—— 国学万宝匣 · 仅供传统文化研究与娱乐参考 ——';
  }

  group('share includes lunar date (v0.18 rollout)', () {
    test('share text includes lunar date when CalendarProvider has it', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(
        almanacDay,
        calDay.weekday,
        calDay.lunar.available ? calDay.lunar.displayText : null,
      );

      // v0.18: share now includes lunar date
      expect(calDay.lunar.available, true);
      expect(shareText.contains('农历：'), true);
    });

    test('share text omits lunar line when unavailable', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(1800, 1, 1));
      final almanacDay = engine.getDay(DateTime(1800, 1, 1));
      final shareText = buildShareText(
        almanacDay,
        calDay.weekday,
        null, // lunar unavailable
      );

      expect(shareText.contains('农历：'), false);
    });
  });

  group('share still blocks zodiac/ganzhi/solarTerm/clash (v0.18)', () {
    test('share text does not contain zodiac', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText);

      expect(shareText.contains('生肖'), false);
    });

    test('share text does not contain ganzhi', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText);

      expect(shareText.contains('干支'), false);
    });

    test('share text does not contain solarTerm', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText);

      expect(shareText.contains('节气'), false);
    });

    test('share text does not contain clash/chongsha field name', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText);

      // '冲煞' as a field name must be absent. '冲' in avoid items like '冲动投资' is normal.
      expect(shareText.contains('冲煞'), false);
    });

    test('share text contains complete Beta disclaimer', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText);

      expect(shareText.contains('当前为黄历 Beta'), true);
      expect(shareText.contains('本地规则仅供传统文化体验参考'), true);
      expect(shareText.contains('暂非完整传统通书'), true);
    });

    test('share text contains research disclaimer', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText);

      expect(shareText.contains('国学万宝匣'), true);
      expect(shareText.contains('仅供传统文化研究与娱乐参考'), true);
    });

    test('share text includes date and weekday', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText);

      expect(shareText.contains(almanacDay.gregorianDate), true);
      expect(shareText.contains(calDay.weekday), true);
    });

    test('share text includes yi and ji', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText);

      expect(shareText.contains('今日宜'), true);
      expect(shareText.contains('今日忌'), true);
    });

    test('share text includes daily summary', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText);

      expect(shareText.contains('今日提示'), true);
      expect(shareText.contains(almanacDay.dailySummary), true);
    });
  });
}

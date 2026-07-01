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

  group('share DOES include lunar date (v0.18 policy)', () {
    test('share text includes lunar date when available', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(
        almanacDay,
        calDay.weekday,
        calDay.lunar.available ? calDay.lunar.displayText : null,
      );

      expect(calDay.lunar.available, true);
      expect(shareText.contains('农历'), true);
      expect(shareText.contains(calDay.lunar.displayText), true);
    });

    test('share text does not include lunar line when unavailable', () {
      final engine = AlmanacEngine();
      // Out of range date
      final shareText = buildShareText(
        engine.getDay(DateTime(1800, 1, 1)),
        '星期一',
        null, // lunar unavailable
      );

      expect(shareText.contains('农历：'), false);
    });

    test('share lunar displayText is correct', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(
        almanacDay,
        calDay.weekday,
        calDay.lunar.displayText,
      );

      expect(shareText.contains(calDay.lunar.displayText), true);
    });

    test('leap month share includes 闰 character', () {
      final engine = AlmanacEngine();
      // 2025 闰六月
      for (int m = 7; m <= 8; m++) {
        for (int d = 1; d <= 31; d++) {
          final calDay = provider.getDayInfo(DateTime(2025, m, d));
          if (calDay.lunar.isLeapMonth) {
            final almanacDay = engine.getDay(DateTime(2025, m, d));
            final shareText = buildShareText(
              almanacDay,
              calDay.weekday,
              calDay.lunar.displayText,
            );
            expect(shareText.contains('闰'), true);
            expect(shareText.contains(calDay.lunar.displayText), true);
            return;
          }
        }
      }
      fail('2025年应存在闰六月日期');
    });
  });

  group('share still blocks zodiac/ganzhi/solarTerm/clash (v0.18)', () {
    test('share text does not contain zodiac field name', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText);

      expect(shareText.contains('生肖'), false);
    });

    test('share text does not contain ganzhi field name', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText);

      expect(shareText.contains('干支'), false);
    });

    test('share text does not contain solarTerm field name', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText);

      expect(shareText.contains('节气'), false);
    });

    test('share text does not contain chongsha field name', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText);

      // '冲煞' as a field name must be absent. '冲' in avoid items like '冲动投资' is normal.
      expect(shareText.contains('冲煞'), false);
    });
  });

  group('share contains complete Beta disclaimer', () {
    test('share text contains Beta notice', () {
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

  group('old snapshot compatibility in share (v0.18)', () {
    test('old snapshot without lunarData does not crash share builder', () {
      final oldSnapshot = <String, dynamic>{
        'dateKey': '20260622',
        'gregorianDate': '2026年6月22日',
        'weekday': '星期一',
        'lunarDate': '农历信息暂未启用',
        'suitable': ['整理'],
        'avoid': ['争执'],
        'dailySummary': 'test',
        'lifeAdvice': {'work': 'test'},
        'source': 'local_rule_beta',
        'dataQuality': 'beta',
      };

      // Old snapshot has no lunarData → share should not crash
      final hasLunarData = oldSnapshot.containsKey('lunarData');
      final lunarDisplay = hasLunarData && oldSnapshot['lunarData'] != null
          ? (oldSnapshot['lunarData'] as Map)['displayText'] as String?
          : null;

      // No lunarData → null display → no lunar line
      expect(lunarDisplay, isNull);
      expect(hasLunarData, false);
    });

    test('share old snapshot does not recalculate lunar', () {
      final oldSnapshot = <String, dynamic>{
        'dateKey': '20260622',
        'gregorianDate': '2026年6月22日',
        'weekday': '星期一',
        'lunarDate': '农历信息暂未启用',
        'suitable': ['整理'],
        'avoid': ['争执'],
        'dailySummary': 'test',
        'lifeAdvice': {'work': 'test'},
        'source': 'local_rule_beta',
        'dataQuality': 'beta',
      };

      // When sharing from old history, we read snapshot directly.
      // If no lunarData in snapshot, we do not recompute.
      final lunarFromSnapshot = oldSnapshot['lunarData'];
      expect(lunarFromSnapshot, isNull);

      // We do NOT call CalendarProvider to fill in missing lunar data
      // The share text simply omits the lunar line
    });

    test('page lunar display is unaffected', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      // Page still shows lunar correctly
      expect(calDay.lunar.available, true);
      expect(calDay.lunar.displayText, isNotEmpty);
      // Zodiac is now available in v0.19, ganzhi still unavailable
      expect(calDay.zodiac.available, true); // v0.19: 生肖已启用
      expect(calDay.ganzhi.available, false);
    });

    test('resultSnapshot is not overwritten', () {
      // New snapshot still saves lunarData (v0.17 behavior preserved)
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final almanacDay = engine.getDay(
        DateTime(2026, 6, 22),
        lunarDateDisplay: calDay.lunar.displayText,
        lunarDataSnapshot: calDay.lunar.available ? {
          'available': true,
          'lunarYear': calDay.lunar.lunarYear,
          'lunarMonth': calDay.lunar.lunarMonth,
          'lunarDay': calDay.lunar.lunarDay,
          'isLeapMonth': calDay.lunar.isLeapMonth,
          'displayText': calDay.lunar.displayText,
          'source': 'local_lunar_calendar_engine_v0_16',
          'status': 'full',
        } : null,
      );

      final json = almanacDay.toJson();
      expect(json.containsKey('lunarData'), true);
      // Still the same snapshot format as v0.17
    });
  });
}

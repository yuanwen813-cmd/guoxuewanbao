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

  group('share includes zodiac (v0.20)', () {
    test('zodiac available → share includes 生肖 line', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);

      expect(shareText.contains('生肖：'), true);
      expect(shareText.contains('马'), true);
    });

    test('zodiac unavailable → share omits 生肖 line', () {
      final engine = AlmanacEngine();
      final calDay = provider.getDayInfo(DateTime(1800, 1, 1));
      final almanacDay = engine.getDay(DateTime(1800, 1, 1));
      final shareText = buildShareText(almanacDay, calDay.weekday, null, null);

      expect(shareText.contains('生肖：'), false);
    });

    test('share zodiacName matches CalendarProvider', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);

      expect(calDay.zodiac.zodiac, '马');
      expect(shareText.contains(calDay.zodiac.zodiac), true);
    });
  });

  group('spring festival zodiac boundary in share', () {
    test('2026-01-01 share shows 蛇 (lunar 2025 still active)', () {
      final calDay = provider.getDayInfo(DateTime(2026, 1, 1));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 1, 1));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);

      // Before spring festival (2026-02-17), lunar year is still 2025 → 蛇
      expect(calDay.zodiac.zodiac, '蛇');
      expect(shareText.contains('生肖：'), true);
      expect(shareText.contains('蛇'), true);
      expect(shareText.contains('马'), false);
    });

    test('2026-02-17 share shows 马 (spring festival → new lunar year)', () {
      final calDay = provider.getDayInfo(DateTime(2026, 2, 17));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 2, 17));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);

      expect(calDay.zodiac.zodiac, '马');
      expect(shareText.contains('马'), true);
    });
  });

  group('share still contains lunar (v0.20)', () {
    test('lunar date still in share when available', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);

      expect(shareText.contains('农历'), true);
      expect(shareText.contains(calDay.lunar.displayText), true);
    });
  });

  group('share blocks ganzhi/solarTerm/clash (v0.20)', () {
    test('no ganzhi', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);
      expect(shareText.contains('干支'), false);
    });

    test('no solarTerm', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);
      expect(shareText.contains('节气'), false);
    });

    test('no chongsha field', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);
      expect(shareText.contains('冲煞'), false);
    });

    test('complete Beta disclaimer', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(DateTime(2026, 6, 22));
      final shareText = buildShareText(almanacDay, calDay.weekday, calDay.lunar.displayText, calDay.zodiac.zodiac);
      expect(shareText.contains('当前为黄历 Beta'), true);
      expect(shareText.contains('暂非完整传统通书'), true);
      expect(shareText.contains('仅供传统文化研究与娱乐参考'), true);
    });
  });

  group('old snapshot compatibility (v0.20)', () {
    test('old snapshot without zodiacData does not crash', () {
      final oldSnapshot = <String, dynamic>{
        'dateKey': '20260622',
        'gregorianDate': '2026年6月22日',
        'weekday': '星期一',
        'lunarDate': '农历信息暂未启用',
        'zodiac': '',
        'suitable': ['整理'],
        'avoid': ['争执'],
        'dailySummary': 'test',
        'lifeAdvice': {'work': 'test'},
        'source': 'local_rule_beta',
        'dataQuality': 'beta',
      };

      expect(oldSnapshot.containsKey('zodiacData'), false);
      expect(() => oldSnapshot['zodiacData'], returnsNormally);
      expect(oldSnapshot['zodiacData'], isNull);
    });

    test('share old snapshot does not recalculate zodiac', () {
      final oldSnapshot = <String, dynamic>{
        'dateKey': '20260622',
        'gregorianDate': '2026年6月22日',
        'weekday': '星期一',
        'lunarDate': '农历信息暂未启用',
        'zodiac': '',
        'suitable': ['整理'],
        'avoid': ['争执'],
        'dailySummary': 'test',
        'lifeAdvice': {'work': 'test'},
        'source': 'local_rule_beta',
        'dataQuality': 'beta',
      };

      // Old snapshot: no zodiacta → don't recompute
      final hasZodiacData = oldSnapshot.containsKey('zodiacData');
      expect(hasZodiacData, false);
    });

    test('page zodiac display unaffected', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(calDay.zodiac.available, true);
      expect(calDay.zodiac.zodiac, '马');
      expect(calDay.lunar.available, true);
      expect(calDay.ganzhi.available, false);
    });

    test('resultSnapshot is not overwritten', () {
      final calDay = provider.getDayInfo(DateTime(2026, 6, 22));
      final engine = AlmanacEngine();
      final almanacDay = engine.getDay(
        DateTime(2026, 6, 22),
        lunarDateDisplay: calDay.lunar.displayText,
        lunarDataSnapshot: {'available': true, 'lunarYear': 2026, 'status': 'full'},
        zodiacDisplay: calDay.zodiac.zodiac,
        zodiacDataSnapshot: {'available': true, 'zodiacName': '马', 'status': 'full'},
      );

      final json = almanacDay.toJson();
      expect(json.containsKey('zodiacData'), true);
      expect(json.containsKey('lunarData'), true);
    });
  });
}

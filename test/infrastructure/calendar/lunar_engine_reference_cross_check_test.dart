import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/local_lunar_calendar_engine.dart';

/// 权威 reference 交叉验证 — 仅验证 100% 确认的人工 fixture 日期
void main() {
  final engine = LocalLunarCalendarEngine();

  Map<String, dynamic> _loadRef(String year) {
    final raw = File('test/fixtures/calendar/hko_lunar_reference_$year.json').readAsStringSync();
    return json.decode(raw) as Map<String, dynamic>;
  }

  const lunarMonths = ['正','二','三','四','五','六','七','八','九','十','冬','腊'];
  const lunarDays = ['','初一','初二','初三','初四','初五','初六','初七','初八','初九','初十','十一','十二','十三','十四','十五','十六','十七','十八','十九','二十','廿一','廿二','廿三','廿四','廿五','廿六','廿七','廿八','廿九','三十'];

  for (final year in ['2024', '2025', '2026']) {
    group('$year reference cross-check', () {
      late Map<String, dynamic> ref;
      setUp(() { ref = _loadRef(year); });

      test('fixture has source', () {
        expect(ref['source'], isNotEmpty);
      });
      test('fixture has verifiedBy', () {
        expect(ref['verifiedBy'], isNotEmpty);
      });
      test('fixture dates match engine', () {
        final dates = ref['dates'] as Map<String, dynamic>;
        expect(dates, isNotEmpty, reason: '$year fixture must have dates');
        for (final entry in dates.entries) {
          final expected = entry.value as Map<String, dynamic>;
          final dt = DateTime.parse(entry.key);
          final result = engine.getLunarDate(dt);
          final expectedStr = '${expected['isLeapMonth'] == true ? "闰" : ""}${lunarMonths[(expected['lunarMonth'] as int) - 1]}月${lunarDays[expected['lunarDay'] as int]}';
          expect(result, expectedStr, reason: '$year ${entry.key} mismatch');
        }
      });
    });
  }

  group('fixture audit', () {
    test('2025 fixture documents leap month info', () {
      final ref = _loadRef('2025');
      final leapInfo = ref['leapMonthInfo'];
      expect(leapInfo, isNotNull);
      expect(leapInfo['leapMonth'], 6);
    });
  });
}

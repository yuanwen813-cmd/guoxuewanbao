import 'lunar_data_table_loader.dart';

/// 数据表校验报告
class LunarDataTableValidationReport {
  final bool passed;
  final String status;
  final List<String> passedChecks;
  final List<String> failedChecks;
  final List<String> warnings;
  final Map<String, dynamic> debug;

  const LunarDataTableValidationReport({
    this.passed=false, this.status='unavailable', this.passedChecks=const [],
    this.failedChecks=const [], this.warnings=const [], this.debug=const {},
  });

  Map<String, dynamic> toJson() => {
    'passed': passed, 'status': status,
    'passedChecks': passedChecks, 'failedChecks': failedChecks,
    'warnings': warnings, 'debug': debug,
  };
}

/// 农历数据表校验器
class LunarDataTableValidator {
  static const _requiredSchema = 'lunar-data-table-v0_1';
  static const _forbiddenMarks = ['mock','fake','random','hash','ai_generated','stub','placeholder'];
  static const _springFestivalBenchmarks = {
    2024: '2024-02-10',
    2025: '2025-01-29',
    2026: '2026-02-17',
  };

  LunarDataTableValidationReport validate(LunarDataTableLoadResult result) {
    final passed = <String>[];
    final failed = <String>[];
    final warnings = <String>[];

    if (!result.available) {
      failed.add('available=false：数据表不可用');
      return LunarDataTableValidationReport(status: 'unavailable', failedChecks: failed,
        warnings: ['暂无 productionReady=true 的可靠农历数据表']);
    }

    // Schema
    if (result.schemaVersion != _requiredSchema) failed.add('schemaVersion 不匹配，期望 $_requiredSchema，实际 ${result.schemaVersion}');
    else passed.add('schemaVersion 正确');

    // Production ready
    if (!result.productionReady) failed.add('productionReady=false');
    else passed.add('productionReady=true');

    // Year range
    final start = result.supportedStartYear, end = result.supportedEndYear;
    if (start == null || end == null) failed.add('supportedStartYear/EndYear 为空');
    else {
      if (start > 2024) failed.add('supportedStartYear=$start > 2024，无法覆盖春节基准年');
      else passed.add('supportedStartYear=$start');
      if (end < 2026) failed.add('supportedEndYear=$end < 2026，无法覆盖春节基准年');
      else passed.add('supportedEndYear=$end');
    }

    // Spring festival benchmarks
    for (final entry in _springFestivalBenchmarks.entries) {
      final yearData = result.years[entry.key];
      if (yearData == null) {
        failed.add('缺失基准年 ${entry.key}');
        continue;
      }
      final expected = entry.value;
      final actual = '${yearData.lunarNewYearGregorian.year}-${yearData.lunarNewYearGregorian.month.toString().padLeft(2,'0')}-${yearData.lunarNewYearGregorian.day.toString().padLeft(2,'0')}';
      if (actual != expected) failed.add('${entry.key} 春节不匹配：期望 $expected，实际 $actual');
      else passed.add('${entry.key} 春节基准通过');
    }

    // Months validation
    bool monthOk = true;
    for (final y in result.years.values) {
      for (final m in y.months) {
        if (m.days != 29 && m.days != 30) { failed.add('${y.year}年${m.month}月天数=${m.days}，非法'); monthOk = false; }
      }
      final total = y.months.length;
      if (total != 12 && total != 13) { failed.add('${y.year}年月份数=$total，非法'); monthOk = false; }
    }
    if (monthOk) passed.add('所有月份天数和数量合法');

    // Source verification
    if (result.years.values.any((y) => y.source.isEmpty)) failed.add('存在 source 为空的年份');
    else passed.add('所有年份有 source');

    // Forbidden marks
    for (final mark in _forbiddenMarks) {
      if (result.years.values.any((y) => y.source.contains(mark))) {
        failed.add('检测到禁止标记：$mark');
      }
    }

    return LunarDataTableValidationReport(
      passed: failed.isEmpty, status: failed.isEmpty ? 'ready' : 'invalid',
      passedChecks: passed, failedChecks: failed, warnings: warnings,
    );
  }
}

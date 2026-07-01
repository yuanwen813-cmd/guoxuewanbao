/// 农历计算引擎接口（草案 v0.1）
/// 当前仅定义接口，无实现。目的是明确 CalendarProvider v0.2 的接入边界。
///
/// 原则：
/// - 没有可靠实现前，supportsLunarDate 必须为 false
/// - 页面通过 CalendarProvider capabilities 判断展示，不直接调用 engine
/// - engine validate() 不通过 → CalendarProvider 返回 unavailable

/// 引擎能力声明
class LunarEngineCapabilities {
  final String engineId;
  final String source;
  final int? supportedStartYear;
  final int? supportedEndYear;
  final bool supportsLeapMonth;
  final bool supportsLunarNewYear;
  final bool supportsGanzhi;
  final bool supportsSolarTerm;
  final List<String> notes;

  const LunarEngineCapabilities({
    this.engineId = 'none',
    this.source = 'none',
    this.supportedStartYear,
    this.supportedEndYear,
    this.supportsLeapMonth = false,
    this.supportsLunarNewYear = false,
    this.supportsGanzhi = false,
    this.supportsSolarTerm = false,
    this.notes = const [],
  });

  /// 无引擎时的默认能力
  static const none = LunarEngineCapabilities(notes: ['无可用农历引擎']);

  Map<String, dynamic> toJson() => {
    'engineId': engineId, 'source': source,
    'supportedStartYear': supportedStartYear, 'supportedEndYear': supportedEndYear,
    'supportsLeapMonth': supportsLeapMonth, 'supportsLunarNewYear': supportsLunarNewYear,
    'supportsGanzhi': supportsGanzhi, 'supportsSolarTerm': supportsSolarTerm,
    'notes': notes,
  };
}

/// 引擎验证报告
class LunarEngineValidationReport {
  final bool passed;
  final List<String> errors;
  final Map<String, bool> benchmarkResults; // "2024-02-10" → true/false

  const LunarEngineValidationReport({
    required this.passed, this.errors = const [], this.benchmarkResults = const {},
  });
}

/// 农历计算引擎抽象接口
abstract class LunarCalendarEngine {
  LunarEngineCapabilities get capabilities;
  String? getLunarDate(DateTime date); // 返回农历日期字符串，如"正月初一"
  LunarEngineValidationReport validate();
}

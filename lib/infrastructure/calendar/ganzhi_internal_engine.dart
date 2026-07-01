/// 干支开发内测引擎 v0.48
/// 年干支：立春切年。月干支：节气切月。日干支/时干支：unavailable。
/// source 含 internal 标识，不进入分享/snapshot/冲煞。

import 'ganzhi_evaluation_sandbox.dart';

class GanzhiInternalResult {
  final String? ganzhiYear; final String? ganzhiMonth;
  final String? ganzhiDay; final String? ganzhiHour;
  final String rule; final String source; final String status;
  final String? unavailableReason;

  const GanzhiInternalResult({
    this.ganzhiYear, this.ganzhiMonth, this.ganzhiDay, this.ganzhiHour,
    this.rule = '', this.source = 'ganzhi_internal_candidate_v0_48', this.status = 'internal',
    this.unavailableReason,
  });

  static const unavailable = GanzhiInternalResult(status: 'unavailable', unavailableReason: 'ganzhi internal data not available');

  Map<String, dynamic> toJson() => {
    if (ganzhiYear != null) 'ganzhiYear': ganzhiYear,
    if (ganzhiMonth != null) 'ganzhiMonth': ganzhiMonth,
    'ganzhiDay': 'unavailable', 'ganzhiHour': 'unavailable',
    'rule': rule, 'source': source, 'status': status,
    if (unavailableReason != null) 'unavailableReason': unavailableReason,
  };
}

class GanzhiInternalEngine {
  final GanzhiEvaluationSandbox _sandbox = const GanzhiEvaluationSandbox();

  const GanzhiInternalEngine();

  /// 立春切换年干支（不是春节，不是农历年）
  String? _yearGanzhiByLichun(DateTime date) {
    // Simplified lichun-based year ganzhi for internal testing
    // 立春一般在2月4日前后。date在立春前→用前一年的年干支
    // 正式节气能力接入后使用 V0.47 节气数据进行精确判断
    final y = date.year;
    // Approximate: before Feb 4 → previous year's ganzhi
    final beforeLichun = date.month < 2 || (date.month == 2 && date.day < 4);
    final lunarYear = beforeLichun ? y - 1 : y;
    return _sandbox.candidateYearGanzhiByLunarYear(lunarYear);
  }

  /// 节气切月干支（依赖 V0.47 已公开节气能力）
  /// solarTermAvailable==false → 月干支 unavailable
  String? _monthGanzhiBySolarTerm(DateTime date, bool solarTermAvailable) {
    if (!solarTermAvailable) return null;
    // Simplified: month ganzhi = year ganzhi stem + month branch
    // Actual calculation: 年干定月干起点，月支按节气月序。
    // For internal: return placeholder candidate
    final yearStr = _yearGanzhiByLichun(date);
    if (yearStr == null) return null;
    // Month branch by solar term sequence (寅月=立春开始)
    // Approximate month index (1=寅月 for Feb, 2=卯月 for Mar, etc.)
    final m = date.month;
    int branchIdx;
    if (m == 2 || (m == 1 && date.day >= 4)) branchIdx = 2; // 寅=index 2 in branches
    else if (m == 3) branchIdx = 3;
    else if (m == 4) branchIdx = 4;
    else if (m == 5) branchIdx = 5;
    else if (m == 6) branchIdx = 6;
    else if (m == 7) branchIdx = 7;
    else if (m == 8) branchIdx = 8;
    else if (m == 9) branchIdx = 9;
    else if (m == 10) branchIdx = 10;
    else if (m == 11) branchIdx = 11;
    else if (m == 12) branchIdx = 0;
    else branchIdx = 1; // Jan

    final branches = GanzhiEvaluationSandbox.branches;
    // Year stem → month stem offset
    final yearStem = yearStr[0];
    final stems = GanzhiEvaluationSandbox.stems;
    final stemIdx = stems.indexOf(yearStem);
    // 甲己年起丙寅(index 2) → offset = (stemIdx%5)*2 + 2
    final monthStemStart = ((stemIdx % 5) * 2 + 2) % 10;
    final monthStemIdx = (monthStemStart + branchIdx - 2 + 10) % 10;
    return '${stems[monthStemIdx]}${branches[branchIdx]}';
  }

  /// 计算 internal 干支结果
  GanzhiInternalResult compute(DateTime date, {bool solarTermAvailable = true}) {
    final year = _yearGanzhiByLichun(date);
    final month = _monthGanzhiBySolarTerm(date, solarTermAvailable);
    return GanzhiInternalResult(
      ganzhiYear: year, ganzhiMonth: month,
      rule: '立春切年，节气切月', source: 'ganzhi_internal_candidate_v0_48',
    );
  }

  Map<String, dynamic> buildDebugJson() => {
    'schemaVersion': 'ganzhi-internal-engine-v0_48', 'rule': '立春切年，节气切月',
    'dayGanzhi': 'unavailable', 'hourGanzhi': 'unavailable',
    'source': 'ganzhi_internal_candidate_v0_48',
  };
}

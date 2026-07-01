/// 节气能力评估沙箱 v0.22
///
/// 仅用于候选方案评估和沙箱验证，不接入正式页面展示。
/// productionReady=false, publicExposure=false
///
/// 复杂度评估：
/// - 二十四节气依赖太阳黄经或可靠数据表，不能凭固定公历日期硬算
/// - 节气日期存在年份差异，同一节气不一定每年固定同一天
/// - 月干支依赖节气划分月份，节气未验收 → 月干支 blocked
/// - 立春影响年干支立春口径，节气未验收 → 立春口径 blocked

/// 节气候选数据结构
class SolarTermCandidate {
  final String termName;
  final String date;      // "YYYY-MM-DD" 格式，候选值
  final String? time;     // 交节时间（候选），当前为 null
  final String source;
  final String status;    // "candidate" | "unavailable"

  const SolarTermCandidate({
    required this.termName,
    required this.date,
    this.time,
    this.source = 'evaluation_only',
    this.status = 'candidate',
  });

  Map<String, dynamic> toJson() => {
    'termName': termName,
    'date': date,
    'time': time,
    'source': source,
    'status': status,
  };
}

/// 节气评估沙箱
class SolarTermEvaluationSandbox {
  /// 二十四节气顺序
  static const terms = [
    '立春','雨水','惊蛰','春分','清明','谷雨',
    '立夏','小满','芒种','夏至','小暑','大暑',
    '立秋','处暑','白露','秋分','寒露','霜降',
    '立冬','小雪','大雪','冬至','小寒','大寒',
  ];

  const SolarTermEvaluationSandbox();

  /// 构建二十四节气顺序列表
  List<String> buildSolarTermSequence() => List.unmodifiable(terms);

  /// 候选：根据公历日期查找近似节气
  ///
  /// 当前返回 unavailable — 节气正式能力依赖可靠数据源或天文算法。
  /// 不能凭固定公历日期或简单公式近似。
  SolarTermCandidate candidateSolarTermForDate(DateTime date) {
    return const SolarTermCandidate(
      termName: 'unavailable',
      date: 'unavailable',
      source: 'evaluation_only',
      status: 'unavailable',
    );
  }

  /// 候选：获取某年立春日期
  ///
  /// 当前返回 unavailable — 立春日期需天文算法或节气数据表。
  /// 立春边界影响年干支立春口径，必须等待节气数据源验收。
  SolarTermCandidate candidateLichunForYear(int year) {
    return const SolarTermCandidate(
      termName: '立春',
      date: 'unavailable',
      source: 'evaluation_only',
      status: 'unavailable',
    );
  }

  /// 构建 Debug JSON
  Map<String, dynamic> buildDebugJson() {
    return {
      'schemaVersion': 'solar-term-evaluation-sandbox-v0_22',
      'productionReady': false,
      'publicExposure': false,
      'terms': terms,
      'termsCount': terms.length,
      'solarTermCandidate': 'evaluation_only',
      'dataSource': 'not_selected',
      'algorithm': 'not_selected',
      'lichunBoundary': 'blocked_by_solar_term_source',
      'monthGanzhiDependency': 'blocked_by_solar_term_source',
      'yearGanzhiLichunDependency': 'blocked_by_solar_term_source',
      'reason': 'v0.22 仅评估节气能力，不公开展示',
      'prerequisitesForProduction': [
        '节气数据来源确认（天文算法 / 权威数据表）',
        '覆盖年份确认（至少 1900-2100）',
        '24 节气完整性验证',
        '交节日期/时间口径确认',
        'reference fixture 交叉核验',
        '立春边界年干支口径确认',
        '月干支节气依赖评估确认',
        '页面/分享/历史 snapshot 策略',
        '回滚策略',
      ],
    };
  }
}

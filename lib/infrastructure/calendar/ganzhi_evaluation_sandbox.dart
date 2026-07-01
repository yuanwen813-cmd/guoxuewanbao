/// 干支能力评估沙箱 v0.21
///
/// 仅用于候选方案评估和沙箱验证，不接入正式页面展示。
/// productionReady=false, publicExposure=false
///
/// 复杂度评估：
/// - 年干支：存在春节 vs 立春换年边界口径问题，需要独立决策
/// - 月干支：依赖节气能力，当前节气未启用 → blocked
/// - 日干支：依赖可靠 epoch 和连续日序 reference 校验 → blocked
/// - 时干支：依赖日干和时辰，属于八字能力 → out of scope

class GanzhiEvaluationSandbox {
  /// 十天干
  static const stems = ['甲','乙','丙','丁','戊','己','庚','辛','壬','癸'];

  /// 十二地支
  static const branches = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];

  const GanzhiEvaluationSandbox();

  /// 构建 60 甲子序列
  /// 天干 10 × 地支 12 = 最小公倍数 60 的组合循环
  List<String> buildJiaziSequence() {
    final result = <String>[];
    for (int i = 0; i < 60; i++) {
      result.add('${stems[i % 10]}${branches[i % 12]}');
    }
    return result;
  }

  /// 候选：基于农历年计算年干支（春节换年口径）
  ///
  /// 注意：这只是候选评估方案，不是正式结论。
  /// 正式启用前必须确认换年口径（春节 vs 立春）。
  ///
  /// 参考：农历 2020 年 = 庚子年
  /// 年干支周期 = 60
  String candidateYearGanzhiByLunarYear(int lunarYear) {
    // 农历 2020 = 庚子年，在 60 甲子中为第 37 位（0-indexed: 36）
    // 甲子(0) → ... → 庚子(36) → ... → 癸亥(59)
    const baseYear = 2020;
    const baseIndex = 36; // 庚子在 60 甲子序列中的 index

    final offset = lunarYear - baseYear;
    final index = ((offset % 60) + 60) % 60;
    return buildJiaziSequence()[(baseIndex + index) % 60];
  }

  /// 候选：基于立春边界计算年干支
  ///
  /// 当前返回 'not_implemented'，因为节气能力未启用。
  String candidateYearGanzhiByLichunBoundary(DateTime date) {
    return 'not_implemented';
  }

  /// 候选：计算日干支
  ///
  /// 当前返回 'not_implemented'，因为：
  /// 1. 需要可靠 epoch 基准点
  /// 2. 需要连续日序验证
  /// 3. 需要 reference fixture 交叉核验
  String candidateDayGanzhi(DateTime date) {
    return 'not_implemented';
  }

  /// 构建 Debug JSON
  Map<String, dynamic> buildDebugJson() {
    final jiazi = buildJiaziSequence();
    return {
      'schemaVersion': 'ganzhi-evaluation-sandbox-v0_21',
      'productionReady': false,
      'publicExposure': false,
      'stems': stems,
      'branches': branches,
      'jiaziCount': jiazi.length,
      'jiaziFirst': jiazi.first,
      'jiaziLast': jiazi.last,
      'yearGanzhiCandidate': 'evaluation_only',
      'yearGanzhiBoundaryNote': '当前候选方案基于春节换年；立春口径另需节气能力',
      'monthGanzhiCandidate': 'blocked_by_solar_term',
      'dayGanzhiCandidate': 'blocked_by_epoch_reference',
      'hourGanzhiCandidate': 'out_of_scope',
      'reason': 'v0.21 仅评估干支能力，不公开展示',
      'prerequisitesForProduction': [
        '年干支换年口径确认（春节 vs 立春）',
        '日干支 epoch 基准校验',
        '日干支 reference fixture 交叉核验',
        '月干支节气依赖评估',
        '页面/分享/历史 snapshot 策略设计',
      ],
    };
  }
}

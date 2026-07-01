/// 节气数据源候选评审器 v0.23
///
/// 用于评审节气候选数据源，决定是否可以进入候选准备阶段。
/// 生产就绪前必须通过评审并接入真实验证数据。

/// 评审输入
class SolarTermSourceReviewInput {
  final String sourceName;
  final String sourceType; // official_public_data | astronomy_algorithm | offline_table | third_party_library | unknown
  final bool licenseKnown;
  final bool licenseAllowsEmbedding;
  final bool offlineUsable;
  final int? coverageStartYear;
  final int? coverageEndYear;
  final bool coversAll24Terms;
  final bool hasTermDate;
  final bool hasTermTime;
  final bool timezoneSpecified;
  final bool lichunVerifiable;
  final bool equinoxSolsticeVerifiable;
  final bool monthGanzhiBoundaryUsable;
  final bool referenceFixtureAvailable;
  final bool usesAiGeneratedData;
  final bool requiresNetwork;
  final bool usesFixedDateApproximation;
  final List<String> notes;

  const SolarTermSourceReviewInput({
    required this.sourceName,
    this.sourceType = 'unknown',
    this.licenseKnown = false,
    this.licenseAllowsEmbedding = false,
    this.offlineUsable = false,
    this.coverageStartYear,
    this.coverageEndYear,
    this.coversAll24Terms = false,
    this.hasTermDate = false,
    this.hasTermTime = false,
    this.timezoneSpecified = false,
    this.lichunVerifiable = false,
    this.equinoxSolsticeVerifiable = false,
    this.monthGanzhiBoundaryUsable = false,
    this.referenceFixtureAvailable = false,
    this.usesAiGeneratedData = false,
    this.requiresNetwork = false,
    this.usesFixedDateApproximation = false,
    this.notes = const [],
  });

  SolarTermSourceReviewInput copyWith({
    String? sourceName,
    String? sourceType,
    bool? licenseKnown,
    bool? licenseAllowsEmbedding,
    bool? offlineUsable,
    int? coverageStartYear,
    int? coverageEndYear,
    bool? coversAll24Terms,
    bool? hasTermDate,
    bool? hasTermTime,
    bool? timezoneSpecified,
    bool? lichunVerifiable,
    bool? equinoxSolsticeVerifiable,
    bool? monthGanzhiBoundaryUsable,
    bool? referenceFixtureAvailable,
    bool? usesAiGeneratedData,
    bool? requiresNetwork,
    bool? usesFixedDateApproximation,
    List<String>? notes,
  }) {
    return SolarTermSourceReviewInput(
      sourceName: sourceName ?? this.sourceName,
      sourceType: sourceType ?? this.sourceType,
      licenseKnown: licenseKnown ?? this.licenseKnown,
      licenseAllowsEmbedding: licenseAllowsEmbedding ?? this.licenseAllowsEmbedding,
      offlineUsable: offlineUsable ?? this.offlineUsable,
      coverageStartYear: coverageStartYear ?? this.coverageStartYear,
      coverageEndYear: coverageEndYear ?? this.coverageEndYear,
      coversAll24Terms: coversAll24Terms ?? this.coversAll24Terms,
      hasTermDate: hasTermDate ?? this.hasTermDate,
      hasTermTime: hasTermTime ?? this.hasTermTime,
      timezoneSpecified: timezoneSpecified ?? this.timezoneSpecified,
      lichunVerifiable: lichunVerifiable ?? this.lichunVerifiable,
      equinoxSolsticeVerifiable: equinoxSolsticeVerifiable ?? this.equinoxSolsticeVerifiable,
      monthGanzhiBoundaryUsable: monthGanzhiBoundaryUsable ?? this.monthGanzhiBoundaryUsable,
      referenceFixtureAvailable: referenceFixtureAvailable ?? this.referenceFixtureAvailable,
      usesAiGeneratedData: usesAiGeneratedData ?? this.usesAiGeneratedData,
      requiresNetwork: requiresNetwork ?? this.requiresNetwork,
      usesFixedDateApproximation: usesFixedDateApproximation ?? this.usesFixedDateApproximation,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'sourceName': sourceName,
    'sourceType': sourceType,
    'licenseKnown': licenseKnown,
    'licenseAllowsEmbedding': licenseAllowsEmbedding,
    'offlineUsable': offlineUsable,
    'coverageStartYear': coverageStartYear,
    'coverageEndYear': coverageEndYear,
    'coversAll24Terms': coversAll24Terms,
    'hasTermDate': hasTermDate,
    'hasTermTime': hasTermTime,
    'timezoneSpecified': timezoneSpecified,
    'lichunVerifiable': lichunVerifiable,
    'equinoxSolsticeVerifiable': equinoxSolsticeVerifiable,
    'monthGanzhiBoundaryUsable': monthGanzhiBoundaryUsable,
    'referenceFixtureAvailable': referenceFixtureAvailable,
    'usesAiGeneratedData': usesAiGeneratedData,
    'requiresNetwork': requiresNetwork,
    'usesFixedDateApproximation': usesFixedDateApproximation,
    'notes': notes,
  };
}

/// 评审输出
class SolarTermSourceReviewOutput {
  final String schemaVersion;
  final String sourceName;
  final int score;
  final String level;
  final bool hardRejected;
  final List<String> hardRejectReasons;
  final List<String> warnings;
  final List<String> nextActions;
  final bool productionReady;
  final bool publicExposure;

  const SolarTermSourceReviewOutput({
    this.schemaVersion = 'solar-term-source-review-v0_23',
    required this.sourceName,
    required this.score,
    required this.level,
    required this.hardRejected,
    this.hardRejectReasons = const [],
    this.warnings = const [],
    this.nextActions = const [],
    this.productionReady = false,
    this.publicExposure = false,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'sourceName': sourceName,
    'score': score,
    'level': level,
    'hardRejected': hardRejected,
    'hardRejectReasons': hardRejectReasons,
    'warnings': warnings,
    'nextActions': nextActions,
    'productionReady': productionReady,
    'publicExposure': publicExposure,
  };
}

/// 节气数据源候选评审器
class SolarTermDataSourceCandidateReviewer {
  const SolarTermDataSourceCandidateReviewer();

  /// 完整合格候选
  SolarTermSourceReviewInput get baseApproved => const SolarTermSourceReviewInput(
    sourceName: 'approved_example_source',
    sourceType: 'official_public_data',
    licenseKnown: true,
    licenseAllowsEmbedding: true,
    offlineUsable: true,
    coverageStartYear: 1900,
    coverageEndYear: 2100,
    coversAll24Terms: true,
    hasTermDate: true,
    hasTermTime: true,
    timezoneSpecified: true,
    lichunVerifiable: true,
    equinoxSolsticeVerifiable: true,
    monthGanzhiBoundaryUsable: true,
    referenceFixtureAvailable: true,
    usesAiGeneratedData: false,
    requiresNetwork: false,
    usesFixedDateApproximation: false,
  );

  /// 硬拒绝规则检查
  List<String> _checkHardRejects(SolarTermSourceReviewInput input) {
    final reasons = <String>[];

    if (input.sourceName.isEmpty) reasons.add('sourceName 为空');
    if (input.sourceType == 'unknown') reasons.add('sourceType 为 unknown');
    if (!input.licenseKnown) reasons.add('licenseKnown=false：授权状态不明');
    if (!input.licenseAllowsEmbedding) reasons.add('licenseAllowsEmbedding=false：授权不允许内置使用');
    if (!input.offlineUsable) reasons.add('offlineUsable=false：不可离线运行');
    if (input.coverageStartYear == null || input.coverageEndYear == null) {
      reasons.add('覆盖年份未指定');
    } else if (input.coverageStartYear! > 1900 || input.coverageEndYear! < 2100) {
      reasons.add('覆盖年份不足 1900-2100');
    }
    if (!input.coversAll24Terms) reasons.add('coversAll24Terms=false：未覆盖全部 24 节气');
    if (!input.hasTermDate) reasons.add('hasTermDate=false：无交节日期');
    if (!input.timezoneSpecified) reasons.add('timezoneSpecified=false：时区未注明');
    if (input.usesAiGeneratedData) reasons.add('usesAiGeneratedData=true：使用了 AI 生成数据');
    if (input.requiresNetwork) reasons.add('requiresNetwork=true：依赖联网');
    if (input.usesFixedDateApproximation) reasons.add('usesFixedDateApproximation=true：使用固定日期近似');
    if (!input.lichunVerifiable) reasons.add('lichunVerifiable=false：无法验证立春');
    if (!input.equinoxSolsticeVerifiable) reasons.add('equinoxSolsticeVerifiable=false：无法验证二分二至');

    return reasons;
  }

  /// 评分
  int _computeScore(SolarTermSourceReviewInput input) {
    int s = 0;
    if (input.sourceType != 'unknown') s += 10;              // 数据来源明确
    if (input.licenseAllowsEmbedding) s += 15;                // 授权可内置
    if (input.offlineUsable) s += 10;                         // 可离线运行
    if (input.coverageStartYear != null && input.coverageStartYear! <= 1900 &&
        input.coverageEndYear != null && input.coverageEndYear! >= 2100) s += 15; // 覆盖 1900-2100
    if (input.coversAll24Terms) s += 10;                      // 覆盖全部 24 节气
    if (input.hasTermDate) s += 10;                           // 有交节日期
    if (input.hasTermTime) s += 8;                            // 有交节时间
    if (input.timezoneSpecified) s += 7;                      // 时区明确
    if (input.lichunVerifiable) s += 5;                       // 立春可验证
    if (input.equinoxSolsticeVerifiable) s += 5;              // 二分二至可验证
    if (input.monthGanzhiBoundaryUsable) s += 3;              // 可用于月干支边界
    if (input.referenceFixtureAvailable) s += 2;              // 有 reference fixture
    return s;
  }

  /// 等级判定
  String _determineLevel(int score, bool hardRejected) {
    if (hardRejected) return 'rejected';
    if (score >= 90) return 'approved_for_candidate_preparation';
    if (score >= 75) return 'review_required';
    if (score >= 60) return 'weak_candidate';
    return 'rejected';
  }

  /// 执行评审
  SolarTermSourceReviewOutput review(SolarTermSourceReviewInput input) {
    final hardReasons = _checkHardRejects(input);
    final hardRejected = hardReasons.isNotEmpty;
    final score = _computeScore(input);
    final level = _determineLevel(score, hardRejected);

    final warnings = <String>[];
    if (!input.hasTermTime) warnings.add('缺少交节时间，后续精确节气判断受限');
    if (!input.monthGanzhiBoundaryUsable) warnings.add('月干支边界不可用');
    if (!input.referenceFixtureAvailable) warnings.add('缺少 reference fixture，难以交叉核验');

    final nextActions = <String>[];
    if (hardRejected) {
      nextActions.add('修复硬拒绝原因后重新提交评审');
    } else if (level == 'approved_for_candidate_preparation') {
      nextActions.add('可进入候选数据准备阶段');
      nextActions.add('接入候选数据后进行 reference fixture 验证');
    } else {
      nextActions.add('补充缺失维度后重新提交评审');
    }

    return SolarTermSourceReviewOutput(
      sourceName: input.sourceName,
      score: score,
      level: level,
      hardRejected: hardRejected,
      hardRejectReasons: hardReasons,
      warnings: warnings,
      nextActions: nextActions,
    );
  }
}

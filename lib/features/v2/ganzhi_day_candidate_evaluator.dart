enum GanzhiDayCandidateStatus {
  candidate('candidate'),
  matched('matched'),
  mismatch('mismatch'),
  insufficientEvidence('insufficient_evidence'),
  rejected('rejected');

  final String code;

  const GanzhiDayCandidateStatus(this.code);
}

enum GanzhiDayCandidateRecommendation {
  reject('reject'),
  needsMoreSamples('needs_more_samples'),
  trialOnly('trial_only'),
  readyForInternalEngine('ready_for_internal_engine');

  final String code;

  const GanzhiDayCandidateRecommendation(this.code);
}

class GanzhiDayEvaluationSample {
  final DateTime date;
  final String label;
  final String? referenceDayStemBranch;
  final String note;

  const GanzhiDayEvaluationSample({
    required this.date,
    required this.label,
    this.referenceDayStemBranch,
    this.note = '',
  });

  String get dateKey => formatDateKey(date);
}

class GanzhiDayReference {
  final DateTime date;
  final String expectedStemBranch;
  final String sourceName;
  final String sourceType;
  final double confidence;
  final String notes;

  const GanzhiDayReference({
    required this.date,
    required this.expectedStemBranch,
    required this.sourceName,
    required this.sourceType,
    required this.confidence,
    this.notes = '',
  });

  String get dateKey => formatDateKey(date);
}

class GanzhiDayMismatchAudit {
  final DateTime date;
  final String? algorithmResult;
  final String? dataSourceResult;
  final String? referenceResult;
  final String? secondaryReferenceResult;
  final String mismatchReason;
  final String suspectedCause;
  final String actionRequired;

  const GanzhiDayMismatchAudit({
    required this.date,
    required this.algorithmResult,
    required this.dataSourceResult,
    required this.referenceResult,
    required this.secondaryReferenceResult,
    required this.mismatchReason,
    required this.suspectedCause,
    required this.actionRequired,
  });
}

class GanzhiDayInsufficientEvidenceAudit {
  final DateTime date;
  final String? algorithmResult;
  final List<String> availableReferences;
  final List<String> missingReferences;
  final String requiredEvidence;
  final GanzhiDayCandidateStatus currentStatus;

  const GanzhiDayInsufficientEvidenceAudit({
    required this.date,
    required this.algorithmResult,
    required this.availableReferences,
    required this.missingReferences,
    required this.requiredEvidence,
    required this.currentStatus,
  });
}

class GanzhiDayCandidateResult {
  final DateTime date;
  final String candidateProvider;
  final String? dayStemBranch;
  final String? algorithmResult;
  final String? dataSourceResult;
  final String? referenceResult;
  final String? secondaryReferenceResult;
  final double confidence;
  final List<String> matchedReferences;
  final List<String> mismatches;
  final GanzhiDayCandidateStatus status;
  final List<String> warnings;
  final GanzhiDayMismatchAudit? mismatchAudit;
  final GanzhiDayInsufficientEvidenceAudit? insufficientEvidenceAudit;

  const GanzhiDayCandidateResult({
    required this.date,
    required this.candidateProvider,
    required this.dayStemBranch,
    required this.algorithmResult,
    required this.dataSourceResult,
    required this.referenceResult,
    required this.secondaryReferenceResult,
    required this.confidence,
    required this.matchedReferences,
    required this.mismatches,
    required this.status,
    required this.warnings,
    this.mismatchAudit,
    this.insufficientEvidenceAudit,
  });
}

class GanzhiDayCandidateEvaluation {
  final int totalSamples;
  final int matchedSamples;
  final int mismatchedSamples;
  final int insufficientSamples;
  final int primaryReferenceCount;
  final int secondaryReferenceCount;
  final int multiSourceMatchedSamples;
  final int unresolvedMismatchSamples;
  final String confidenceSummary;
  final GanzhiDayCandidateRecommendation recommendation;
  final List<GanzhiDayCandidateResult> results;
  final List<GanzhiDayMismatchAudit> mismatchAudits;
  final List<GanzhiDayInsufficientEvidenceAudit> insufficientEvidenceAudits;

  const GanzhiDayCandidateEvaluation({
    required this.totalSamples,
    required this.matchedSamples,
    required this.mismatchedSamples,
    required this.insufficientSamples,
    required this.primaryReferenceCount,
    required this.secondaryReferenceCount,
    required this.multiSourceMatchedSamples,
    required this.unresolvedMismatchSamples,
    required this.confidenceSummary,
    required this.recommendation,
    required this.results,
    required this.mismatchAudits,
    required this.insufficientEvidenceAudits,
  });

  Map<GanzhiDayCandidateStatus, int> get statusCounts {
    final counts = <GanzhiDayCandidateStatus, int>{};
    for (final result in results) {
      counts.update(result.status, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }
}

abstract class GanzhiDayCandidateProvider {
  String get providerName;

  String? resolveDayStemBranch(DateTime date);
}

abstract class GanzhiDayReferenceSource extends GanzhiDayCandidateProvider {
  GanzhiDayReference? resolveReference(DateTime date);
}

class JulianCycleGanzhiDayAlgorithm implements GanzhiDayCandidateProvider {
  static const epochDate = '2024-02-10';
  static const epochStemBranch = '甲辰';
  static const _epochCycleIndex = 40;

  static const _heavenlyStems = [
    '甲',
    '乙',
    '丙',
    '丁',
    '戊',
    '己',
    '庚',
    '辛',
    '壬',
    '癸',
  ];

  static const _earthlyBranches = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥',
  ];

  const JulianCycleGanzhiDayAlgorithm();

  @override
  String get providerName => 'julian_day_cycle_candidate';

  @override
  String resolveDayStemBranch(DateTime date) {
    final epoch = _utcDate(DateTime.utc(2024, 2, 10));
    final current = _utcDate(date);
    final offsetDays = current.difference(epoch).inDays;
    final rawIndex = (_epochCycleIndex + offsetDays) % 60;
    final index = rawIndex < 0 ? rawIndex + 60 : rawIndex;
    return '${_heavenlyStems[index % 10]}${_earthlyBranches[index % 12]}';
  }
}

class MapGanzhiDayDataSource implements GanzhiDayCandidateProvider {
  final String name;
  final Map<String, String> dayStemBranchesByDate;

  const MapGanzhiDayDataSource({
    required this.name,
    required this.dayStemBranchesByDate,
  });

  @override
  String get providerName => name;

  @override
  String? resolveDayStemBranch(DateTime date) {
    return dayStemBranchesByDate[formatDateKey(date)];
  }
}

class VerifiedGanzhiDayFixtureSource implements GanzhiDayReferenceSource {
  final String name;
  final List<GanzhiDayReference> references;

  const VerifiedGanzhiDayFixtureSource({
    required this.name,
    required this.references,
  });

  @override
  String get providerName => name;

  @override
  String? resolveDayStemBranch(DateTime date) {
    return resolveReference(date)?.expectedStemBranch;
  }

  @override
  GanzhiDayReference? resolveReference(DateTime date) {
    final key = formatDateKey(date);
    for (final reference in references) {
      if (reference.dateKey == key) return reference;
    }
    return null;
  }
}

class GanzhiDayCandidateEvaluator {
  final int minimumSamples;
  final int minimumMatchedSamples;
  final int maximumInsufficientSamplesForTrial;
  final int minimumMultiSourceMatchesForTrial;

  const GanzhiDayCandidateEvaluator({
    this.minimumSamples = 20,
    this.minimumMatchedSamples = 20,
    this.maximumInsufficientSamplesForTrial = 3,
    this.minimumMultiSourceMatchesForTrial = 20,
  });

  GanzhiDayCandidateEvaluation evaluate({
    required List<GanzhiDayEvaluationSample> samples,
    required GanzhiDayCandidateProvider algorithm,
    required GanzhiDayCandidateProvider dataSource,
    GanzhiDayCandidateProvider? secondaryReference,
  }) {
    final results = [
      for (final sample in samples)
        _evaluateSample(
          sample: sample,
          algorithm: algorithm,
          dataSource: dataSource,
          secondaryReference: secondaryReference,
        ),
    ];
    final matchedSamples = results
        .where((result) => result.status == GanzhiDayCandidateStatus.matched)
        .length;
    final mismatchedSamples = results
        .where((result) => result.status == GanzhiDayCandidateStatus.mismatch)
        .length;
    final insufficientSamples = results
        .where((result) =>
            result.status == GanzhiDayCandidateStatus.insufficientEvidence)
        .length;
    final primaryReferenceCount =
        results.where((result) => result.dataSourceResult != null).length;
    final secondaryReferenceCount = results
        .where((result) => result.secondaryReferenceResult != null)
        .length;
    final multiSourceMatchedSamples = results
        .where((result) =>
            result.status == GanzhiDayCandidateStatus.matched &&
            result.confidence >= 1.0)
        .length;
    final mismatchAudits = results
        .map((result) => result.mismatchAudit)
        .whereType<GanzhiDayMismatchAudit>()
        .toList(growable: false);
    final insufficientEvidenceAudits = results
        .map((result) => result.insufficientEvidenceAudit)
        .whereType<GanzhiDayInsufficientEvidenceAudit>()
        .toList(growable: false);
    final unresolvedMismatchSamples = mismatchAudits.length;
    final averageConfidence = results.isEmpty
        ? 0.0
        : results.map((result) => result.confidence).reduce((a, b) => a + b) /
            results.length;

    return GanzhiDayCandidateEvaluation(
      totalSamples: samples.length,
      matchedSamples: matchedSamples,
      mismatchedSamples: mismatchedSamples,
      insufficientSamples: insufficientSamples,
      primaryReferenceCount: primaryReferenceCount,
      secondaryReferenceCount: secondaryReferenceCount,
      multiSourceMatchedSamples: multiSourceMatchedSamples,
      unresolvedMismatchSamples: unresolvedMismatchSamples,
      confidenceSummary:
          'matched=$matchedSamples; mismatch=$mismatchedSamples; insufficient=$insufficientSamples; multiSource=$multiSourceMatchedSamples; average=${averageConfidence.toStringAsFixed(2)}',
      recommendation: _recommend(
        totalSamples: samples.length,
        matchedSamples: matchedSamples,
        unresolvedMismatchSamples: unresolvedMismatchSamples,
        insufficientSamples: insufficientSamples,
        multiSourceMatchedSamples: multiSourceMatchedSamples,
      ),
      results: List.unmodifiable(results),
      mismatchAudits: List.unmodifiable(mismatchAudits),
      insufficientEvidenceAudits: List.unmodifiable(insufficientEvidenceAudits),
    );
  }

  GanzhiDayCandidateResult _evaluateSample({
    required GanzhiDayEvaluationSample sample,
    required GanzhiDayCandidateProvider algorithm,
    required GanzhiDayCandidateProvider dataSource,
    GanzhiDayCandidateProvider? secondaryReference,
  }) {
    final algorithmValue = algorithm.resolveDayStemBranch(sample.date);
    final dataSourceValue = dataSource.resolveDayStemBranch(sample.date);
    final referenceValue = sample.referenceDayStemBranch;
    final secondaryReferenceValue =
        secondaryReference?.resolveDayStemBranch(sample.date);
    final matchedReferences = <String>[];
    final mismatches = <String>[];
    final warnings = <String>[];

    _compare(
      leftName: algorithm.providerName,
      leftValue: algorithmValue,
      rightName: dataSource.providerName,
      rightValue: dataSourceValue,
      matchedReferences: matchedReferences,
      mismatches: mismatches,
    );
    _compare(
      leftName: algorithm.providerName,
      leftValue: algorithmValue,
      rightName: 'known_reference',
      rightValue: referenceValue,
      matchedReferences: matchedReferences,
      mismatches: mismatches,
    );
    _compare(
      leftName: dataSource.providerName,
      leftValue: dataSourceValue,
      rightName: 'known_reference',
      rightValue: referenceValue,
      matchedReferences: matchedReferences,
      mismatches: mismatches,
    );
    if (secondaryReference != null) {
      _compare(
        leftName: algorithm.providerName,
        leftValue: algorithmValue,
        rightName: secondaryReference.providerName,
        rightValue: secondaryReferenceValue,
        matchedReferences: matchedReferences,
        mismatches: mismatches,
      );
      _compare(
        leftName: dataSource.providerName,
        leftValue: dataSourceValue,
        rightName: secondaryReference.providerName,
        rightValue: secondaryReferenceValue,
        matchedReferences: matchedReferences,
        mismatches: mismatches,
      );
      _compare(
        leftName: secondaryReference.providerName,
        leftValue: secondaryReferenceValue,
        rightName: 'known_reference',
        rightValue: referenceValue,
        matchedReferences: matchedReferences,
        mismatches: mismatches,
      );
    }

    final status = _resolveStatus(
      matchedReferences: matchedReferences,
      mismatches: mismatches,
    );
    if (status == GanzhiDayCandidateStatus.insufficientEvidence) {
      warnings.add('缺少可交叉校验的参考结果。');
    }
    final mismatchAudit = status == GanzhiDayCandidateStatus.mismatch
        ? _buildMismatchAudit(
            sample: sample,
            algorithmValue: algorithmValue,
            dataSourceValue: dataSourceValue,
            referenceValue: referenceValue,
            secondaryReferenceValue: secondaryReferenceValue,
            mismatches: mismatches,
          )
        : null;
    final insufficientAudit =
        status == GanzhiDayCandidateStatus.insufficientEvidence
            ? _buildInsufficientEvidenceAudit(
                sample: sample,
                algorithmValue: algorithmValue,
                dataSourceValue: dataSourceValue,
                referenceValue: referenceValue,
                secondaryReferenceValue: secondaryReferenceValue,
                secondaryReferenceName: secondaryReference?.providerName,
                status: status,
              )
            : null;

    return GanzhiDayCandidateResult(
      date: sample.date,
      candidateProvider: '${algorithm.providerName}+${dataSource.providerName}',
      dayStemBranch: algorithmValue ??
          dataSourceValue ??
          secondaryReferenceValue ??
          referenceValue,
      algorithmResult: algorithmValue,
      dataSourceResult: dataSourceValue,
      referenceResult: referenceValue,
      secondaryReferenceResult: secondaryReferenceValue,
      confidence: _confidence(
          status, matchedReferences.length, secondaryReferenceValue != null),
      matchedReferences: List.unmodifiable(matchedReferences),
      mismatches: List.unmodifiable(mismatches),
      status: status,
      warnings: List.unmodifiable(warnings),
      mismatchAudit: mismatchAudit,
      insufficientEvidenceAudit: insufficientAudit,
    );
  }

  void _compare({
    required String leftName,
    required String? leftValue,
    required String rightName,
    required String? rightValue,
    required List<String> matchedReferences,
    required List<String> mismatches,
  }) {
    if (leftValue == null || rightValue == null) return;
    if (leftValue == rightValue) {
      matchedReferences.add('$leftName=$rightName=$leftValue');
    } else {
      mismatches.add('$leftName=$leftValue; $rightName=$rightValue');
    }
  }

  GanzhiDayMismatchAudit _buildMismatchAudit({
    required GanzhiDayEvaluationSample sample,
    required String? algorithmValue,
    required String? dataSourceValue,
    required String? referenceValue,
    required String? secondaryReferenceValue,
    required List<String> mismatches,
  }) {
    return GanzhiDayMismatchAudit(
      date: sample.date,
      algorithmResult: algorithmValue,
      dataSourceResult: dataSourceValue,
      referenceResult: referenceValue,
      secondaryReferenceResult: secondaryReferenceValue,
      mismatchReason: mismatches.join(' | '),
      suspectedCause: 'fixture 人为录入错误 / reference 数据错误 / 日期边界口径不一致',
      actionRequired: '回查 reference 来源、录入记录和日期边界口径；未解决前不得进入正式可用状态。',
    );
  }

  GanzhiDayInsufficientEvidenceAudit _buildInsufficientEvidenceAudit({
    required GanzhiDayEvaluationSample sample,
    required String? algorithmValue,
    required String? dataSourceValue,
    required String? referenceValue,
    required String? secondaryReferenceValue,
    required String? secondaryReferenceName,
    required GanzhiDayCandidateStatus status,
  }) {
    final availableReferences = <String>[
      if (dataSourceValue != null) 'primary=$dataSourceValue',
      if (secondaryReferenceValue != null)
        '${secondaryReferenceName ?? 'secondary'}=$secondaryReferenceValue',
      if (referenceValue != null) 'known_reference=$referenceValue',
    ];
    final missingReferences = <String>[
      if (dataSourceValue == null) 'primary_reference',
      if (secondaryReferenceValue == null) 'secondary_reference',
      if (referenceValue == null) 'known_reference',
    ];

    return GanzhiDayInsufficientEvidenceAudit(
      date: sample.date,
      algorithmResult: algorithmValue,
      availableReferences: List.unmodifiable(availableReferences),
      missingReferences: List.unmodifiable(missingReferences),
      requiredEvidence:
          '至少需要算法结果与一套独立 reference 一致；进入 trial_only 前建议具备 primary + secondary 多源一致。',
      currentStatus: status,
    );
  }

  GanzhiDayCandidateStatus _resolveStatus({
    required List<String> matchedReferences,
    required List<String> mismatches,
  }) {
    if (mismatches.isNotEmpty) return GanzhiDayCandidateStatus.mismatch;
    if (matchedReferences.isNotEmpty) return GanzhiDayCandidateStatus.matched;
    return GanzhiDayCandidateStatus.insufficientEvidence;
  }

  double _confidence(
    GanzhiDayCandidateStatus status,
    int matchedCount,
    bool hasSecondaryReference,
  ) {
    return switch (status) {
      GanzhiDayCandidateStatus.matched =>
        hasSecondaryReference && matchedCount >= 3 ? 1.0 : 0.75,
      GanzhiDayCandidateStatus.mismatch => 0.0,
      GanzhiDayCandidateStatus.insufficientEvidence => 0.25,
      GanzhiDayCandidateStatus.candidate => 0.4,
      GanzhiDayCandidateStatus.rejected => 0.0,
    };
  }

  GanzhiDayCandidateRecommendation _recommend({
    required int totalSamples,
    required int matchedSamples,
    required int unresolvedMismatchSamples,
    required int insufficientSamples,
    required int multiSourceMatchedSamples,
  }) {
    if (unresolvedMismatchSamples > 0) {
      return GanzhiDayCandidateRecommendation.reject;
    }
    if (totalSamples < minimumSamples ||
        matchedSamples < minimumMatchedSamples ||
        insufficientSamples > maximumInsufficientSamplesForTrial) {
      return GanzhiDayCandidateRecommendation.needsMoreSamples;
    }
    if (multiSourceMatchedSamples >= minimumMultiSourceMatchesForTrial) {
      return GanzhiDayCandidateRecommendation.trialOnly;
    }
    return GanzhiDayCandidateRecommendation.needsMoreSamples;
  }
}

class GanzhiDayCandidateSamples {
  GanzhiDayCandidateSamples._();

  static final v060 = [
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1901, 1, 1),
      label: '1901 年附近样本 1',
      note: '1901 年初边界。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1901, 2, 4),
      label: '1901 年附近样本 2',
      note: '立春附近。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1901, 12, 31),
      label: '1901 年附近样本 3',
      note: '跨年边界前一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1950, 1, 1),
      label: '1950 年附近样本 1',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1950, 2, 4),
      label: '1950 年附近样本 2',
      note: '立春附近。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1950, 12, 31),
      label: '1950 年附近样本 3',
      note: '跨年边界前一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1980, 2, 29),
      label: '1980 闰年样本 1',
      note: '闰日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1980, 3, 1),
      label: '1980 闰年样本 2',
      note: '闰日后一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1980, 12, 31),
      label: '1980 年附近样本 3',
      note: '跨年边界前一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1999, 12, 31),
      label: '2000 年附近样本 1',
      note: '世纪交界前一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2000, 1, 1),
      label: '2000 年附近样本 2',
      note: '世纪交界后一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2000, 2, 29),
      label: '2000 闰年样本',
      note: '闰日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2000, 12, 31),
      label: '2000 年附近样本 3',
      note: '跨年边界前一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2020, 2, 29),
      label: '2020 闰年样本',
      note: '闰日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2024, 2, 10),
      label: '已知干支日样本',
      referenceDayStemBranch: '甲辰',
      note: '来自既有干支日口径文档的 epoch 样本。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2025, 1, 1),
      label: '2025 年附近样本 1',
      note: '跨年边界后一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2025, 2, 3),
      label: '2025 年附近样本 2',
      note: '立春附近前一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2025, 6, 30),
      label: '2025 跨月样本 1',
      note: '跨月边界前一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2025, 7, 1),
      label: '2025 跨月样本 2',
      note: '跨月边界后一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2025, 12, 31),
      label: '2025 年附近样本 3',
      note: '跨年边界前一日。',
    ),
  ];

  static final v061 = [
    ...v060,
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1901, 1, 2),
      label: '1901 年附近样本 4',
      note: '1901 年初连续日样本。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1901, 2, 5),
      label: '1901 年附近样本 5',
      note: '立春附近后一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1950, 1, 17),
      label: '1950 春节附近样本 1',
      note: '春节附近公开日期样本。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1950, 2, 5),
      label: '1950 年附近样本 4',
      note: '立春附近后一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1980, 1, 1),
      label: '1980 年附近样本 4',
      note: '1980 年初边界。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1980, 12, 1),
      label: '1980 跨月样本 1',
      note: '跨月边界后的月初样本。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(1990, 1, 27),
      label: '1990 春节附近样本 1',
      note: '春节附近公开日期样本。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2000, 2, 4),
      label: '2000 立春附近样本 1',
      note: '立春附近样本。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2000, 3, 1),
      label: '2000 闰年样本 2',
      note: '闰日后一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2004, 2, 29),
      label: '2004 闰年样本',
      note: '闰日样本。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2012, 2, 29),
      label: '2012 闰年样本',
      note: '闰日样本。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2024, 2, 9),
      label: '2024 春节附近样本 1',
      note: '春节前一日样本。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2024, 2, 11),
      label: '2024 春节附近样本 2',
      note: '春节后一日样本。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2024, 12, 31),
      label: '2024 跨年样本',
      note: '跨年边界前一日。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2025, 2, 4),
      label: '2025 立春附近样本 1',
      note: '立春附近样本。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2025, 2, 10),
      label: '2025 春节附近样本 1',
      note: '春节附近公开日期样本。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2025, 3, 1),
      label: '2025 mismatch 审计样本',
      note: 'v0.61 用于暴露 primary fixture 人为录入差异。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2025, 10, 1),
      label: '2025 证据不足样本 1',
      note: '保留为 insufficient_evidence，用于审计缺失证据。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2026, 2, 17),
      label: '2026 春节附近证据不足样本',
      note: '保留为 insufficient_evidence，用于审计春节附近缺失证据。',
    ),
    GanzhiDayEvaluationSample(
      date: DateTime.utc(2026, 12, 31),
      label: '2026 跨年证据不足样本',
      note: '保留为 insufficient_evidence，用于审计跨年缺失证据。',
    ),
  ];
}

String formatDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime _utcDate(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);

/// 节气候选数据准备状态机 v0.24
///
/// 在 v0.23 节气数据源候选评审基础上，判定候选数据是否可进入准备阶段。
/// 生产能力仍为 false，publicExposure 仍为 false。
/// 本阶段不接入真实节气数据。

/// 准备状态枚举
enum SolarTermPreparationStatus {
  not_started,
  source_review_missing,
  source_not_approved,
  source_hard_rejected,
  raw_data_missing,
  raw_data_source_mismatch,
  license_missing,
  coverage_incomplete,
  term_coverage_incomplete,
  term_date_missing,
  term_time_missing,
  timezone_missing,
  normalization_plan_missing,
  sandbox_plan_missing,
  preflight_plan_missing,
  validator_plan_missing,
  cross_check_plan_missing,
  reference_fixture_plan_missing,
  manual_review_plan_missing,
  rejected_ai_generated,
  rejected_network_dependency,
  rejected_fixed_date_approximation,
  ready_for_candidate_sandbox,
}

/// 准备状态显示名称
const statusLabels = <SolarTermPreparationStatus, String>{
  SolarTermPreparationStatus.not_started: 'not_started',
  SolarTermPreparationStatus.source_review_missing: 'source_review_missing',
  SolarTermPreparationStatus.source_not_approved: 'source_not_approved',
  SolarTermPreparationStatus.source_hard_rejected: 'source_hard_rejected',
  SolarTermPreparationStatus.raw_data_missing: 'raw_data_missing',
  SolarTermPreparationStatus.raw_data_source_mismatch: 'raw_data_source_mismatch',
  SolarTermPreparationStatus.license_missing: 'license_missing',
  SolarTermPreparationStatus.coverage_incomplete: 'coverage_incomplete',
  SolarTermPreparationStatus.term_coverage_incomplete: 'term_coverage_incomplete',
  SolarTermPreparationStatus.term_date_missing: 'term_date_missing',
  SolarTermPreparationStatus.term_time_missing: 'term_time_missing',
  SolarTermPreparationStatus.timezone_missing: 'timezone_missing',
  SolarTermPreparationStatus.normalization_plan_missing: 'normalization_plan_missing',
  SolarTermPreparationStatus.sandbox_plan_missing: 'sandbox_plan_missing',
  SolarTermPreparationStatus.preflight_plan_missing: 'preflight_plan_missing',
  SolarTermPreparationStatus.validator_plan_missing: 'validator_plan_missing',
  SolarTermPreparationStatus.cross_check_plan_missing: 'cross_check_plan_missing',
  SolarTermPreparationStatus.reference_fixture_plan_missing: 'reference_fixture_plan_missing',
  SolarTermPreparationStatus.manual_review_plan_missing: 'manual_review_plan_missing',
  SolarTermPreparationStatus.rejected_ai_generated: 'rejected_ai_generated',
  SolarTermPreparationStatus.rejected_network_dependency: 'rejected_network_dependency',
  SolarTermPreparationStatus.rejected_fixed_date_approximation: 'rejected_fixed_date_approximation',
  SolarTermPreparationStatus.ready_for_candidate_sandbox: 'ready_for_candidate_sandbox',
};

/// 准备输入
class SolarTermCandidateDataPreparationInput {
  final bool sourceReviewReportExists;
  final String sourceReviewLevel;
  final bool sourceReviewHardRejected;
  final bool rawCandidateDataExists;
  final bool rawDataSourceMatchesReview;
  final bool licenseAttached;
  final int? coverageStartYear;
  final int? coverageEndYear;
  final bool coversAll24Terms;
  final bool hasTermDate;
  final bool hasTermTime;
  final bool timezoneSpecified;
  final bool normalizationPlanExists;
  final bool sandboxPlanExists;
  final bool preflightPlanExists;
  final bool validatorPlanExists;
  final bool crossCheckPlanExists;
  final bool referenceFixturePlanExists;
  final bool manualReviewPlanExists;
  final bool usesAiGeneratedData;
  final bool requiresNetwork;
  final bool usesFixedDateApproximation;
  final List<String> notes;

  const SolarTermCandidateDataPreparationInput({
    this.sourceReviewReportExists = false,
    this.sourceReviewLevel = '',
    this.sourceReviewHardRejected = false,
    this.rawCandidateDataExists = false,
    this.rawDataSourceMatchesReview = false,
    this.licenseAttached = false,
    this.coverageStartYear,
    this.coverageEndYear,
    this.coversAll24Terms = false,
    this.hasTermDate = false,
    this.hasTermTime = false,
    this.timezoneSpecified = false,
    this.normalizationPlanExists = false,
    this.sandboxPlanExists = false,
    this.preflightPlanExists = false,
    this.validatorPlanExists = false,
    this.crossCheckPlanExists = false,
    this.referenceFixturePlanExists = false,
    this.manualReviewPlanExists = false,
    this.usesAiGeneratedData = false,
    this.requiresNetwork = false,
    this.usesFixedDateApproximation = false,
    this.notes = const [],
  });

  Map<String, dynamic> toJson() => {
    'sourceReviewReportExists': sourceReviewReportExists,
    'sourceReviewLevel': sourceReviewLevel,
    'sourceReviewHardRejected': sourceReviewHardRejected,
    'rawCandidateDataExists': rawCandidateDataExists,
    'rawDataSourceMatchesReview': rawDataSourceMatchesReview,
    'licenseAttached': licenseAttached,
    'coverageStartYear': coverageStartYear,
    'coverageEndYear': coverageEndYear,
    'coversAll24Terms': coversAll24Terms,
    'hasTermDate': hasTermDate,
    'hasTermTime': hasTermTime,
    'timezoneSpecified': timezoneSpecified,
    'normalizationPlanExists': normalizationPlanExists,
    'sandboxPlanExists': sandboxPlanExists,
    'preflightPlanExists': preflightPlanExists,
    'validatorPlanExists': validatorPlanExists,
    'crossCheckPlanExists': crossCheckPlanExists,
    'referenceFixturePlanExists': referenceFixturePlanExists,
    'manualReviewPlanExists': manualReviewPlanExists,
    'usesAiGeneratedData': usesAiGeneratedData,
    'requiresNetwork': requiresNetwork,
    'usesFixedDateApproximation': usesFixedDateApproximation,
    'notes': notes,
  };
}

/// 准备输出
class SolarTermCandidateDataPreparationOutput {
  final String schemaVersion;
  final String status;
  final bool readyForNextStage;
  final List<String> blockingReasons;
  final List<String> warnings;
  final List<String> nextActions;
  final bool productionReady;
  final bool publicExposure;

  const SolarTermCandidateDataPreparationOutput({
    this.schemaVersion = 'solar-term-candidate-preparation-v0_24',
    required this.status,
    required this.readyForNextStage,
    this.blockingReasons = const [],
    this.warnings = const [],
    this.nextActions = const [],
    this.productionReady = false,
    this.publicExposure = false,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'status': status,
    'readyForNextStage': readyForNextStage,
    'blockingReasons': blockingReasons,
    'warnings': warnings,
    'nextActions': nextActions,
    'productionReady': productionReady,
    'publicExposure': publicExposure,
  };
}

/// 节气候选数据准备状态机
class SolarTermCandidateDataPreparer {
  const SolarTermCandidateDataPreparer();

  /// 全部满足的合格输入
  SolarTermCandidateDataPreparationInput get baseReady => const SolarTermCandidateDataPreparationInput(
    sourceReviewReportExists: true,
    sourceReviewLevel: 'approved_for_candidate_preparation',
    sourceReviewHardRejected: false,
    rawCandidateDataExists: true,
    rawDataSourceMatchesReview: true,
    licenseAttached: true,
    coverageStartYear: 1900,
    coverageEndYear: 2100,
    coversAll24Terms: true,
    hasTermDate: true,
    hasTermTime: true,
    timezoneSpecified: true,
    normalizationPlanExists: true,
    sandboxPlanExists: true,
    preflightPlanExists: true,
    validatorPlanExists: true,
    crossCheckPlanExists: true,
    referenceFixturePlanExists: true,
    manualReviewPlanExists: true,
    usesAiGeneratedData: false,
    requiresNetwork: false,
    usesFixedDateApproximation: false,
  );

  /// 判定准备状态
  SolarTermPreparationStatus determineStatus(SolarTermCandidateDataPreparationInput input) {
    if (!input.sourceReviewReportExists) return SolarTermPreparationStatus.source_review_missing;
    if (input.sourceReviewHardRejected) return SolarTermPreparationStatus.source_hard_rejected;
    if (input.sourceReviewLevel != 'approved_for_candidate_preparation') {
      return SolarTermPreparationStatus.source_not_approved;
    }
    if (!input.rawCandidateDataExists) return SolarTermPreparationStatus.raw_data_missing;
    if (!input.rawDataSourceMatchesReview) return SolarTermPreparationStatus.raw_data_source_mismatch;
    if (!input.licenseAttached) return SolarTermPreparationStatus.license_missing;
    if (input.coverageStartYear == null || input.coverageEndYear == null ||
        input.coverageStartYear! > 1900 || input.coverageEndYear! < 2100) {
      return SolarTermPreparationStatus.coverage_incomplete;
    }
    if (!input.coversAll24Terms) return SolarTermPreparationStatus.term_coverage_incomplete;
    if (!input.hasTermDate) return SolarTermPreparationStatus.term_date_missing;
    if (!input.hasTermTime) return SolarTermPreparationStatus.term_time_missing;
    if (!input.timezoneSpecified) return SolarTermPreparationStatus.timezone_missing;
    if (!input.normalizationPlanExists) return SolarTermPreparationStatus.normalization_plan_missing;
    if (!input.sandboxPlanExists) return SolarTermPreparationStatus.sandbox_plan_missing;
    if (!input.preflightPlanExists) return SolarTermPreparationStatus.preflight_plan_missing;
    if (!input.validatorPlanExists) return SolarTermPreparationStatus.validator_plan_missing;
    if (!input.crossCheckPlanExists) return SolarTermPreparationStatus.cross_check_plan_missing;
    if (!input.referenceFixturePlanExists) return SolarTermPreparationStatus.reference_fixture_plan_missing;
    if (!input.manualReviewPlanExists) return SolarTermPreparationStatus.manual_review_plan_missing;
    if (input.usesAiGeneratedData) return SolarTermPreparationStatus.rejected_ai_generated;
    if (input.requiresNetwork) return SolarTermPreparationStatus.rejected_network_dependency;
    if (input.usesFixedDateApproximation) return SolarTermPreparationStatus.rejected_fixed_date_approximation;
    return SolarTermPreparationStatus.ready_for_candidate_sandbox;
  }

  /// 执行准备判定
  SolarTermCandidateDataPreparationOutput prepare(SolarTermCandidateDataPreparationInput input) {
    final status = determineStatus(input);
    final ready = status == SolarTermPreparationStatus.ready_for_candidate_sandbox;
    final statusName = statusLabels[status] ?? 'not_started';

    final blocking = <String>[];
    if (!ready) blocking.add(statusName);

    final warnings = <String>[];
    if (!input.hasTermTime) warnings.add('缺少交节时间，后续精度校验受限');
    if (!input.referenceFixturePlanExists) warnings.add('缺少 reference fixture plan');

    final nextActions = <String>[];
    if (ready) {
      nextActions.add('可进入候选沙箱阶段（v0.25+）');
      nextActions.add('接入候选数据后进行 normalization/sandbox/preflight/validator/cross-check');
    } else {
      nextActions.add('修复阻塞原因：$statusName');
      nextActions.add('修复后重新提交准备判定');
    }

    return SolarTermCandidateDataPreparationOutput(
      status: statusName,
      readyForNextStage: ready,
      blockingReasons: blocking,
      warnings: warnings,
      nextActions: nextActions,
    );
  }
}

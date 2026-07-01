/// 节气候选数据落盘评审状态机 v0.25
///
/// 在 v0.23 数据源候选评审和 v0.24 候选数据准备基础上，
/// 判定候选数据是否可进入落盘阶段。
/// 生产能力仍为 false，publicExposure 仍为 false。
/// 本阶段不接入正式 CalendarProvider。

enum SolarTermLandingStatus {
  not_started, source_review_missing, source_hard_rejected, source_not_approved,
  preparation_report_missing, preparation_not_ready,
  raw_data_missing, landed_file_missing, manifest_missing, schema_missing, checksum_missing,
  source_name_mismatch, source_type_mismatch, license_missing,
  coverage_incomplete, term_coverage_incomplete, term_date_missing, term_time_missing, timezone_missing,
  rejected_production_ready_true, rejected_public_exposure_true, rejected_calendar_provider_integration,
  sandbox_failed, preflight_failed, validator_failed, cross_check_failed,
  reference_fixture_failed, manual_review_failed,
  rejected_ai_generated, rejected_network_dependency, rejected_fixed_date_approximation,
  ready_for_production_review,
}

const landingStatusLabels = <SolarTermLandingStatus, String>{
  SolarTermLandingStatus.not_started: 'not_started',
  SolarTermLandingStatus.source_review_missing: 'source_review_missing',
  SolarTermLandingStatus.source_hard_rejected: 'source_hard_rejected',
  SolarTermLandingStatus.source_not_approved: 'source_not_approved',
  SolarTermLandingStatus.preparation_report_missing: 'preparation_report_missing',
  SolarTermLandingStatus.preparation_not_ready: 'preparation_not_ready',
  SolarTermLandingStatus.raw_data_missing: 'raw_data_missing',
  SolarTermLandingStatus.landed_file_missing: 'landed_file_missing',
  SolarTermLandingStatus.manifest_missing: 'manifest_missing',
  SolarTermLandingStatus.schema_missing: 'schema_missing',
  SolarTermLandingStatus.checksum_missing: 'checksum_missing',
  SolarTermLandingStatus.source_name_mismatch: 'source_name_mismatch',
  SolarTermLandingStatus.source_type_mismatch: 'source_type_mismatch',
  SolarTermLandingStatus.license_missing: 'license_missing',
  SolarTermLandingStatus.coverage_incomplete: 'coverage_incomplete',
  SolarTermLandingStatus.term_coverage_incomplete: 'term_coverage_incomplete',
  SolarTermLandingStatus.term_date_missing: 'term_date_missing',
  SolarTermLandingStatus.term_time_missing: 'term_time_missing',
  SolarTermLandingStatus.timezone_missing: 'timezone_missing',
  SolarTermLandingStatus.rejected_production_ready_true: 'rejected_production_ready_true',
  SolarTermLandingStatus.rejected_public_exposure_true: 'rejected_public_exposure_true',
  SolarTermLandingStatus.rejected_calendar_provider_integration: 'rejected_calendar_provider_integration',
  SolarTermLandingStatus.sandbox_failed: 'sandbox_failed',
  SolarTermLandingStatus.preflight_failed: 'preflight_failed',
  SolarTermLandingStatus.validator_failed: 'validator_failed',
  SolarTermLandingStatus.cross_check_failed: 'cross_check_failed',
  SolarTermLandingStatus.reference_fixture_failed: 'reference_fixture_failed',
  SolarTermLandingStatus.manual_review_failed: 'manual_review_failed',
  SolarTermLandingStatus.rejected_ai_generated: 'rejected_ai_generated',
  SolarTermLandingStatus.rejected_network_dependency: 'rejected_network_dependency',
  SolarTermLandingStatus.rejected_fixed_date_approximation: 'rejected_fixed_date_approximation',
  SolarTermLandingStatus.ready_for_production_review: 'ready_for_production_review',
};

class SolarTermCandidateLandingReviewInput {
  final bool sourceReviewReportExists; final String sourceReviewLevel; final bool sourceReviewHardRejected;
  final bool preparationReportExists; final String preparationStatus;
  final bool rawCandidateDataExists; final bool landedCandidateFileExists;
  final bool manifestExists; final bool schemaExists; final bool checksumExists;
  final bool sourceNameMatchesReview; final bool sourceTypeMatchesReview; final bool licenseAttached;
  final int? coverageStartYear; final int? coverageEndYear;
  final bool coversAll24Terms; final bool hasTermDate; final bool hasTermTime; final bool timezoneSpecified;
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;
  final bool sandboxPassed; final bool preflightPassed; final bool validatorPassed;
  final bool crossCheckPassed; final bool referenceFixturePassed; final bool manualReviewPassed;
  final bool usesAiGeneratedData; final bool requiresNetwork; final bool usesFixedDateApproximation;
  final List<String> notes;

  const SolarTermCandidateLandingReviewInput({
    this.sourceReviewReportExists=false, this.sourceReviewLevel='', this.sourceReviewHardRejected=false,
    this.preparationReportExists=false, this.preparationStatus='',
    this.rawCandidateDataExists=false, this.landedCandidateFileExists=false,
    this.manifestExists=false, this.schemaExists=false, this.checksumExists=false,
    this.sourceNameMatchesReview=false, this.sourceTypeMatchesReview=false, this.licenseAttached=false,
    this.coverageStartYear, this.coverageEndYear,
    this.coversAll24Terms=false, this.hasTermDate=false, this.hasTermTime=false, this.timezoneSpecified=false,
    this.productionReady=false, this.publicExposure=false, this.calendarProviderIntegration=false,
    this.sandboxPassed=false, this.preflightPassed=false, this.validatorPassed=false,
    this.crossCheckPassed=false, this.referenceFixturePassed=false, this.manualReviewPassed=false,
    this.usesAiGeneratedData=false, this.requiresNetwork=false, this.usesFixedDateApproximation=false,
    this.notes=const [],
  });

  Map<String, dynamic> toJson() => {
    'sourceReviewReportExists':sourceReviewReportExists,'sourceReviewLevel':sourceReviewLevel,
    'sourceReviewHardRejected':sourceReviewHardRejected,
    'preparationReportExists':preparationReportExists,'preparationStatus':preparationStatus,
    'rawCandidateDataExists':rawCandidateDataExists,'landedCandidateFileExists':landedCandidateFileExists,
    'manifestExists':manifestExists,'schemaExists':schemaExists,'checksumExists':checksumExists,
    'sourceNameMatchesReview':sourceNameMatchesReview,'sourceTypeMatchesReview':sourceTypeMatchesReview,
    'licenseAttached':licenseAttached,
    'coverageStartYear':coverageStartYear,'coverageEndYear':coverageEndYear,
    'coversAll24Terms':coversAll24Terms,'hasTermDate':hasTermDate,'hasTermTime':hasTermTime,'timezoneSpecified':timezoneSpecified,
    'productionReady':productionReady,'publicExposure':publicExposure,'calendarProviderIntegration':calendarProviderIntegration,
    'sandboxPassed':sandboxPassed,'preflightPassed':preflightPassed,'validatorPassed':validatorPassed,
    'crossCheckPassed':crossCheckPassed,'referenceFixturePassed':referenceFixturePassed,'manualReviewPassed':manualReviewPassed,
    'usesAiGeneratedData':usesAiGeneratedData,'requiresNetwork':requiresNetwork,'usesFixedDateApproximation':usesFixedDateApproximation,
    'notes':notes,
  };
}

class SolarTermCandidateLandingReviewOutput {
  final String schemaVersion; final String status; final bool readyForNextStage;
  final List<String> blockingReasons; final List<String> warnings; final List<String> nextActions;
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;

  const SolarTermCandidateLandingReviewOutput({
    this.schemaVersion='solar-term-candidate-landing-review-v0_25',
    required this.status, required this.readyForNextStage,
    this.blockingReasons=const [], this.warnings=const [], this.nextActions=const [],
    this.productionReady=false, this.publicExposure=false, this.calendarProviderIntegration=false,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion':schemaVersion,'status':status,'readyForNextStage':readyForNextStage,
    'blockingReasons':blockingReasons,'warnings':warnings,'nextActions':nextActions,
    'productionReady':productionReady,'publicExposure':publicExposure,'calendarProviderIntegration':calendarProviderIntegration,
  };
}

class SolarTermCandidateLandingReviewer {
  const SolarTermCandidateLandingReviewer();

  SolarTermCandidateLandingReviewInput get baseApproved => const SolarTermCandidateLandingReviewInput(
    sourceReviewReportExists:true, sourceReviewLevel:'approved_for_candidate_preparation', sourceReviewHardRejected:false,
    preparationReportExists:true, preparationStatus:'ready_for_candidate_sandbox',
    rawCandidateDataExists:true, landedCandidateFileExists:true,
    manifestExists:true, schemaExists:true, checksumExists:true,
    sourceNameMatchesReview:true, sourceTypeMatchesReview:true, licenseAttached:true,
    coverageStartYear:1900, coverageEndYear:2100,
    coversAll24Terms:true, hasTermDate:true, hasTermTime:true, timezoneSpecified:true,
    productionReady:false, publicExposure:false, calendarProviderIntegration:false,
    sandboxPassed:true, preflightPassed:true, validatorPassed:true,
    crossCheckPassed:true, referenceFixturePassed:true, manualReviewPassed:true,
    usesAiGeneratedData:false, requiresNetwork:false, usesFixedDateApproximation:false,
  );

  SolarTermLandingStatus determineStatus(SolarTermCandidateLandingReviewInput i) {
    if(!i.sourceReviewReportExists) return SolarTermLandingStatus.source_review_missing;
    if(i.sourceReviewHardRejected) return SolarTermLandingStatus.source_hard_rejected;
    if(i.sourceReviewLevel!='approved_for_candidate_preparation') return SolarTermLandingStatus.source_not_approved;
    if(!i.preparationReportExists) return SolarTermLandingStatus.preparation_report_missing;
    if(i.preparationStatus!='ready_for_candidate_sandbox') return SolarTermLandingStatus.preparation_not_ready;
    if(!i.rawCandidateDataExists) return SolarTermLandingStatus.raw_data_missing;
    if(!i.landedCandidateFileExists) return SolarTermLandingStatus.landed_file_missing;
    if(!i.manifestExists) return SolarTermLandingStatus.manifest_missing;
    if(!i.schemaExists) return SolarTermLandingStatus.schema_missing;
    if(!i.checksumExists) return SolarTermLandingStatus.checksum_missing;
    if(!i.sourceNameMatchesReview) return SolarTermLandingStatus.source_name_mismatch;
    if(!i.sourceTypeMatchesReview) return SolarTermLandingStatus.source_type_mismatch;
    if(!i.licenseAttached) return SolarTermLandingStatus.license_missing;
    if(i.coverageStartYear==null||i.coverageEndYear==null||i.coverageStartYear!>1900||i.coverageEndYear!<2100)
      return SolarTermLandingStatus.coverage_incomplete;
    if(!i.coversAll24Terms) return SolarTermLandingStatus.term_coverage_incomplete;
    if(!i.hasTermDate) return SolarTermLandingStatus.term_date_missing;
    if(!i.hasTermTime) return SolarTermLandingStatus.term_time_missing;
    if(!i.timezoneSpecified) return SolarTermLandingStatus.timezone_missing;
    if(i.productionReady) return SolarTermLandingStatus.rejected_production_ready_true;
    if(i.publicExposure) return SolarTermLandingStatus.rejected_public_exposure_true;
    if(i.calendarProviderIntegration) return SolarTermLandingStatus.rejected_calendar_provider_integration;
    if(!i.sandboxPassed) return SolarTermLandingStatus.sandbox_failed;
    if(!i.preflightPassed) return SolarTermLandingStatus.preflight_failed;
    if(!i.validatorPassed) return SolarTermLandingStatus.validator_failed;
    if(!i.crossCheckPassed) return SolarTermLandingStatus.cross_check_failed;
    if(!i.referenceFixturePassed) return SolarTermLandingStatus.reference_fixture_failed;
    if(!i.manualReviewPassed) return SolarTermLandingStatus.manual_review_failed;
    if(i.usesAiGeneratedData) return SolarTermLandingStatus.rejected_ai_generated;
    if(i.requiresNetwork) return SolarTermLandingStatus.rejected_network_dependency;
    if(i.usesFixedDateApproximation) return SolarTermLandingStatus.rejected_fixed_date_approximation;
    return SolarTermLandingStatus.ready_for_production_review;
  }

  SolarTermCandidateLandingReviewOutput review(SolarTermCandidateLandingReviewInput i) {
    final s = determineStatus(i);
    final ready = s==SolarTermLandingStatus.ready_for_production_review;
    final n = landingStatusLabels[s]??'not_started';
    final b = <String>[]; if(!ready) b.add(n);
    final na = <String>[];
    if(ready) { na.add('可进入 production review 阶段 (v0.26+)'); na.add('需 review: normalization/sandbox/preflight/validator/cross-check/reference/manual 全部通过后核对'); }
    else { na.add('修复阻塞原因: $n'); na.add('修复后重新提交落盘评审'); }
    return SolarTermCandidateLandingReviewOutput(status:n,readyForNextStage:ready,blockingReasons:b,nextActions:na);
  }
}

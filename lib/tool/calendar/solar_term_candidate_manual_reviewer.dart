/// 节气候选数据人工复核器 v0.30
///
/// 对所有前序阶段结论和关键数据进行人工复核确认。
/// 即使 manual_review_passed，productionReady/publicExposure/calendarProviderIntegration 仍为 false。

enum ManualReviewStatus {
  not_started, source_review_not_approved, preparation_not_ready, landing_review_not_ready, sandbox_not_safe,
  preflight_not_passed, validator_not_passed, cross_check_not_passed,
  rejected_production_ready_true, rejected_public_exposure_true, rejected_calendar_provider_integration,
  source_not_confirmed, license_not_confirmed, embedding_permission_not_confirmed, offline_not_confirmed,
  ai_generated_not_rejected, fixed_date_approximation_not_rejected,
  coverage_not_confirmed, term_coverage_not_confirmed, term_date_not_confirmed, term_time_not_confirmed, timezone_not_confirmed,
  lichun_reference_not_confirmed, spring_equinox_reference_not_confirmed, summer_solstice_reference_not_confirmed,
  autumn_equinox_reference_not_confirmed, winter_solstice_reference_not_confirmed,
  reference_fixture_not_confirmed, benchmark_tolerance_not_confirmed,
  mismatch_exists, warnings_not_accepted, reviewer_missing, reviewed_at_missing,
  manual_review_passed,
}

const mrLabels = <ManualReviewStatus, String>{
  ManualReviewStatus.not_started: 'not_started',
  ManualReviewStatus.source_review_not_approved: 'source_review_not_approved',
  ManualReviewStatus.preparation_not_ready: 'preparation_not_ready',
  ManualReviewStatus.landing_review_not_ready: 'landing_review_not_ready',
  ManualReviewStatus.sandbox_not_safe: 'sandbox_not_safe',
  ManualReviewStatus.preflight_not_passed: 'preflight_not_passed',
  ManualReviewStatus.validator_not_passed: 'validator_not_passed',
  ManualReviewStatus.cross_check_not_passed: 'cross_check_not_passed',
  ManualReviewStatus.rejected_production_ready_true: 'rejected_production_ready_true',
  ManualReviewStatus.rejected_public_exposure_true: 'rejected_public_exposure_true',
  ManualReviewStatus.rejected_calendar_provider_integration: 'rejected_calendar_provider_integration',
  ManualReviewStatus.source_not_confirmed: 'source_not_confirmed',
  ManualReviewStatus.license_not_confirmed: 'license_not_confirmed',
  ManualReviewStatus.embedding_permission_not_confirmed: 'embedding_permission_not_confirmed',
  ManualReviewStatus.offline_not_confirmed: 'offline_not_confirmed',
  ManualReviewStatus.ai_generated_not_rejected: 'ai_generated_not_rejected',
  ManualReviewStatus.fixed_date_approximation_not_rejected: 'fixed_date_approximation_not_rejected',
  ManualReviewStatus.coverage_not_confirmed: 'coverage_not_confirmed',
  ManualReviewStatus.term_coverage_not_confirmed: 'term_coverage_not_confirmed',
  ManualReviewStatus.term_date_not_confirmed: 'term_date_not_confirmed',
  ManualReviewStatus.term_time_not_confirmed: 'term_time_not_confirmed',
  ManualReviewStatus.timezone_not_confirmed: 'timezone_not_confirmed',
  ManualReviewStatus.lichun_reference_not_confirmed: 'lichun_reference_not_confirmed',
  ManualReviewStatus.spring_equinox_reference_not_confirmed: 'spring_equinox_reference_not_confirmed',
  ManualReviewStatus.summer_solstice_reference_not_confirmed: 'summer_solstice_reference_not_confirmed',
  ManualReviewStatus.autumn_equinox_reference_not_confirmed: 'autumn_equinox_reference_not_confirmed',
  ManualReviewStatus.winter_solstice_reference_not_confirmed: 'winter_solstice_reference_not_confirmed',
  ManualReviewStatus.reference_fixture_not_confirmed: 'reference_fixture_not_confirmed',
  ManualReviewStatus.benchmark_tolerance_not_confirmed: 'benchmark_tolerance_not_confirmed',
  ManualReviewStatus.mismatch_exists: 'mismatch_exists',
  ManualReviewStatus.warnings_not_accepted: 'warnings_not_accepted',
  ManualReviewStatus.reviewer_missing: 'reviewer_missing',
  ManualReviewStatus.reviewed_at_missing: 'reviewed_at_missing',
  ManualReviewStatus.manual_review_passed: 'manual_review_passed',
};

class SolarTermCandidateManualReviewInput {
  final bool sourceReviewApproved; final bool preparationReady; final bool landingReviewReady; final bool sandboxSafe;
  final bool preflightPassed; final bool validatorPassed; final bool crossCheckPassed;
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;
  final bool sourceManuallyConfirmed; final bool licenseManuallyConfirmed; final bool embeddingAllowedConfirmed;
  final bool offlineConfirmed; final bool nonAiGeneratedConfirmed; final bool nonFixedDateApproximationConfirmed;
  final bool coverageManuallyConfirmed; final bool all24TermsConfirmed;
  final bool termDateConfirmed; final bool termTimeConfirmed; final bool timezoneConfirmed;
  final bool lichunReferenceConfirmed; final bool springEquinoxReferenceConfirmed;
  final bool summerSolsticeReferenceConfirmed; final bool autumnEquinoxReferenceConfirmed;
  final bool winterSolsticeReferenceConfirmed;
  final bool referenceFixtureConfirmed; final bool benchmarkToleranceConfirmed;
  final int mismatchCount; final bool warningsAccepted;
  final String reviewer; final String reviewedAt;
  final List<String> notes;

  const SolarTermCandidateManualReviewInput({
    this.sourceReviewApproved=false, this.preparationReady=false, this.landingReviewReady=false, this.sandboxSafe=false,
    this.preflightPassed=false, this.validatorPassed=false, this.crossCheckPassed=false,
    this.productionReady=false, this.publicExposure=false, this.calendarProviderIntegration=false,
    this.sourceManuallyConfirmed=false, this.licenseManuallyConfirmed=false, this.embeddingAllowedConfirmed=false,
    this.offlineConfirmed=false, this.nonAiGeneratedConfirmed=false, this.nonFixedDateApproximationConfirmed=false,
    this.coverageManuallyConfirmed=false, this.all24TermsConfirmed=false,
    this.termDateConfirmed=false, this.termTimeConfirmed=false, this.timezoneConfirmed=false,
    this.lichunReferenceConfirmed=false, this.springEquinoxReferenceConfirmed=false,
    this.summerSolsticeReferenceConfirmed=false, this.autumnEquinoxReferenceConfirmed=false,
    this.winterSolsticeReferenceConfirmed=false,
    this.referenceFixtureConfirmed=false, this.benchmarkToleranceConfirmed=false,
    this.mismatchCount=0, this.warningsAccepted=false,
    this.reviewer='', this.reviewedAt='',
    this.notes=const [],
  });
}

class SolarTermCandidateManualReviewOutput {
  final String schemaVersion; final bool passed; final String status; final bool readyForTrialIntegration;
  final List<String> blockingReasons; final List<String> warnings; final List<String> nextActions;
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;

  const SolarTermCandidateManualReviewOutput({
    this.schemaVersion='solar-term-candidate-manual-review-v0_30',
    required this.passed, required this.status, required this.readyForTrialIntegration,
    this.blockingReasons=const [], this.warnings=const [], this.nextActions=const [],
    this.productionReady=false, this.publicExposure=false, this.calendarProviderIntegration=false,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion':schemaVersion,'passed':passed,'status':status,'readyForTrialIntegration':readyForTrialIntegration,
    'blockingReasons':blockingReasons,'warnings':warnings,'nextActions':nextActions,
    'productionReady':productionReady,'publicExposure':publicExposure,'calendarProviderIntegration':calendarProviderIntegration,
  };
}

class SolarTermCandidateManualReviewer {
  const SolarTermCandidateManualReviewer();

  static const allApproved = SolarTermCandidateManualReviewInput(
    sourceReviewApproved:true, preparationReady:true, landingReviewReady:true, sandboxSafe:true,
    preflightPassed:true, validatorPassed:true, crossCheckPassed:true,
    productionReady:false, publicExposure:false, calendarProviderIntegration:false,
    sourceManuallyConfirmed:true, licenseManuallyConfirmed:true, embeddingAllowedConfirmed:true,
    offlineConfirmed:true, nonAiGeneratedConfirmed:true, nonFixedDateApproximationConfirmed:true,
    coverageManuallyConfirmed:true, all24TermsConfirmed:true,
    termDateConfirmed:true, termTimeConfirmed:true, timezoneConfirmed:true,
    lichunReferenceConfirmed:true, springEquinoxReferenceConfirmed:true,
    summerSolsticeReferenceConfirmed:true, autumnEquinoxReferenceConfirmed:true, winterSolsticeReferenceConfirmed:true,
    referenceFixtureConfirmed:true, benchmarkToleranceConfirmed:true,
    mismatchCount:0, warningsAccepted:true,
    reviewer:'manual_reviewer', reviewedAt:'2026-06-23T00:00:00+09:00',
  );

  ManualReviewStatus determineStatus(SolarTermCandidateManualReviewInput i) {
    if(!i.sourceReviewApproved) return ManualReviewStatus.source_review_not_approved;
    if(!i.preparationReady) return ManualReviewStatus.preparation_not_ready;
    if(!i.landingReviewReady) return ManualReviewStatus.landing_review_not_ready;
    if(!i.sandboxSafe) return ManualReviewStatus.sandbox_not_safe;
    if(!i.preflightPassed) return ManualReviewStatus.preflight_not_passed;
    if(!i.validatorPassed) return ManualReviewStatus.validator_not_passed;
    if(!i.crossCheckPassed) return ManualReviewStatus.cross_check_not_passed;
    if(i.productionReady) return ManualReviewStatus.rejected_production_ready_true;
    if(i.publicExposure) return ManualReviewStatus.rejected_public_exposure_true;
    if(i.calendarProviderIntegration) return ManualReviewStatus.rejected_calendar_provider_integration;
    if(!i.sourceManuallyConfirmed) return ManualReviewStatus.source_not_confirmed;
    if(!i.licenseManuallyConfirmed) return ManualReviewStatus.license_not_confirmed;
    if(!i.embeddingAllowedConfirmed) return ManualReviewStatus.embedding_permission_not_confirmed;
    if(!i.offlineConfirmed) return ManualReviewStatus.offline_not_confirmed;
    if(!i.nonAiGeneratedConfirmed) return ManualReviewStatus.ai_generated_not_rejected;
    if(!i.nonFixedDateApproximationConfirmed) return ManualReviewStatus.fixed_date_approximation_not_rejected;
    if(!i.coverageManuallyConfirmed) return ManualReviewStatus.coverage_not_confirmed;
    if(!i.all24TermsConfirmed) return ManualReviewStatus.term_coverage_not_confirmed;
    if(!i.termDateConfirmed) return ManualReviewStatus.term_date_not_confirmed;
    if(!i.termTimeConfirmed) return ManualReviewStatus.term_time_not_confirmed;
    if(!i.timezoneConfirmed) return ManualReviewStatus.timezone_not_confirmed;
    if(!i.lichunReferenceConfirmed) return ManualReviewStatus.lichun_reference_not_confirmed;
    if(!i.springEquinoxReferenceConfirmed) return ManualReviewStatus.spring_equinox_reference_not_confirmed;
    if(!i.summerSolsticeReferenceConfirmed) return ManualReviewStatus.summer_solstice_reference_not_confirmed;
    if(!i.autumnEquinoxReferenceConfirmed) return ManualReviewStatus.autumn_equinox_reference_not_confirmed;
    if(!i.winterSolsticeReferenceConfirmed) return ManualReviewStatus.winter_solstice_reference_not_confirmed;
    if(!i.referenceFixtureConfirmed) return ManualReviewStatus.reference_fixture_not_confirmed;
    if(!i.benchmarkToleranceConfirmed) return ManualReviewStatus.benchmark_tolerance_not_confirmed;
    if(i.mismatchCount>0) return ManualReviewStatus.mismatch_exists;
    if(!i.warningsAccepted) return ManualReviewStatus.warnings_not_accepted;
    if(i.reviewer.isEmpty) return ManualReviewStatus.reviewer_missing;
    if(i.reviewedAt.isEmpty) return ManualReviewStatus.reviewed_at_missing;
    return ManualReviewStatus.manual_review_passed;
  }

  SolarTermCandidateManualReviewOutput review(SolarTermCandidateManualReviewInput i) {
    final s=determineStatus(i); final p=s==ManualReviewStatus.manual_review_passed;
    final n=mrLabels[s]??'not_started';
    return SolarTermCandidateManualReviewOutput(passed:p,status:n,readyForTrialIntegration:p,
      blockingReasons:p?[]:[n],
      nextActions:p?['人工复核通过，可进入试运行接入设计阶段 (v0.31+)']:['修复阻塞原因: $n'],
    );
  }
}

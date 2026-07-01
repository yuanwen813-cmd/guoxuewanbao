/// 节气候选数据预检器 v0.27
///
/// 对候选数据进行结构、覆盖、节气序列、日期、时间、时区、安全标记的全面预检。
/// 即使 preflight_passed，productionReady/publicExposure/calendarProviderIntegration 仍为 false。

enum SolarTermPreflightStatus {
  not_started, candidate_data_missing, manifest_missing, schema_missing,
  source_review_not_approved, preparation_not_ready, landing_review_not_ready, sandbox_not_safe,
  candidate_data_not_ready,
  rejected_production_ready_true, rejected_public_exposure_true, rejected_calendar_provider_integration,
  rejected_ai_generated, rejected_network_dependency, rejected_fixed_date_approximation,
  source_metadata_missing, license_missing, timezone_missing,
  coverage_missing, coverage_incomplete,
  years_empty, year_out_of_range, yearly_terms_count_invalid,
  term_name_invalid, term_name_duplicate, term_sequence_invalid,
  term_date_invalid, term_time_missing, term_timezone_missing, term_order_invalid,
  preflight_passed,
}

const pfLabels = <SolarTermPreflightStatus, String>{
  SolarTermPreflightStatus.not_started: 'not_started',
  SolarTermPreflightStatus.candidate_data_missing: 'candidate_data_missing',
  SolarTermPreflightStatus.manifest_missing: 'manifest_missing',
  SolarTermPreflightStatus.schema_missing: 'schema_missing',
  SolarTermPreflightStatus.source_review_not_approved: 'source_review_not_approved',
  SolarTermPreflightStatus.preparation_not_ready: 'preparation_not_ready',
  SolarTermPreflightStatus.landing_review_not_ready: 'landing_review_not_ready',
  SolarTermPreflightStatus.sandbox_not_safe: 'sandbox_not_safe',
  SolarTermPreflightStatus.candidate_data_not_ready: 'candidate_data_not_ready',
  SolarTermPreflightStatus.rejected_production_ready_true: 'rejected_production_ready_true',
  SolarTermPreflightStatus.rejected_public_exposure_true: 'rejected_public_exposure_true',
  SolarTermPreflightStatus.rejected_calendar_provider_integration: 'rejected_calendar_provider_integration',
  SolarTermPreflightStatus.rejected_ai_generated: 'rejected_ai_generated',
  SolarTermPreflightStatus.rejected_network_dependency: 'rejected_network_dependency',
  SolarTermPreflightStatus.rejected_fixed_date_approximation: 'rejected_fixed_date_approximation',
  SolarTermPreflightStatus.source_metadata_missing: 'source_metadata_missing',
  SolarTermPreflightStatus.license_missing: 'license_missing',
  SolarTermPreflightStatus.timezone_missing: 'timezone_missing',
  SolarTermPreflightStatus.coverage_missing: 'coverage_missing',
  SolarTermPreflightStatus.coverage_incomplete: 'coverage_incomplete',
  SolarTermPreflightStatus.years_empty: 'years_empty',
  SolarTermPreflightStatus.year_out_of_range: 'year_out_of_range',
  SolarTermPreflightStatus.yearly_terms_count_invalid: 'yearly_terms_count_invalid',
  SolarTermPreflightStatus.term_name_invalid: 'term_name_invalid',
  SolarTermPreflightStatus.term_name_duplicate: 'term_name_duplicate',
  SolarTermPreflightStatus.term_sequence_invalid: 'term_sequence_invalid',
  SolarTermPreflightStatus.term_date_invalid: 'term_date_invalid',
  SolarTermPreflightStatus.term_time_missing: 'term_time_missing',
  SolarTermPreflightStatus.term_timezone_missing: 'term_timezone_missing',
  SolarTermPreflightStatus.term_order_invalid: 'term_order_invalid',
  SolarTermPreflightStatus.preflight_passed: 'preflight_passed',
};

class SolarTermCandidatePreflightInput {
  final bool candidateDataExists; final bool manifestExists; final bool schemaExists;
  final bool sourceReviewApproved; final bool preparationReady; final bool landingReviewReady; final bool sandboxSafe;
  final bool candidateDataReady;
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;
  final bool usesAiGeneratedData; final bool requiresNetwork; final bool usesFixedDateApproximation;
  final String sourceName; final String sourceType; final bool licenseAttached; final String timezone;
  final int? coverageStartYear; final int? coverageEndYear;
  final List<Map<String, dynamic>> years;
  final List<String> notes;

  const SolarTermCandidatePreflightInput({
    this.candidateDataExists=false, this.manifestExists=false, this.schemaExists=false,
    this.sourceReviewApproved=false, this.preparationReady=false, this.landingReviewReady=false, this.sandboxSafe=false,
    this.candidateDataReady=false,
    this.productionReady=false, this.publicExposure=false, this.calendarProviderIntegration=false,
    this.usesAiGeneratedData=false, this.requiresNetwork=false, this.usesFixedDateApproximation=false,
    this.sourceName='', this.sourceType='', this.licenseAttached=false, this.timezone='',
    this.coverageStartYear, this.coverageEndYear,
    this.years=const [], this.notes=const [],
  });
}

class SolarTermCandidatePreflightOutput {
  final String schemaVersion; final bool passed; final String status;
  final List<String> blockingReasons; final List<String> warnings; final List<String> nextActions;
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;

  const SolarTermCandidatePreflightOutput({
    this.schemaVersion='solar-term-candidate-preflight-v0_27',
    required this.passed, required this.status,
    this.blockingReasons=const [], this.warnings=const [], this.nextActions=const [],
    this.productionReady=false, this.publicExposure=false, this.calendarProviderIntegration=false,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion':schemaVersion,'passed':passed,'status':status,
    'blockingReasons':blockingReasons,'warnings':warnings,'nextActions':nextActions,
    'productionReady':productionReady,'publicExposure':publicExposure,'calendarProviderIntegration':calendarProviderIntegration,
  };
}

class SolarTermCandidatePreflightValidator {
  static const termNames = ['立春','雨水','惊蛰','春分','清明','谷雨','立夏','小满','芒种','夏至','小暑','大暑','立秋','处暑','白露','秋分','寒露','霜降','立冬','小雪','大雪','冬至','小寒','大寒'];

  const SolarTermCandidatePreflightValidator();

  SolarTermCandidatePreflightInput get baseApproved => SolarTermCandidatePreflightInput(
    candidateDataExists:true, manifestExists:true, schemaExists:true,
    sourceReviewApproved:true, preparationReady:true, landingReviewReady:true, sandboxSafe:true,
    candidateDataReady:true,
    productionReady:false, publicExposure:false, calendarProviderIntegration:false,
    usesAiGeneratedData:false, requiresNetwork:false, usesFixedDateApproximation:false,
    sourceName:'approved', sourceType:'official_public_data', licenseAttached:true, timezone:'Asia/Shanghai',
    coverageStartYear:1900, coverageEndYear:2100,
  );

  Map<String,dynamic> _validYear(int year) => {
    'year':year,
    'terms': List.generate(24, (i) => {'name':termNames[i],'date':'$year-${((i~/2)+1).toString().padLeft(2,'0')}-${(15+(i%2)*15).toString().padLeft(2,'0')}','time':'12:00','timezone':'Asia/Shanghai','sequenceIndex':i+1}),
  };

  SolarTermCandidatePreflightInput get withValidYears => SolarTermCandidatePreflightInput(
    candidateDataExists:true, manifestExists:true, schemaExists:true,
    sourceReviewApproved:true, preparationReady:true, landingReviewReady:true, sandboxSafe:true,
    candidateDataReady:true,
    productionReady:false, publicExposure:false, calendarProviderIntegration:false,
    usesAiGeneratedData:false, requiresNetwork:false, usesFixedDateApproximation:false,
    sourceName:'approved', sourceType:'official_public_data', licenseAttached:true, timezone:'Asia/Shanghai',
    coverageStartYear:1900, coverageEndYear:2100,
    years:[_validYear(2026)],
  );

  SolarTermPreflightStatus determineStatus(SolarTermCandidatePreflightInput i) {
    if(!i.candidateDataExists) return SolarTermPreflightStatus.candidate_data_missing;
    if(!i.manifestExists) return SolarTermPreflightStatus.manifest_missing;
    if(!i.schemaExists) return SolarTermPreflightStatus.schema_missing;
    if(!i.sourceReviewApproved) return SolarTermPreflightStatus.source_review_not_approved;
    if(!i.preparationReady) return SolarTermPreflightStatus.preparation_not_ready;
    if(!i.landingReviewReady) return SolarTermPreflightStatus.landing_review_not_ready;
    if(!i.sandboxSafe) return SolarTermPreflightStatus.sandbox_not_safe;
    if(!i.candidateDataReady) return SolarTermPreflightStatus.candidate_data_not_ready;
    if(i.productionReady) return SolarTermPreflightStatus.rejected_production_ready_true;
    if(i.publicExposure) return SolarTermPreflightStatus.rejected_public_exposure_true;
    if(i.calendarProviderIntegration) return SolarTermPreflightStatus.rejected_calendar_provider_integration;
    if(i.usesAiGeneratedData) return SolarTermPreflightStatus.rejected_ai_generated;
    if(i.requiresNetwork) return SolarTermPreflightStatus.rejected_network_dependency;
    if(i.usesFixedDateApproximation) return SolarTermPreflightStatus.rejected_fixed_date_approximation;
    if(i.sourceName.isEmpty||i.sourceType.isEmpty) return SolarTermPreflightStatus.source_metadata_missing;
    if(!i.licenseAttached) return SolarTermPreflightStatus.license_missing;
    if(i.timezone.isEmpty) return SolarTermPreflightStatus.timezone_missing;
    if(i.coverageStartYear==null||i.coverageEndYear==null) return SolarTermPreflightStatus.coverage_missing;
    if(i.coverageStartYear!>1900||i.coverageEndYear!<2100) return SolarTermPreflightStatus.coverage_incomplete;
    if(i.years.isEmpty) return SolarTermPreflightStatus.years_empty;

    for(final y in i.years) {
      final yr=y['year'] as int?; final terms=y['terms'] as List?;
      if(yr==null||yr<i.coverageStartYear!||yr>i.coverageEndYear!) return SolarTermPreflightStatus.year_out_of_range;
      if(terms==null||terms.length!=24) return SolarTermPreflightStatus.yearly_terms_count_invalid;

      final names=<String>{};
      for(final t in terms) {
        final tm=t as Map<String,dynamic>;
        final name=tm['name'] as String?; final si=tm['sequenceIndex'] as int?; final date=tm['date'] as String?;
        final time=tm['time'] as String?; final tz=tm['timezone'] as String?;
        if(name==null||!termNames.contains(name)) return SolarTermPreflightStatus.term_name_invalid;
        if(!names.add(name)) return SolarTermPreflightStatus.term_name_duplicate;
        if(si==null||si<1||si>24) return SolarTermPreflightStatus.term_sequence_invalid;
        if(date==null||date.isEmpty) return SolarTermPreflightStatus.term_date_invalid;
        if(time==null||time.isEmpty) return SolarTermPreflightStatus.term_time_missing;
        if(tz==null||tz.isEmpty) return SolarTermPreflightStatus.term_timezone_missing;
      }
      // Check term order
      for(int j=1;j<terms.length;j++) {
        final prev=(terms[j-1] as Map<String,dynamic>)['sequenceIndex'] as int?;
        final curr=(terms[j] as Map<String,dynamic>)['sequenceIndex'] as int?;
        if(prev!=null&&curr!=null&&prev>=curr) return SolarTermPreflightStatus.term_order_invalid;
      }
    }
    return SolarTermPreflightStatus.preflight_passed;
  }

  SolarTermCandidatePreflightOutput validate(SolarTermCandidatePreflightInput i) {
    final s=determineStatus(i); final p=s==SolarTermPreflightStatus.preflight_passed;
    final n=pfLabels[s]??'not_started';
    return SolarTermCandidatePreflightOutput(passed:p,status:n,
      blockingReasons:p?[]:[n],
      nextActions:p?['预检通过，可进入下一阶段验证']:['修复阻塞原因: $n'],
    );
  }
}

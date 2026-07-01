/// 节气候选数据交叉验证器 v0.29
///
/// 对候选数据与 reference fixture / benchmark / known date 进行交叉验证。
/// 即使 cross_check_passed，productionReady/publicExposure/calendarProviderIntegration 仍为 false。

enum CrossCheckStatus {
  not_started, validator_not_passed, candidate_data_not_ready,
  rejected_production_ready_true, rejected_public_exposure_true, rejected_calendar_provider_integration,
  coverage_missing, years_empty,
  reference_fixture_missing, reference_fixture_invalid, reference_fixture_term_missing,
  reference_fixture_date_mismatch, reference_fixture_timezone_mismatch,
  benchmark_missing, benchmark_invalid, benchmark_term_missing, benchmark_date_out_of_tolerance,
  lichun_reference_missing, winter_solstice_reference_missing, quarter_term_reference_missing,
  insufficient_high_confidence_references,
  cross_check_passed,
}

const ccLabels = <CrossCheckStatus, String>{
  CrossCheckStatus.not_started: 'not_started',
  CrossCheckStatus.validator_not_passed: 'validator_not_passed',
  CrossCheckStatus.candidate_data_not_ready: 'candidate_data_not_ready',
  CrossCheckStatus.rejected_production_ready_true: 'rejected_production_ready_true',
  CrossCheckStatus.rejected_public_exposure_true: 'rejected_public_exposure_true',
  CrossCheckStatus.rejected_calendar_provider_integration: 'rejected_calendar_provider_integration',
  CrossCheckStatus.coverage_missing: 'coverage_missing',
  CrossCheckStatus.years_empty: 'years_empty',
  CrossCheckStatus.reference_fixture_missing: 'reference_fixture_missing',
  CrossCheckStatus.reference_fixture_invalid: 'reference_fixture_invalid',
  CrossCheckStatus.reference_fixture_term_missing: 'reference_fixture_term_missing',
  CrossCheckStatus.reference_fixture_date_mismatch: 'reference_fixture_date_mismatch',
  CrossCheckStatus.reference_fixture_timezone_mismatch: 'reference_fixture_timezone_mismatch',
  CrossCheckStatus.benchmark_missing: 'benchmark_missing',
  CrossCheckStatus.benchmark_invalid: 'benchmark_invalid',
  CrossCheckStatus.benchmark_term_missing: 'benchmark_term_missing',
  CrossCheckStatus.benchmark_date_out_of_tolerance: 'benchmark_date_out_of_tolerance',
  CrossCheckStatus.lichun_reference_missing: 'lichun_reference_missing',
  CrossCheckStatus.winter_solstice_reference_missing: 'winter_solstice_reference_missing',
  CrossCheckStatus.quarter_term_reference_missing: 'quarter_term_reference_missing',
  CrossCheckStatus.insufficient_high_confidence_references: 'insufficient_high_confidence_references',
  CrossCheckStatus.cross_check_passed: 'cross_check_passed',
};

class SolarTermCandidateCrossCheckInput {
  final bool validatorPassed; final bool candidateDataReady;
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;
  final int? coverageStartYear; final int? coverageEndYear;
  final List<Map<String, dynamic>> years;
  final List<Map<String, dynamic>> referenceFixtures;
  final List<Map<String, dynamic>> benchmarkDates;
  final List<String> notes;

  const SolarTermCandidateCrossCheckInput({
    this.validatorPassed=false, this.candidateDataReady=false,
    this.productionReady=false, this.publicExposure=false, this.calendarProviderIntegration=false,
    this.coverageStartYear, this.coverageEndYear,
    this.years=const [], this.referenceFixtures=const [], this.benchmarkDates=const [],
    this.notes=const [],
  });
}

class SolarTermCandidateCrossCheckOutput {
  final String schemaVersion; final bool passed; final String status;
  final int checkedFixtures; final int matchedFixtures; final int mismatchedFixtures;
  final int checkedBenchmarks; final int matchedBenchmarks; final int mismatchedBenchmarks;
  final List<String> blockingReasons; final List<String> warnings; final List<String> nextActions;
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;

  const SolarTermCandidateCrossCheckOutput({
    this.schemaVersion='solar-term-candidate-cross-check-v0_29',
    required this.passed, required this.status,
    this.checkedFixtures=0, this.matchedFixtures=0, this.mismatchedFixtures=0,
    this.checkedBenchmarks=0, this.matchedBenchmarks=0, this.mismatchedBenchmarks=0,
    this.blockingReasons=const [], this.warnings=const [], this.nextActions=const [],
    this.productionReady=false, this.publicExposure=false, this.calendarProviderIntegration=false,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion':schemaVersion,'passed':passed,'status':status,
    'checkedFixtures':checkedFixtures,'matchedFixtures':matchedFixtures,'mismatchedFixtures':mismatchedFixtures,
    'checkedBenchmarks':checkedBenchmarks,'matchedBenchmarks':matchedBenchmarks,'mismatchedBenchmarks':mismatchedBenchmarks,
    'blockingReasons':blockingReasons,'warnings':warnings,'nextActions':nextActions,
    'productionReady':productionReady,'publicExposure':publicExposure,'calendarProviderIntegration':calendarProviderIntegration,
  };
}

class SolarTermCandidateCrossChecker {
  static const termNames = ['立春','雨水','惊蛰','春分','清明','谷雨','立夏','小满','芒种','夏至','小暑','大暑','立秋','处暑','白露','秋分','寒露','霜降','立冬','小雪','大雪','冬至','小寒','大寒'];
  static const quarterSet = {'春分','夏至','秋分','冬至'};

  const SolarTermCandidateCrossChecker();

  /// Build sample reference fixtures for v0.29 testing
  static List<Map<String,dynamic>> sampleReferences(int year) => [
    {'year':year,'termName':'立春','expectedDate':'$year-02-04','expectedTime':null,'timezone':'Asia/Shanghai','source':'manual_reference','confidence':'high'},
    {'year':year,'termName':'春分','expectedDate':'$year-03-20','expectedTime':null,'timezone':'Asia/Shanghai','source':'manual_reference','confidence':'high'},
    {'year':year,'termName':'夏至','expectedDate':'$year-06-21','expectedTime':null,'timezone':'Asia/Shanghai','source':'manual_reference','confidence':'high'},
    {'year':year,'termName':'秋分','expectedDate':'$year-09-23','expectedTime':null,'timezone':'Asia/Shanghai','source':'manual_reference','confidence':'high'},
    {'year':year,'termName':'冬至','expectedDate':'$year-12-22','expectedTime':null,'timezone':'Asia/Shanghai','source':'manual_reference','confidence':'high'},
  ];

  static List<Map<String,dynamic>> sampleBenchmarks(int year) => [
    {'year':year,'termName':'立春','expectedDate':'$year-02-04','toleranceDays':2,'source':'benchmark','confidence':'medium'},
    {'year':year,'termName':'冬至','expectedDate':'$year-12-22','toleranceDays':1,'source':'benchmark','confidence':'medium'},
  ];

  Map<String,Map<String,dynamic>> _buildTermIndex(List<Map<String,dynamic>> years) {
    final idx=<String,Map<String,dynamic>>{};
    for(final y in years){final yr=y['year']; for(final t in (y['terms'] as List)){final tm=t as Map<String,dynamic>; idx['$yr:${tm['name']}']=tm;}}
    return idx;
  }

  CrossCheckStatus determineStatus(SolarTermCandidateCrossCheckInput i) {
    if(!i.validatorPassed) return CrossCheckStatus.validator_not_passed;
    if(!i.candidateDataReady) return CrossCheckStatus.candidate_data_not_ready;
    if(i.productionReady) return CrossCheckStatus.rejected_production_ready_true;
    if(i.publicExposure) return CrossCheckStatus.rejected_public_exposure_true;
    if(i.calendarProviderIntegration) return CrossCheckStatus.rejected_calendar_provider_integration;
    if(i.coverageStartYear==null||i.coverageEndYear==null) return CrossCheckStatus.coverage_missing;
    if(i.years.isEmpty) return CrossCheckStatus.years_empty;
    if(i.referenceFixtures.isEmpty) return CrossCheckStatus.reference_fixture_missing;

    final idx=_buildTermIndex(i.years);
    final refNames=<String>{};
    int highConf=0;

    for(final ref in i.referenceFixtures) {
      final rn=ref['termName'] as String?; final ed=ref['expectedDate'] as String?;
      final tz=ref['timezone'] as String?; final yr=ref['year'];
      final conf=ref['confidence'] as String?;
      if(rn==null||ed==null||tz==null||yr==null) return CrossCheckStatus.reference_fixture_invalid;
      refNames.add(rn);
      if(conf=='high') highConf++;
      final key='$yr:$rn'; final ct=idx[key];
      if(ct==null) return CrossCheckStatus.reference_fixture_term_missing;
      if(ct['date']!=ed) return CrossCheckStatus.reference_fixture_date_mismatch;
      if(ct['timezone']!=tz) return CrossCheckStatus.reference_fixture_timezone_mismatch;
    }

    if(!refNames.contains('立春')) return CrossCheckStatus.lichun_reference_missing;
    if(!refNames.contains('冬至')) return CrossCheckStatus.winter_solstice_reference_missing;
    if(!refNames.containsAll(quarterSet)) return CrossCheckStatus.quarter_term_reference_missing;
    if(highConf<2) return CrossCheckStatus.insufficient_high_confidence_references;

    if(i.benchmarkDates.isEmpty) return CrossCheckStatus.benchmark_missing;
    for(final bm in i.benchmarkDates) {
      final bn=bm['termName'] as String?; final ed=bm['expectedDate'] as String?;
      final tol=bm['toleranceDays'] as int?; final yr2=bm['year'];
      if(bn==null||ed==null||tol==null||yr2==null) return CrossCheckStatus.benchmark_invalid;
      final key='$yr2:$bn'; final ct=idx[key];
      if(ct==null) return CrossCheckStatus.benchmark_term_missing;
      final cd=ct['date'] as String?; if(cd==null) return CrossCheckStatus.benchmark_invalid;
      // Simple tolerance: abs day difference
      final cdd=DateTime.tryParse(cd); final edd=DateTime.tryParse(ed);
      if(cdd==null||edd==null) return CrossCheckStatus.benchmark_invalid;
      if((cdd.difference(edd)).inDays.abs()>tol) return CrossCheckStatus.benchmark_date_out_of_tolerance;
    }
    return CrossCheckStatus.cross_check_passed;
  }

  SolarTermCandidateCrossCheckOutput check(SolarTermCandidateCrossCheckInput i) {
    final s=determineStatus(i); final p=s==CrossCheckStatus.cross_check_passed;
    final n=ccLabels[s]??'not_started';
    int cf=0,mf=0,xf=0,cb=0,mb=0,xb=0;

    if(p||s==CrossCheckStatus.reference_fixture_date_mismatch||s==CrossCheckStatus.reference_fixture_timezone_mismatch||s==CrossCheckStatus.lichun_reference_missing||s==CrossCheckStatus.winter_solstice_reference_missing||s==CrossCheckStatus.quarter_term_reference_missing||s==CrossCheckStatus.insufficient_high_confidence_references||s==CrossCheckStatus.benchmark_missing||s==CrossCheckStatus.benchmark_date_out_of_tolerance) {
      final idx=_buildTermIndex(i.years);
      for(final ref in i.referenceFixtures) {
        final rn=ref['termName'] as String?; final ed=ref['expectedDate'] as String?;
        final tz=ref['timezone'] as String?; final yr=ref['year'];
        if(rn==null||ed==null||tz==null||yr==null) continue;
        cf++; final ct=idx['$yr:$rn']; if(ct!=null&&ct['date']==ed&&ct['timezone']==tz) mf++; else xf++;
      }
      for(final bm in i.benchmarkDates) {
        final bn=bm['termName'] as String?; final ed=bm['expectedDate'] as String?;
        final tol=bm['toleranceDays'] as int?; final yr2=bm['year'];
        if(bn==null||ed==null||tol==null||yr2==null) continue;
        cb++; final ct=idx['$yr2:$bn'];
        if(ct!=null){final cdDate=DateTime.tryParse(ct['date']??'');final edDate=DateTime.tryParse(ed);if(cdDate!=null&&edDate!=null&&(cdDate.difference(edDate)).inDays.abs()<=tol)mb++;else xb++;}
      }
    }

    return SolarTermCandidateCrossCheckOutput(passed:p,status:n,
      checkedFixtures:cf,matchedFixtures:mf,mismatchedFixtures:xf,
      checkedBenchmarks:cb,matchedBenchmarks:mb,mismatchedBenchmarks:xb,
      blockingReasons:p?[]:[n],
      nextActions:p?['交叉验证通过，可进入下一阶段']:['修复阻塞原因: $n'],
    );
  }
}

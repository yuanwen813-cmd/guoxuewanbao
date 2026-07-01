/// 节气候选数据正式校验器 v0.28
///
/// 对候选数据进行完整性、连续性、边界、日期合法性、时间合法性、时区一致性校验。
/// 即使 validator_passed，productionReady/publicExposure/calendarProviderIntegration 仍为 false。

enum SolarTermValidationStatus {
  not_started, preflight_not_passed, candidate_data_not_ready,
  rejected_production_ready_true, rejected_public_exposure_true, rejected_calendar_provider_integration,
  coverage_missing, coverage_incomplete,
  years_empty, year_count_mismatch, year_out_of_range, year_duplicate,
  yearly_terms_count_invalid, term_name_invalid, term_name_duplicate,
  term_sequence_invalid, term_sequence_duplicate, term_order_invalid,
  term_date_invalid, term_date_year_mismatch, term_time_invalid,
  term_timezone_missing, term_timezone_mismatch, term_date_order_invalid,
  major_term_missing, quarter_term_missing, lichun_missing,
  validator_passed,
}

const vLabels = <SolarTermValidationStatus, String>{
  SolarTermValidationStatus.not_started: 'not_started',
  SolarTermValidationStatus.preflight_not_passed: 'preflight_not_passed',
  SolarTermValidationStatus.candidate_data_not_ready: 'candidate_data_not_ready',
  SolarTermValidationStatus.rejected_production_ready_true: 'rejected_production_ready_true',
  SolarTermValidationStatus.rejected_public_exposure_true: 'rejected_public_exposure_true',
  SolarTermValidationStatus.rejected_calendar_provider_integration: 'rejected_calendar_provider_integration',
  SolarTermValidationStatus.coverage_missing: 'coverage_missing',
  SolarTermValidationStatus.coverage_incomplete: 'coverage_incomplete',
  SolarTermValidationStatus.years_empty: 'years_empty',
  SolarTermValidationStatus.year_count_mismatch: 'year_count_mismatch',
  SolarTermValidationStatus.year_out_of_range: 'year_out_of_range',
  SolarTermValidationStatus.year_duplicate: 'year_duplicate',
  SolarTermValidationStatus.yearly_terms_count_invalid: 'yearly_terms_count_invalid',
  SolarTermValidationStatus.term_name_invalid: 'term_name_invalid',
  SolarTermValidationStatus.term_name_duplicate: 'term_name_duplicate',
  SolarTermValidationStatus.term_sequence_invalid: 'term_sequence_invalid',
  SolarTermValidationStatus.term_sequence_duplicate: 'term_sequence_duplicate',
  SolarTermValidationStatus.term_order_invalid: 'term_order_invalid',
  SolarTermValidationStatus.term_date_invalid: 'term_date_invalid',
  SolarTermValidationStatus.term_date_year_mismatch: 'term_date_year_mismatch',
  SolarTermValidationStatus.term_time_invalid: 'term_time_invalid',
  SolarTermValidationStatus.term_timezone_missing: 'term_timezone_missing',
  SolarTermValidationStatus.term_timezone_mismatch: 'term_timezone_mismatch',
  SolarTermValidationStatus.term_date_order_invalid: 'term_date_order_invalid',
  SolarTermValidationStatus.major_term_missing: 'major_term_missing',
  SolarTermValidationStatus.quarter_term_missing: 'quarter_term_missing',
  SolarTermValidationStatus.lichun_missing: 'lichun_missing',
  SolarTermValidationStatus.validator_passed: 'validator_passed',
};

class SolarTermCandidateValidationInput {
  final bool preflightPassed; final bool candidateDataReady;
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;
  final String sourceName; final String sourceType; final String timezone;
  final int? coverageStartYear; final int? coverageEndYear;
  final List<Map<String, dynamic>> years;
  final List<String> notes;

  const SolarTermCandidateValidationInput({
    this.preflightPassed=false, this.candidateDataReady=false,
    this.productionReady=false, this.publicExposure=false, this.calendarProviderIntegration=false,
    this.sourceName='', this.sourceType='', this.timezone='',
    this.coverageStartYear, this.coverageEndYear,
    this.years=const [], this.notes=const [],
  });
}

class SolarTermCandidateValidationOutput {
  final String schemaVersion; final bool passed; final String status;
  final int validatedYears; final int validatedTerms;
  final List<String> blockingReasons; final List<String> warnings; final List<String> nextActions;
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;

  const SolarTermCandidateValidationOutput({
    this.schemaVersion='solar-term-candidate-validator-v0_28',
    required this.passed, required this.status,
    this.validatedYears=0, this.validatedTerms=0,
    this.blockingReasons=const [], this.warnings=const [], this.nextActions=const [],
    this.productionReady=false, this.publicExposure=false, this.calendarProviderIntegration=false,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion':schemaVersion,'passed':passed,'status':status,
    'validatedYears':validatedYears,'validatedTerms':validatedTerms,
    'blockingReasons':blockingReasons,'warnings':warnings,'nextActions':nextActions,
    'productionReady':productionReady,'publicExposure':publicExposure,'calendarProviderIntegration':calendarProviderIntegration,
  };
}

class SolarTermCandidateValidator {
  static const termNames = ['立春','雨水','惊蛰','春分','清明','谷雨','立夏','小满','芒种','夏至','小暑','大暑','立秋','处暑','白露','秋分','寒露','霜降','立冬','小雪','大雪','冬至','小寒','大寒'];
  static const majorTerms = {'小寒','大寒','立春','冬至'};
  static const quarterTerms = {'春分','夏至','秋分','冬至'};
  static final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _timeRe = RegExp(r'^\d{2}:\d{2}(:\d{2})?$');

  const SolarTermCandidateValidator();

  bool _isValidDate(String d) {
    if(!_dateRe.hasMatch(d)) return false;
    final parts=d.split('-'); final y=int.tryParse(parts[0]),m=int.tryParse(parts[1]),day=int.tryParse(parts[2]);
    if(y==null||m==null||day==null||m<1||m>12||day<1||day>31) return false;
    final dim=[0,31,28,31,30,31,30,31,31,30,31,30,31];
    int mx=dim[m]; if(m==2&&((y%4==0&&y%100!=0)||y%400==0)) mx=29;
    return day<=mx;
  }

  bool _isValidTime(String t) {
    if(!_timeRe.hasMatch(t)) return false;
    final parts=t.split(':'); final h=int.parse(parts[0]),mm=int.parse(parts[1]);
    if(h<0||h>23||mm<0||mm>59) return false;
    if(parts.length>2) { final s=int.parse(parts[2]); if(s<0||s>59) return false; }
    return true;
  }

  List<Map<String,dynamic>> _validYearData(int year) => List.generate(24, (i) => {
    'name':termNames[i],'sequenceIndex':i+1,
    'date':'$year-${((i~/2)+1).toString().padLeft(2,'0')}-${(15+(i%2)*10).toString().padLeft(2,'0')}',
    'time':'12:00','timezone':'Asia/Shanghai',
  });

  SolarTermCandidateValidationInput get withValidData => SolarTermCandidateValidationInput(
    preflightPassed:true, candidateDataReady:true,
    sourceName:'approved', sourceType:'official_public_data', timezone:'Asia/Shanghai',
    coverageStartYear:1900, coverageEndYear:2100,
    years: List.generate(201, (i) => {'year':1900+i, 'terms':_validYearData(1900+i)}),
  );

  SolarTermValidationStatus determineStatus(SolarTermCandidateValidationInput i) {
    if(!i.preflightPassed) return SolarTermValidationStatus.preflight_not_passed;
    if(!i.candidateDataReady) return SolarTermValidationStatus.candidate_data_not_ready;
    if(i.productionReady) return SolarTermValidationStatus.rejected_production_ready_true;
    if(i.publicExposure) return SolarTermValidationStatus.rejected_public_exposure_true;
    if(i.calendarProviderIntegration) return SolarTermValidationStatus.rejected_calendar_provider_integration;
    final sy=i.coverageStartYear, ey=i.coverageEndYear;
    if(sy==null||ey==null) return SolarTermValidationStatus.coverage_missing;
    if(sy>1900||ey<2100) return SolarTermValidationStatus.coverage_incomplete;
    if(i.years.isEmpty) return SolarTermValidationStatus.years_empty;
    final expectedCount=ey-sy+1;
    if(i.years.length!=expectedCount) return SolarTermValidationStatus.year_count_mismatch;

    final seenYears=<int>{};
    for(final y in i.years) {
      final yr=y['year'] as int?; if(yr==null||yr<sy||yr>ey) return SolarTermValidationStatus.year_out_of_range;
      if(!seenYears.add(yr)) return SolarTermValidationStatus.year_duplicate;
      final terms=y['terms'] as List?; if(terms==null||terms.length!=24) return SolarTermValidationStatus.yearly_terms_count_invalid;

      final names=<String>{}, seqs=<int>{};
      for(final t in terms) {
        final tm=t as Map<String,dynamic>;
        final name=tm['name'] as String?; final si=tm['sequenceIndex'] as int?;
        final date=tm['date'] as String?; final time=tm['time'] as String?; final tz=tm['timezone'] as String?;
        if(name==null||!termNames.contains(name)) return SolarTermValidationStatus.term_name_invalid;
        if(!names.add(name)) return SolarTermValidationStatus.term_name_duplicate;
        if(si==null||si<1||si>24) return SolarTermValidationStatus.term_sequence_invalid;
        if(!seqs.add(si)) return SolarTermValidationStatus.term_sequence_duplicate;
        if(date==null||date.isEmpty||!_isValidDate(date)) return SolarTermValidationStatus.term_date_invalid;
        final dYear=int.parse(date.substring(0,4));
        if((dYear-yr).abs()>1) return SolarTermValidationStatus.term_date_year_mismatch;
        if(time==null||time.isEmpty||!_isValidTime(time)) return SolarTermValidationStatus.term_time_invalid;
        if(tz==null||tz.isEmpty) return SolarTermValidationStatus.term_timezone_missing;
        if(tz!=i.timezone) return SolarTermValidationStatus.term_timezone_mismatch;
      }
      // key term checks (after individual validation, before order/date checks)
      if(!names.containsAll(majorTerms)) return SolarTermValidationStatus.major_term_missing;
      if(!names.containsAll(quarterTerms)) return SolarTermValidationStatus.quarter_term_missing;
      if(!names.contains('立春')) return SolarTermValidationStatus.lichun_missing;
      for(int j=1;j<terms.length;j++) {
        final prev=(terms[j-1] as Map<String,dynamic>)['sequenceIndex'] as int?;
        final curr=(terms[j] as Map<String,dynamic>)['sequenceIndex'] as int?;
        if(prev!=null&&curr!=null&&prev>=curr) return SolarTermValidationStatus.term_order_invalid;
      }
      for(int j=1;j<terms.length;j++) {
        final pd=(terms[j-1] as Map<String,dynamic>)['date'] as String?;
        final cd=(terms[j] as Map<String,dynamic>)['date'] as String?;
        if(pd!=null&&cd!=null&&pd.compareTo(cd)>=0) return SolarTermValidationStatus.term_date_order_invalid;
      }
    }
    return SolarTermValidationStatus.validator_passed;
  }

  SolarTermCandidateValidationOutput validate(SolarTermCandidateValidationInput i) {
    final s=determineStatus(i); final p=s==SolarTermValidationStatus.validator_passed;
    final n=vLabels[s]??'not_started';
    int vy=0, vt=0;
    if(p) { vy=i.years.length; for(final y in i.years) { vt+=(y['terms'] as List?)?.length??0; } }
    return SolarTermCandidateValidationOutput(passed:p,status:n,validatedYears:vy,validatedTerms:vt,
      blockingReasons:p?[]:[n],
      nextActions:p?['校验通过，可进入下一阶段']:['修复阻塞原因: $n'],
    );
  }
}

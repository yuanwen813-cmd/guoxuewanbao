import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/tool/calendar/solar_term_candidate_cross_checker.dart';

void main() {
  final cc = const SolarTermCandidateCrossChecker();
  final termNames = SolarTermCandidateCrossChecker.termNames;

  // Generate candidate data with dates matching the sample references
  List<Map<String,dynamic>> _matchYear(int yr) {
    final refs=Map<String,String>.fromEntries(SolarTermCandidateCrossChecker.sampleReferences(yr).map((r)=>MapEntry(r['termName'] as String,r['expectedDate'] as String)));
    return [{'year':yr,'terms':List.generate(24,(i)=><String,dynamic>{'name':termNames[i],'sequenceIndex':i+1,'date':refs[termNames[i]]??'$yr-01-01','time':'12:00','timezone':'Asia/Shanghai'})}];
  }
  final ref2026 = SolarTermCandidateCrossChecker.sampleReferences(2026);
  final bm2026 = SolarTermCandidateCrossChecker.sampleBenchmarks(2026);

  SolarTermCandidateCrossCheckInput _base(bool ok) => SolarTermCandidateCrossCheckInput(
    validatorPassed:ok,candidateDataReady:ok,coverageStartYear:1900,coverageEndYear:2100,
    years:ok?_matchYear(2026):[],referenceFixtures:ok?ref2026:[],benchmarkDates:ok?bm2026:[],
  );

  group('gate & safety', () {
    test('validator not passed',()=>expect(cc.check(const SolarTermCandidateCrossCheckInput()).status,'validator_not_passed'));
    test('data not ready',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true)).status,'candidate_data_not_ready'));
    test('prodReady rejected',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,productionReady:true)).status,'rejected_production_ready_true'));
    test('publicExposure rejected',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,publicExposure:true)).status,'rejected_public_exposure_true'));
    test('calProvider rejected',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,calendarProviderIntegration:true)).status,'rejected_calendar_provider_integration'));
    test('coverage missing',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true)).status,'coverage_missing'));
    test('years empty',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100)).status,'years_empty'));
  });

  group('reference fixture', () {
    test('missing',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,years:_matchYear(2026))).status,'reference_fixture_missing'));
    test('invalid (missing fields)',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,years:_matchYear(2026),referenceFixtures:[{'bad':'data'}])).status,'reference_fixture_invalid'));
    test('term missing',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,years:_matchYear(2026),referenceFixtures:[{'year':2026,'termName':'立春','expectedDate':'2026-02-05','timezone':'Asia/Shanghai','source':'ref','confidence':'high'}])).status,'reference_fixture_date_mismatch'));
    test('date mismatch',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,years:_matchYear(2026),referenceFixtures:[{'year':2026,'termName':'立春','expectedDate':'2026-02-05','timezone':'Asia/Shanghai','source':'ref','confidence':'high'}])).status,'reference_fixture_date_mismatch'));
    test('tz mismatch',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,years:_matchYear(2026),referenceFixtures:[{'year':2026,'termName':'立春','expectedDate':'2026-02-04','timezone':'UTC','source':'ref','confidence':'high'}])).status,'reference_fixture_timezone_mismatch'));
    test('lichun missing',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,years:_matchYear(2026),referenceFixtures:[{'year':2026,'termName':'春分','expectedDate':'2026-03-20','timezone':'Asia/Shanghai','source':'ref','confidence':'high'}])).status,'lichun_reference_missing'));
    test('winter solstice missing',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,years:_matchYear(2026),referenceFixtures:[{'year':2026,'termName':'立春','expectedDate':'2026-02-04','timezone':'Asia/Shanghai','source':'ref','confidence':'high'}])).status,'winter_solstice_reference_missing'));
    test('quarter missing',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,years:_matchYear(2026),referenceFixtures:[{'year':2026,'termName':'立春','expectedDate':'2026-02-04','timezone':'Asia/Shanghai','source':'ref','confidence':'high'},{'year':2026,'termName':'冬至','expectedDate':'2026-12-22','timezone':'Asia/Shanghai','source':'ref','confidence':'high'}])).status,'quarter_term_reference_missing'));
    test('insufficient high conf',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,years:_matchYear(2026),referenceFixtures:[{'year':2026,'termName':'立春','expectedDate':'2026-02-04','timezone':'Asia/Shanghai','source':'ref','confidence':'low'},{'year':2026,'termName':'春分','expectedDate':'2026-03-20','timezone':'Asia/Shanghai','source':'ref','confidence':'low'},{'year':2026,'termName':'夏至','expectedDate':'2026-06-21','timezone':'Asia/Shanghai','source':'ref','confidence':'low'},{'year':2026,'termName':'秋分','expectedDate':'2026-09-23','timezone':'Asia/Shanghai','source':'ref','confidence':'low'},{'year':2026,'termName':'冬至','expectedDate':'2026-12-22','timezone':'Asia/Shanghai','source':'ref','confidence':'low'}])).status,'insufficient_high_confidence_references'));
  });

  group('benchmark', () {
    test('missing',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,years:_matchYear(2026),referenceFixtures:ref2026)).status,'benchmark_missing'));
    test('invalid',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,years:_matchYear(2026),referenceFixtures:ref2026,benchmarkDates:[{'bad':'data'}])).status,'benchmark_invalid'));
    test('term missing',()=>expect(cc.check(SolarTermCandidateCrossCheckInput(validatorPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,years:_matchYear(2026),referenceFixtures:ref2026,benchmarkDates:[{'year':9999,'termName':'立春','expectedDate':'9999-02-04','toleranceDays':2,'source':'bm','confidence':'medium'}])).status,'benchmark_term_missing'));
  });

  group('cross check passed', () {
    test('valid→passed',() {
      final o=cc.check(_base(true));
      expect(o.passed,true);
      expect(o.status,'cross_check_passed');
      expect(o.checkedFixtures,5);
      expect(o.matchedFixtures,5);
      expect(o.mismatchedFixtures,0);
      expect(o.checkedBenchmarks,2);
      expect(o.matchedBenchmarks,2);
      expect(o.mismatchedBenchmarks,0);
    });
    test('productionReady false',()=>expect(cc.check(_base(true)).productionReady,false));
    test('publicExposure false',()=>expect(cc.check(_base(true)).publicExposure,false));
    test('calendarProviderIntegration false',()=>expect(cc.check(_base(true)).calendarProviderIntegration,false));
    test('schemaVersion',()=>expect(cc.check(_base(true)).schemaVersion,'solar-term-candidate-cross-check-v0_29'));
  });
}

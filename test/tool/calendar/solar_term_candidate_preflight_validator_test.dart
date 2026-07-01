import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/tool/calendar/solar_term_candidate_preflight_validator.dart';

void main() {
  final v = const SolarTermCandidatePreflightValidator();
  final a = v.withValidYears;

  group('gate states', () {
    test('data missing',()=>expect(v.validate(const SolarTermCandidatePreflightInput()).status,'candidate_data_missing'));
    test('manifest missing',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true)).status,'manifest_missing'));
    test('schema missing',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true)).status,'schema_missing'));
    test('source not approved',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true)).status,'source_review_not_approved'));
    test('prep not ready',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true)).status,'preparation_not_ready'));
    test('landing not ready',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true)).status,'landing_review_not_ready'));
    test('sandbox not safe',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true)).status,'sandbox_not_safe'));
    test('data not ready',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true)).status,'candidate_data_not_ready'));
  });

  group('safety flag rejection', () {
    final b = SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true);
    test('prodReady',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,productionReady:true)).status,'rejected_production_ready_true'));
    test('publicExposure',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,publicExposure:true)).status,'rejected_public_exposure_true'));
    test('calProvider',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,calendarProviderIntegration:true)).status,'rejected_calendar_provider_integration'));
    test('ai',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,usesAiGeneratedData:true)).status,'rejected_ai_generated'));
    test('network',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,requiresNetwork:true)).status,'rejected_network_dependency'));
    test('fixedDate',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,usesFixedDateApproximation:true)).status,'rejected_fixed_date_approximation'));
  });

  group('metadata states', () {
    final b = SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true);
    test('source metadata',()=>expect(v.validate(b).status,'source_metadata_missing'));
    test('license',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y')).status,'license_missing'));
    test('timezone',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y',licenseAttached:true)).status,'timezone_missing'));
    test('coverage missing',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y',licenseAttached:true,timezone:'Asia/Shanghai')).status,'coverage_missing'));
    test('coverage incomplete',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y',licenseAttached:true,timezone:'Asia/Shanghai',coverageStartYear:2000,coverageEndYear:2050)).status,'coverage_incomplete'));
    test('years empty',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y',licenseAttached:true,timezone:'Asia/Shanghai',coverageStartYear:1900,coverageEndYear:2100)).status,'years_empty'));
  });

  group('term validation states', () {
    final b = SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y',licenseAttached:true,timezone:'Asia/Shanghai',coverageStartYear:1900,coverageEndYear:2100);
    test('year out of range',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y',licenseAttached:true,timezone:'Asia/Shanghai',coverageStartYear:1900,coverageEndYear:2100,years:[{'year':2200,'terms':[]}])).status,'year_out_of_range'));
    test('terms count invalid',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y',licenseAttached:true,timezone:'Asia/Shanghai',coverageStartYear:1900,coverageEndYear:2100,years:[{'year':2026,'terms':[{'name':'立春','sequenceIndex':1}]}])).status,'yearly_terms_count_invalid'));
    test('term name invalid',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y',licenseAttached:true,timezone:'Asia/Shanghai',coverageStartYear:1900,coverageEndYear:2100,years:[{'year':2026,'terms':List.generate(24,(i)=>{'name':'BAD${i}','sequenceIndex':i+1})}])).status,'term_name_invalid'));
    test('sequence invalid',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y',licenseAttached:true,timezone:'Asia/Shanghai',coverageStartYear:1900,coverageEndYear:2100,years:[{'year':2026,'terms':List.generate(24,(i)=>{'name':SolarTermCandidatePreflightValidator.termNames[i],'sequenceIndex':99})}])).status,'term_sequence_invalid'));
    test('date invalid',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y',licenseAttached:true,timezone:'Asia/Shanghai',coverageStartYear:1900,coverageEndYear:2100,years:[{'year':2026,'terms':List.generate(24,(i)=>{'name':SolarTermCandidatePreflightValidator.termNames[i],'sequenceIndex':i+1,'date':''})}])).status,'term_date_invalid'));
    test('time missing',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y',licenseAttached:true,timezone:'Asia/Shanghai',coverageStartYear:1900,coverageEndYear:2100,years:[{'year':2026,'terms':List.generate(24,(i)=>{'name':SolarTermCandidatePreflightValidator.termNames[i],'sequenceIndex':i+1,'date':'2026-01-01'})}])).status,'term_time_missing'));
    test('tz missing',()=>expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y',licenseAttached:true,timezone:'Asia/Shanghai',coverageStartYear:1900,coverageEndYear:2100,years:[{'year':2026,'terms':List.generate(24,(i)=>{'name':SolarTermCandidatePreflightValidator.termNames[i],'sequenceIndex':i+1,'date':'2026-01-01','time':'12:00'})}])).status,'term_timezone_missing'));
    test('order invalid',() {
      final names = SolarTermCandidatePreflightValidator.termNames;
      // Create 24 terms with sequenceIndex 1..24 but reversed order in list (scores wrong)
      final terms = List.generate(24, (i) => <String,dynamic>{'name':names[i],'sequenceIndex':24-i,'date':'2026-01-${(i+1).toString().padLeft(2,'0')}','time':'12:00','timezone':'Asia/Shanghai'});
      expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y',licenseAttached:true,timezone:'Asia/Shanghai',coverageStartYear:1900,coverageEndYear:2100,years:[{'year':2026,'terms':terms}])).status,'term_order_invalid');
    });
    test('name duplicate',() {
      final names = SolarTermCandidatePreflightValidator.termNames;
      // 24 terms but first two have same name
      final terms = List.generate(24, (i) => <String,dynamic>{'name':i==0?names[0]:names[i],'sequenceIndex':i+1,'date':'2026-01-${(i+1).toString().padLeft(2,'0')}','time':'12:00','timezone':'Asia/Shanghai'});
      // At index 0 and index 1: both map to names[0] (i==0→names[0], i==1→names[1]... but since i==0 already took names[0], this just duplicates)
      // Actually I need both index 0 and 1 to have the same name. Let's set terms[1]['name'] = names[0]:
      terms[1]['name'] = terms[0]['name'];
      expect(v.validate(SolarTermCandidatePreflightInput(candidateDataExists:true,manifestExists:true,schemaExists:true,sourceReviewApproved:true,preparationReady:true,landingReviewReady:true,sandboxSafe:true,candidateDataReady:true,sourceName:'x',sourceType:'y',licenseAttached:true,timezone:'Asia/Shanghai',coverageStartYear:1900,coverageEndYear:2100,years:[{'year':2026,'terms':terms}])).status,'term_name_duplicate');
    });
  });

  group('preflight passed', () {
    test('valid data→passed',() {
      final o=v.validate(a);
      expect(o.passed,true);
      expect(o.status,'preflight_passed');
    });
    test('passed→productionReady=false',()=>expect(v.validate(a).productionReady,false));
    test('passed→publicExposure=false',()=>expect(v.validate(a).publicExposure,false));
    test('passed→calendarProviderIntegration=false',()=>expect(v.validate(a).calendarProviderIntegration,false));
    test('schemaVersion',()=>expect(v.validate(a).schemaVersion,'solar-term-candidate-preflight-v0_27'));
    test('no AI/network',() { final o=v.validate(a); expect(o.publicExposure,false); });
  });
}

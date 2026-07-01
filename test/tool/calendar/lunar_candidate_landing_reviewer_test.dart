import 'package:flutter_test/flutter_test.dart';
import '../../../../tool/calendar/lunar_candidate_landing_reviewer.dart';

LunarCandidateLandingReviewInput _base() => LunarCandidateLandingReviewInput(
  sourceName:'test',sourceUrl:'x',license:'public',
  reviewStatus:'approved_for_candidate_preparation',reviewScore:95,
  preparationStatus:'ready_for_import_review',
  rawDataProvided:true,rawDataTraceable:true,
  normalizerPassed:true,candidateDraftExists:true,candidateProductionReadyFalse:true,
  candidateSchemaValid:true,candidateCovers1900To2100:true,candidateSupportsLeapMonth:true,
  candidateIncludesMonthDays:true,candidateIncludesLunarNewYearGregorian:true,
  candidateSourceComplete:true,landingPrecheckPassed:true,
  sandboxPassed:true,preflightPassed:true,validatorPassed:true,
  crossCheckPassed:true,manualReviewPassed:true,
);

void main(){
  final r=LunarCandidateLandingReviewer();

  group('review + prep gates',(){
    test('empty review→review_report_missing',(){expect(r.review(LunarCandidateLandingReviewInput()).status,'review_report_missing');});
    test('empty prep→preparation_report_missing',(){expect(r.review(_base().copyWith(preparationStatus:'')).status,'preparation_report_missing');});
    test('not approved→source_not_approved',(){expect(r.review(_base().copyWith(reviewStatus:'rejected')).status,'source_not_approved');});
    test('score<90→source_not_approved',(){expect(r.review(_base().copyWith(reviewScore:85)).status,'source_not_approved');});
    test('hardReject→source_not_approved',(){expect(r.review(_base().copyWith(hardRejectReasons:['no_license'])).status,'source_not_approved');});
    test('prep not ready→preparation_not_ready',(){expect(r.review(_base().copyWith(preparationStatus:'raw_data_required')).status,'preparation_not_ready');});
  });

  group('raw data gates',(){
    test('not provided→raw_data_missing',(){expect(r.review(_base().copyWith(rawDataProvided:false)).status,'raw_data_missing');});
    test('not traceable→raw_data_rejected',(){expect(r.review(_base().copyWith(rawDataTraceable:false)).status,'raw_data_rejected');});
    for(final m in ['aiGenerated','mock','fake','random','hash','fromRuntimeApi']){
      test('$m→raw_data_rejected',(){
        final input=_base().copyWith('rawData${m[0].toUpperCase()+m.substring(1)}':true);
        expect(r.review(input).status,'raw_data_rejected');
      });
    }
  });

  group('step gates',(){
    test('normalizer fail→normalization_failed',(){expect(r.review(_base().copyWith(normalizerPassed:false)).status,'normalization_failed');});
    test('candidate prodReady true→landing_precheck_failed',(){expect(r.review(_base().copyWith(candidateProductionReadyFalse:false)).status,'landing_precheck_failed');});
    test('schema invalid→landing_precheck_failed',(){expect(r.review(_base().copyWith(candidateSchemaValid:false)).status,'landing_precheck_failed');});
    test('no 1900-2100→landing_precheck_failed',(){expect(r.review(_base().copyWith(candidateCovers1900To2100:false)).status,'landing_precheck_failed');});
    test('no leap→landing_precheck_failed',(){expect(r.review(_base().copyWith(candidateSupportsLeapMonth:false)).status,'landing_precheck_failed');});
    test('no month days→landing_precheck_failed',(){expect(r.review(_base().copyWith(candidateIncludesMonthDays:false)).status,'landing_precheck_failed');});
    test('no spring→landing_precheck_failed',(){expect(r.review(_base().copyWith(candidateIncludesLunarNewYearGregorian:false)).status,'landing_precheck_failed');});
    test('source incomplete→landing_precheck_failed',(){expect(r.review(_base().copyWith(candidateSourceComplete:false)).status,'landing_precheck_failed');});
    test('sandbox fail→sandbox_failed',(){expect(r.review(_base().copyWith(sandboxPassed:false)).status,'sandbox_failed');});
    test('preflight fail→preflight_failed',(){expect(r.review(_base().copyWith(preflightPassed:false)).status,'preflight_failed');});
    test('validator fail→validator_failed',(){expect(r.review(_base().copyWith(validatorPassed:false)).status,'validator_failed');});
    test('crossCheck fail→cross_check_failed',(){expect(r.review(_base().copyWith(crossCheckPassed:false)).status,'cross_check_failed');});
    test('manual review fail→manual_review_required',(){expect(r.review(_base().copyWith(manualReviewPassed:false)).status,'manual_review_required');});
    test('all pass→ready_for_production_review',(){final rp=r.review(_base());expect(rp.status,'ready_for_production_review');expect(rp.readyForProductionReview,true);});
  });

  group('production boundaries',(){
    test('ready→no lunar_data.json',(){expect(r.review(_base()).lunarDataJsonAllowed,false);});
    test('ready→no productionReady',(){expect(r.review(_base()).productionReadyAllowed,false);});
    test('ready→no supportsLunarDate',(){expect(r.review(_base()).supportsLunarDateAllowed,false);});
    test('debug has capabilityImpact',(){final d=r.buildDebugJson(_base());expect(d['capabilityImpact']['productionReady'],false);expect(d['capabilityImpact']['supportsLunarDate'],false);});
  });
}

extension on LunarCandidateLandingReviewInput{
  LunarCandidateLandingReviewInput copyWith({
    String? reviewStatus,preparationStatus;int? reviewScore;List<String>? hardRejectReasons;
    bool? rawDataProvided,rawDataTraceable,rawDataAiGenerated,rawDataMock,rawDataFake,rawDataRandom,rawDataHash,rawDataFromRuntimeApi;
    bool? normalizerPassed,candidateProductionReadyFalse,candidateSchemaValid,candidateCovers1900To2100,candidateSupportsLeapMonth;
    bool? candidateIncludesMonthDays,candidateIncludesLunarNewYearGregorian,candidateSourceComplete;
    bool? sandboxPassed,preflightPassed,validatorPassed,crossCheckPassed,manualReviewPassed;
  })=>LunarCandidateLandingReviewInput(
    sourceName:sourceName,sourceUrl:sourceUrl,license:license,
    reviewStatus:reviewStatus??this.reviewStatus,preparationStatus:preparationStatus??this.preparationStatus,
    reviewScore:reviewScore??this.reviewScore,hardRejectReasons:hardRejectReasons??this.hardRejectReasons,
    rawDataProvided:rawDataProvided??this.rawDataProvided,rawDataTraceable:rawDataTraceable??this.rawDataTraceable,
    rawDataAiGenerated:rawDataAiGenerated??this.rawDataAiGenerated,rawDataMock:rawDataMock??this.rawDataMock,
    rawDataFake:rawDataFake??this.rawDataFake,rawDataRandom:rawDataRandom??this.rawDataRandom,
    rawDataHash:rawDataHash??this.rawDataHash,rawDataFromRuntimeApi:rawDataFromRuntimeApi??this.rawDataFromRuntimeApi,
    normalizerPassed:normalizerPassed??this.normalizerPassed,candidateDraftExists:candidateDraftExists,
    candidateProductionReadyFalse:candidateProductionReadyFalse??this.candidateProductionReadyFalse,
    candidateSchemaValid:candidateSchemaValid??this.candidateSchemaValid,
    candidateCovers1900To2100:candidateCovers1900To2100??this.candidateCovers1900To2100,
    candidateSupportsLeapMonth:candidateSupportsLeapMonth??this.candidateSupportsLeapMonth,
    candidateIncludesMonthDays:candidateIncludesMonthDays??this.candidateIncludesMonthDays,
    candidateIncludesLunarNewYearGregorian:candidateIncludesLunarNewYearGregorian??this.candidateIncludesLunarNewYearGregorian,
    candidateSourceComplete:candidateSourceComplete??this.candidateSourceComplete,
    landingPrecheckPassed:landingPrecheckPassed,
    sandboxPassed:sandboxPassed??this.sandboxPassed,preflightPassed:preflightPassed??this.preflightPassed,
    validatorPassed:validatorPassed??this.validatorPassed,crossCheckPassed:crossCheckPassed??this.crossCheckPassed,
    manualReviewPassed:manualReviewPassed??this.manualReviewPassed,
  );
}

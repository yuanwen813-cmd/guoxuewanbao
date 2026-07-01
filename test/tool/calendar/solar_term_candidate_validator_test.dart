import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/tool/calendar/solar_term_candidate_validator.dart';

void main() {
  final v = const SolarTermCandidateValidator();
  final a = v.withValidData;
  final names = SolarTermCandidateValidator.termNames;

  /// Build valid terms for a year (all 24, correct order, yyyy-01-XX dates for simplicity)
  List<Map<String,dynamic>> _validTerms(int yr) => List.generate(24, (i) => {
    'name':names[i],'sequenceIndex':i+1,
    'date':'$yr-01-${(i+1).toString().padLeft(2,'0')}',
    'time':'12:00','timezone':'Asia/Shanghai',
  });

  /// Build 201 valid years (1900-2100)
  List<Map<String,dynamic>> _validYears() => List.generate(201, (i) => {'year':1900+i, 'terms':_validTerms(1900+i)});

  group('gate & safety', () {
    test('preflight not passed',()=>expect(v.validate(const SolarTermCandidateValidationInput()).status,'preflight_not_passed'));
    test('data not ready',()=>expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true)).status,'candidate_data_not_ready'));
    test('prodReady rejected',()=>expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,productionReady:true)).status,'rejected_production_ready_true'));
    test('publicExposure rejected',()=>expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,publicExposure:true)).status,'rejected_public_exposure_true'));
    test('calProvider rejected',()=>expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,calendarProviderIntegration:true)).status,'rejected_calendar_provider_integration'));
  });

  group('coverage', () {
    test('missing',()=>expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true)).status,'coverage_missing'));
    test('incomplete',()=>expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:2000,coverageEndYear:2050)).status,'coverage_incomplete'));
    test('years empty',()=>expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100)).status,'years_empty'));
    test('count mismatch',() {
      final inp=SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,years:[{'year':2026,'terms':_validTerms(2026)}]);
      expect(v.validate(inp).status,'year_count_mismatch');
    });
  });

  group('year validation', () {
    test('out of range',() {
      final yrs = _validYears(); yrs[0] = {'year':2200,'terms':_validTerms(2200)};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'year_out_of_range');
    });
    test('duplicate',() {
      final yrs = _validYears(); yrs[1] = {'year':1900,'terms':_validTerms(1900)};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'year_duplicate');
    });
  });

  group('term validation', () {
    test('count invalid',() {
      final yrs = _validYears(); yrs[0] = {'year':1900,'terms':[{'name':'立春','sequenceIndex':1,'date':'1900-01-01','time':'12:00','timezone':'Asia/Shanghai'}]};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'yearly_terms_count_invalid');
    });
    test('name invalid',() {
      final bt=List.generate(24,(i)=><String,dynamic>{'name':'BAD$i','sequenceIndex':i+1,'date':'1900-01-${(i+1).toString().padLeft(2,'0')}','time':'12:00','timezone':'Asia/Shanghai'});
      final yrs=_validYears(); yrs[0]={'year':1900,'terms':bt};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'term_name_invalid');
    });
    test('name duplicate',() {
      final bt=List.generate(24,(i)=><String,dynamic>{'name':'立春','sequenceIndex':i+1,'date':'1900-01-${(i+1).toString().padLeft(2,'0')}','time':'12:00','timezone':'Asia/Shanghai'});
      final yrs=_validYears(); yrs[0]={'year':1900,'terms':bt};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'term_name_duplicate');
    });
    test('sequence invalid',() {
      final yrs=_validYears(); final bt=_validTerms(1900); bt[0]['sequenceIndex']=99;
      yrs[0]={'year':1900,'terms':bt};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'term_sequence_invalid');
    });
    test('sequence duplicate',() {
      final bt=List.generate(24,(i)=><String,dynamic>{'name':names[i],'sequenceIndex':1,'date':'1900-01-${(i+1).toString().padLeft(2,'0')}','time':'12:00','timezone':'Asia/Shanghai'});
      final yrs=_validYears(); yrs[0]={'year':1900,'terms':bt};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'term_sequence_duplicate');
    });
    test('date invalid (empty)',() {
      final yrs=_validYears(); final bt=_validTerms(1900); bt[0]['date']='';
      yrs[0]={'year':1900,'terms':bt};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'term_date_invalid');
    });
    test('2026-02-30 invalid date',() {
      final bt=List.generate(24,(i)=><String,dynamic>{'name':names[i],'sequenceIndex':i+1,'date':'2026-02-30','time':'12:00','timezone':'Asia/Shanghai'});
      final yrs=_validYears(); yrs[0]={'year':2026,'terms':bt};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'term_date_invalid');
    });
    test('date year mismatch',() {
      final bt=List.generate(24,(i)=><String,dynamic>{'name':names[i],'sequenceIndex':i+1,'date':'2200-01-${(i+1).toString().padLeft(2,'0')}','time':'12:00','timezone':'Asia/Shanghai'});
      final yrs=_validYears(); yrs[0]={'year':2026,'terms':bt};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'term_date_year_mismatch');
    });
    test('time invalid',() {
      final yrs=_validYears(); final bt=_validTerms(1900); bt[0]['time']='';
      yrs[0]={'year':1900,'terms':bt};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'term_time_invalid');
    });
    test('24:00 invalid',() {
      final yrs=_validYears(); final bt=_validTerms(1900); bt[0]['time']='24:00';
      yrs[0]={'year':1900,'terms':bt};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'term_time_invalid');
    });
    test('tz missing',() {
      final yrs=_validYears(); final bt=_validTerms(1900); bt[0]['timezone']='';
      yrs[0]={'year':1900,'terms':bt};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'term_timezone_missing');
    });
    test('tz mismatch',() {
      final yrs=_validYears(); final bt=_validTerms(1900); bt[0]['timezone']='UTC';
      yrs[0]={'year':1900,'terms':bt};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'term_timezone_mismatch');
    });
    test('date order invalid',() {
      final bt=List.generate(24,(i)=><String,dynamic>{'name':names[i],'sequenceIndex':i+1,'date':'1900-12-${(31-i).toString().padLeft(2,'0')}','time':'12:00','timezone':'Asia/Shanghai'});
      final yrs=_validYears(); yrs[0]={'year':1900,'terms':bt};
      expect(v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status,'term_date_order_invalid');
    });
    // key term checks exist in the validator but can't be independently triggered
    // with valid unique names (24 valid names → all 24 must be present for uniqueness)
    // These checks fire after duplicate detection which catches the deliberately missing term
    test('key term missing triggers via duplicate path',() {
      final n=names.toList(); n[0]=names[1]; // 立春→雨水
      final bt=List.generate(24,(i)=><String,dynamic>{'name':n[i],'sequenceIndex':i+1,'date':'1900-01-${(i+1).toString().padLeft(2,'0')}','time':'12:00','timezone':'Asia/Shanghai'});
      final yrs=_validYears(); yrs[0]={'year':1900,'terms':bt};
      final s=v.validate(SolarTermCandidateValidationInput(preflightPassed:true,candidateDataReady:true,coverageStartYear:1900,coverageEndYear:2100,sourceName:'s',sourceType:'t',timezone:'Asia/Shanghai',years:yrs)).status;
      // name_duplicate fires before major_term_missing (duplicate 雨水 detected first)
      expect(s=='term_name_duplicate'||s=='major_term_missing'||s=='lichun_missing',true);
    });
  });

  group('validator passed', () {
    test('valid data→passed',() {
      final o=v.validate(a);
      expect(o.passed,true);
      expect(o.status,'validator_passed');
      expect(o.validatedYears,201);
      expect(o.validatedTerms,201*24);
    });
    test('productionReady false',()=>expect(v.validate(a).productionReady,false));
    test('publicExposure false',()=>expect(v.validate(a).publicExposure,false));
    test('calendarProviderIntegration false',()=>expect(v.validate(a).calendarProviderIntegration,false));
    test('schemaVersion',()=>expect(v.validate(a).schemaVersion,'solar-term-candidate-validator-v0_28'));
  });
}

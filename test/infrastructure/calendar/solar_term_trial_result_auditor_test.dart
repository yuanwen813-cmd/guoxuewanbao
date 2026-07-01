import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_trial_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_trial_result_auditor.dart';

void main() {
  final auditor = const SolarTermTrialResultAuditor();

  group('compliant result → audit_passed', () {
    test('unavailable passes',() {
      final o=auditor.audit(SolarTermTrialResult.unavailable);
      expect(o.passed,true); expect(o.status,'audit_passed');
    });
    test('trial_only passes',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',termName:'立春');
      expect(auditor.audit(r).passed,true);
    });
    test('blocked passes',() {
      expect(auditor.audit(SolarTermTrialResult.blocked).passed,true);
    });
    test('none passes',() {
      expect(auditor.audit(const SolarTermTrialResult(available:false,status:'none')).passed,true);
    });
  });

  group('safety flag violations → audit_failed', () {
    test('productionReady=true',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',productionReady:true);
      expect(auditor.audit(r).passed,false);
    });
    test('publicExposure=true',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',publicExposure:true);
      expect(auditor.audit(r).passed,false);
    });
    test('calendarProviderIntegration=true',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',calendarProviderIntegration:true);
      expect(auditor.audit(r).passed,false);
    });
    test('displayAllowed=true',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',displayAllowed:true);
      expect(auditor.audit(r).passed,false);
    });
    test('shareAllowed=true',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',shareAllowed:true);
      expect(auditor.audit(r).passed,false);
    });
    test('snapshotAllowed=true',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',snapshotAllowed:true);
      expect(auditor.audit(r).passed,false);
    });
    test('ganzhiDependencyAllowed=true',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',ganzhiDependencyAllowed:true);
      expect(auditor.audit(r).passed,false);
    });
    test('clashDependencyAllowed=true',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',clashDependencyAllowed:true);
      expect(auditor.audit(r).passed,false);
    });
  });

  group('source violations → audit_failed', () {
    test('contains production',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',source:'production_data');
      expect(auditor.audit(r).passed,false);
    });
    test('contains public',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',source:'public_source');
      expect(auditor.audit(r).passed,false);
    });
    test('missing trial/candidate',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',source:'unknown_source');
      expect(auditor.audit(r).passed,false);
    });
    test('contains official_enabled',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',source:'official_enabled_v1');
      expect(auditor.audit(r).passed,false);
    });
  });

  group('status violations', () {
    test('available but status not trial_only',() {
      final r=SolarTermTrialResult(available:true,status:'production');
      expect(auditor.audit(r).passed,false);
    });
    test('unavailable but status illegal',() {
      final r=SolarTermTrialResult(available:false,status:'production');
      expect(auditor.audit(r).passed,false);
    });
  });

  group('debug & output', () {
    test('buildDebugJson schemaVersion',() {
      expect(auditor.buildDebugJson()['schemaVersion'],'solar-term-trial-result-audit-debug-v0_33');
    });
    test('output toJson contains violations',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',displayAllowed:true);
      final j=auditor.audit(r).toJson();
      expect(j['passed'],false); expect((j['violations'] as List).isNotEmpty,true);
    });
    test('output contains result',() {
      final j=auditor.audit(SolarTermTrialResult.unavailable).toJson();
      expect(j.containsKey('result'),true);
    });
  });
}

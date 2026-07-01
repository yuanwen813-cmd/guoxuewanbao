import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/tool/calendar/solar_term_trial_integration_planner.dart';

void main() {
  final p = const SolarTermTrialIntegrationPlanner();
  final a = SolarTermTrialIntegrationPlanner.allApproved;

  group('gate', () {
    test('manual review',()=>expect(p.plan(const SolarTermTrialIntegrationInput()).status,'manual_review_not_passed'));
    test('not ready',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true)).status,'not_ready_for_trial_integration'));
    test('data missing',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true)).status,'candidate_data_missing'));
    test('data not ready',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true)).status,'candidate_data_not_ready'));
    test('sandbox',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true)).status,'sandbox_not_safe'));
    test('preflight',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true)).status,'preflight_not_passed'));
    test('validator',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true)).status,'validator_not_passed'));
    test('crossCheck',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true,validatorPassed:true)).status,'cross_check_not_passed'));
  });

  group('safety', () {
    final b = SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true,validatorPassed:true,crossCheckPassed:true);
    test('prodReady',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true,validatorPassed:true,crossCheckPassed:true,productionReady:true)).status,'rejected_production_ready_true'));
    test('pubExp',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true,validatorPassed:true,crossCheckPassed:true,publicExposure:true)).status,'rejected_public_exposure_true'));
    test('calProv',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true,validatorPassed:true,crossCheckPassed:true,calendarProviderIntegration:true)).status,'rejected_calendar_provider_integration'));
  });

  group('trial constraints', () {
    final b = SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true,validatorPassed:true,crossCheckPassed:true);
    test('not requested',()=>expect(p.plan(b).status,'trial_mode_not_requested'));
    test('not readOnly',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true,validatorPassed:true,crossCheckPassed:true,trialModeRequested:true)).status,'trial_mode_not_read_only'));
    test('not debugOnly',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true,validatorPassed:true,crossCheckPassed:true,trialModeRequested:true,trialModeReadOnly:true)).status,'trial_debug_only_not_confirmed'));
    test('pageDisplay rejected',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true,validatorPassed:true,crossCheckPassed:true,trialModeRequested:true,trialModeReadOnly:true,trialDebugOnly:true,trialPageDisplay:true)).status,'rejected_trial_page_display'));
    test('shareDisplay rejected',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true,validatorPassed:true,crossCheckPassed:true,trialModeRequested:true,trialModeReadOnly:true,trialDebugOnly:true,trialShareDisplay:true)).status,'rejected_trial_share_display'));
    test('snapshotWrite rejected',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true,validatorPassed:true,crossCheckPassed:true,trialModeRequested:true,trialModeReadOnly:true,trialDebugOnly:true,trialSnapshotWrite:true)).status,'rejected_trial_snapshot_write'));
    test('ganzhi rejected',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true,validatorPassed:true,crossCheckPassed:true,trialModeRequested:true,trialModeReadOnly:true,trialDebugOnly:true,trialGanzhiDependency:true)).status,'rejected_trial_ganzhi_dependency'));
    test('clash rejected',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true,validatorPassed:true,crossCheckPassed:true,trialModeRequested:true,trialModeReadOnly:true,trialDebugOnly:true,trialClashDependency:true)).status,'rejected_trial_clash_dependency'));
    test('rollback missing',()=>expect(p.plan(SolarTermTrialIntegrationInput(manualReviewPassed:true,readyForTrialIntegration:true,candidateDataExists:true,candidateDataReady:true,sandboxSafe:true,preflightPassed:true,validatorPassed:true,crossCheckPassed:true,trialModeRequested:true,trialModeReadOnly:true,trialDebugOnly:true)).status,'rollback_plan_missing'));
  });

  group('passed', () {
    test('all→ready',() { final o=p.plan(a); expect(o.readyForTrialDesign,true); expect(o.status,'ready_for_trial_design'); });
    test('pubExp false',()=>expect(p.plan(a).readyForPublicExposure,false));
    test('prodReady false',()=>expect(p.plan(a).productionReady,false));
    test('pubExp2 false',()=>expect(p.plan(a).publicExposure,false));
    test('calProv false',()=>expect(p.plan(a).calendarProviderIntegration,false));
    test('schemaVersion',()=>expect(p.plan(a).schemaVersion,'solar-term-trial-integration-v0_31'));
  });
}

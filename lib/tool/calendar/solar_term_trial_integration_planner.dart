/// 节气试运行接入设计规划器 v0.31
///
/// 在 manual_review_passed 后，设计试运行接入方案。
/// ready_for_trial_design 不代表公开启用。
/// productionReady/publicExposure/calendarProviderIntegration 仍为 false。

enum TrialIntegrationStatus {
  not_started, manual_review_not_passed, not_ready_for_trial_integration,
  candidate_data_missing, candidate_data_not_ready,
  sandbox_not_safe, preflight_not_passed, validator_not_passed, cross_check_not_passed,
  rejected_production_ready_true, rejected_public_exposure_true, rejected_calendar_provider_integration,
  trial_mode_not_requested, trial_mode_not_read_only, trial_debug_only_not_confirmed,
  rejected_trial_page_display, rejected_trial_share_display, rejected_trial_snapshot_write,
  rejected_trial_ganzhi_dependency, rejected_trial_clash_dependency,
  rollback_plan_missing,
  ready_for_trial_design,
}

const tiLabels = <TrialIntegrationStatus, String>{
  TrialIntegrationStatus.not_started: 'not_started',
  TrialIntegrationStatus.manual_review_not_passed: 'manual_review_not_passed',
  TrialIntegrationStatus.not_ready_for_trial_integration: 'not_ready_for_trial_integration',
  TrialIntegrationStatus.candidate_data_missing: 'candidate_data_missing',
  TrialIntegrationStatus.candidate_data_not_ready: 'candidate_data_not_ready',
  TrialIntegrationStatus.sandbox_not_safe: 'sandbox_not_safe',
  TrialIntegrationStatus.preflight_not_passed: 'preflight_not_passed',
  TrialIntegrationStatus.validator_not_passed: 'validator_not_passed',
  TrialIntegrationStatus.cross_check_not_passed: 'cross_check_not_passed',
  TrialIntegrationStatus.rejected_production_ready_true: 'rejected_production_ready_true',
  TrialIntegrationStatus.rejected_public_exposure_true: 'rejected_public_exposure_true',
  TrialIntegrationStatus.rejected_calendar_provider_integration: 'rejected_calendar_provider_integration',
  TrialIntegrationStatus.trial_mode_not_requested: 'trial_mode_not_requested',
  TrialIntegrationStatus.trial_mode_not_read_only: 'trial_mode_not_read_only',
  TrialIntegrationStatus.trial_debug_only_not_confirmed: 'trial_debug_only_not_confirmed',
  TrialIntegrationStatus.rejected_trial_page_display: 'rejected_trial_page_display',
  TrialIntegrationStatus.rejected_trial_share_display: 'rejected_trial_share_display',
  TrialIntegrationStatus.rejected_trial_snapshot_write: 'rejected_trial_snapshot_write',
  TrialIntegrationStatus.rejected_trial_ganzhi_dependency: 'rejected_trial_ganzhi_dependency',
  TrialIntegrationStatus.rejected_trial_clash_dependency: 'rejected_trial_clash_dependency',
  TrialIntegrationStatus.rollback_plan_missing: 'rollback_plan_missing',
  TrialIntegrationStatus.ready_for_trial_design: 'ready_for_trial_design',
};

class SolarTermTrialIntegrationInput {
  final bool manualReviewPassed; final bool readyForTrialIntegration;
  final bool candidateDataExists; final bool candidateDataReady;
  final bool sandboxSafe; final bool preflightPassed; final bool validatorPassed; final bool crossCheckPassed;
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;
  final bool trialModeRequested; final bool trialModeReadOnly; final bool trialDebugOnly;
  final bool trialPageDisplay; final bool trialShareDisplay; final bool trialSnapshotWrite;
  final bool trialGanzhiDependency; final bool trialClashDependency;
  final bool rollbackPlanExists;
  final List<String> notes;

  const SolarTermTrialIntegrationInput({
    this.manualReviewPassed=false, this.readyForTrialIntegration=false,
    this.candidateDataExists=false, this.candidateDataReady=false,
    this.sandboxSafe=false, this.preflightPassed=false, this.validatorPassed=false, this.crossCheckPassed=false,
    this.productionReady=false, this.publicExposure=false, this.calendarProviderIntegration=false,
    this.trialModeRequested=false, this.trialModeReadOnly=false, this.trialDebugOnly=false,
    this.trialPageDisplay=false, this.trialShareDisplay=false, this.trialSnapshotWrite=false,
    this.trialGanzhiDependency=false, this.trialClashDependency=false,
    this.rollbackPlanExists=false,
    this.notes=const [],
  });
}

class SolarTermTrialIntegrationOutput {
  final String schemaVersion; final String status; final bool readyForTrialDesign; final bool readyForPublicExposure;
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;
  final List<String> blockingReasons; final List<String> warnings; final List<String> nextActions;

  const SolarTermTrialIntegrationOutput({
    this.schemaVersion='solar-term-trial-integration-v0_31',
    required this.status, required this.readyForTrialDesign, this.readyForPublicExposure=false,
    this.productionReady=false, this.publicExposure=false, this.calendarProviderIntegration=false,
    this.blockingReasons=const [], this.warnings=const [], this.nextActions=const [],
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion':schemaVersion,'status':status,'readyForTrialDesign':readyForTrialDesign,'readyForPublicExposure':readyForPublicExposure,
    'productionReady':productionReady,'publicExposure':publicExposure,'calendarProviderIntegration':calendarProviderIntegration,
    'blockingReasons':blockingReasons,'warnings':warnings,'nextActions':nextActions,
  };
}

class SolarTermTrialIntegrationPlanner {
  const SolarTermTrialIntegrationPlanner();

  static const allApproved = SolarTermTrialIntegrationInput(
    manualReviewPassed:true, readyForTrialIntegration:true,
    candidateDataExists:true, candidateDataReady:true,
    sandboxSafe:true, preflightPassed:true, validatorPassed:true, crossCheckPassed:true,
    productionReady:false, publicExposure:false, calendarProviderIntegration:false,
    trialModeRequested:true, trialModeReadOnly:true, trialDebugOnly:true,
    trialPageDisplay:false, trialShareDisplay:false, trialSnapshotWrite:false,
    trialGanzhiDependency:false, trialClashDependency:false,
    rollbackPlanExists:true,
  );

  TrialIntegrationStatus determineStatus(SolarTermTrialIntegrationInput i) {
    if(!i.manualReviewPassed) return TrialIntegrationStatus.manual_review_not_passed;
    if(!i.readyForTrialIntegration) return TrialIntegrationStatus.not_ready_for_trial_integration;
    if(!i.candidateDataExists) return TrialIntegrationStatus.candidate_data_missing;
    if(!i.candidateDataReady) return TrialIntegrationStatus.candidate_data_not_ready;
    if(!i.sandboxSafe) return TrialIntegrationStatus.sandbox_not_safe;
    if(!i.preflightPassed) return TrialIntegrationStatus.preflight_not_passed;
    if(!i.validatorPassed) return TrialIntegrationStatus.validator_not_passed;
    if(!i.crossCheckPassed) return TrialIntegrationStatus.cross_check_not_passed;
    if(i.productionReady) return TrialIntegrationStatus.rejected_production_ready_true;
    if(i.publicExposure) return TrialIntegrationStatus.rejected_public_exposure_true;
    if(i.calendarProviderIntegration) return TrialIntegrationStatus.rejected_calendar_provider_integration;
    if(!i.trialModeRequested) return TrialIntegrationStatus.trial_mode_not_requested;
    if(!i.trialModeReadOnly) return TrialIntegrationStatus.trial_mode_not_read_only;
    if(!i.trialDebugOnly) return TrialIntegrationStatus.trial_debug_only_not_confirmed;
    if(i.trialPageDisplay) return TrialIntegrationStatus.rejected_trial_page_display;
    if(i.trialShareDisplay) return TrialIntegrationStatus.rejected_trial_share_display;
    if(i.trialSnapshotWrite) return TrialIntegrationStatus.rejected_trial_snapshot_write;
    if(i.trialGanzhiDependency) return TrialIntegrationStatus.rejected_trial_ganzhi_dependency;
    if(i.trialClashDependency) return TrialIntegrationStatus.rejected_trial_clash_dependency;
    if(!i.rollbackPlanExists) return TrialIntegrationStatus.rollback_plan_missing;
    return TrialIntegrationStatus.ready_for_trial_design;
  }

  SolarTermTrialIntegrationOutput plan(SolarTermTrialIntegrationInput i) {
    final s=determineStatus(i); final p=s==TrialIntegrationStatus.ready_for_trial_design;
    final n=tiLabels[s]??'not_started';
    return SolarTermTrialIntegrationOutput(status:n,readyForTrialDesign:p,
      blockingReasons:p?[]:[n],
      nextActions:p?['试运行设计通过，可进入 Debug-only trial 阶段']:['修复阻塞原因: $n'],
    );
  }
}

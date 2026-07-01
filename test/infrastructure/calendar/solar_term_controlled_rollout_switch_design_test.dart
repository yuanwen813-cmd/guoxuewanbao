import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_controlled_rollout_switch_design.dart';

void main() {
  final sd = const SolarTermControlledRolloutSwitchDesign();

  SolarTermControlledRolloutSwitchResult _design(String review, {bool noGo=false, bool highRisk=false, bool killSwitch=true, bool rollback=true}) {
    return sd.design(reviewStatus: review, hasNoGoTriggered: noGo, hasHighRisk: highRisk, hasKillSwitch: killSwitch, hasRollbackPlan: rollback, sampleName: 'test', dateRange: 'v0.22-v0.42');
  }

  group('generation', () {
    test('can generate', () { final r=_design('review_frozen'); expect(r.schemaVersion, 'solar-term-controlled-rollout-switch-design-v0_42'); expect(r.sampleName, 'test'); });
    test('dateRange', () { expect(_design('review_frozen').dateRange, 'v0.22-v0.42'); });
  });

  group('switchDesignStatus', () {
    test('review blocked→blocked', () => expect(_design('blocked').switchDesignStatus, 'blocked'));
    test('review not_allowed→design_not_allowed', () => expect(_design('review_not_allowed').switchDesignStatus, 'design_not_allowed'));
    test('review ready_for_human→design_not_allowed', () => expect(_design('ready_for_human_approval').switchDesignStatus, 'design_not_allowed'));
    test('review frozen→switch_design_ready', () => expect(_design('review_frozen').switchDesignStatus, 'switch_design_ready'));
    test('noGo→blocked', () => expect(_design('review_frozen', noGo: true).switchDesignStatus, 'blocked'));
    test('highRisk→blocked', () => expect(_design('review_frozen', highRisk: true).switchDesignStatus, 'blocked'));
    test('no killSwitch→blocked', () => expect(_design('review_frozen', killSwitch: false).switchDesignStatus, 'blocked'));
    test('no rollback→blocked', () => expect(_design('review_frozen', rollback: false).switchDesignStatus, 'blocked'));
  });

  group('switchState', () {
    test('contains locked_off', () => expect(SolarTermControlledRolloutSwitchStates.all.contains('locked_off'), true));
    test('contains review_frozen', () => expect(SolarTermControlledRolloutSwitchStates.all.contains('review_frozen'), true));
    test('contains human_approved_pending', () => expect(SolarTermControlledRolloutSwitchStates.all.contains('human_approved_pending'), true));
    test('contains sandbox_ready', () => expect(SolarTermControlledRolloutSwitchStates.all.contains('sandbox_ready'), true));
    test('contains controlled_rollout_ready', () => expect(SolarTermControlledRolloutSwitchStates.all.contains('controlled_rollout_ready'), true));
    test('5 states', () => expect(SolarTermControlledRolloutSwitchStates.all.length, 5));
    test('review_frozen→sandbox_ready', () => expect(_design('review_frozen').switchState, 'sandbox_ready'));
    test('ready_for_human→human_approved_pending', () => expect(_design('ready_for_human_approval').switchState, 'human_approved_pending'));
  });

  group('rollout gates', () {
    final r = _design('review_frozen');
    final ids = r.rolloutGates.map((g) => g.id).toSet();
    test('reviewFrozenConfirmed', () => expect(ids.contains('reviewFrozenConfirmed'), true));
    test('humanApprovalConfirmed', () => expect(ids.contains('humanApprovalConfirmed'), true));
    test('noGoRulesClear', () => expect(ids.contains('noGoRulesClear'), true));
    test('rollbackPlanReady', () => expect(ids.contains('rollbackPlanReady'), true));
    test('killSwitchReady', () => expect(ids.contains('killSwitchReady'), true));
    test('calendarProviderGuardReady', () => expect(ids.contains('calendarProviderGuardReady'), true));
    test('pageDisplayGuardReady', () => expect(ids.contains('pageDisplayGuardReady'), true));
    test('shareExposureGuardReady', () => expect(ids.contains('shareExposureGuardReady'), true));
    test('snapshotWriteGuardReady', () => expect(ids.contains('snapshotWriteGuardReady'), true));
    test('finalReleaseApprovalRequired', () => expect(ids.contains('finalReleaseApprovalRequired'), true));
    test('15 gates', () => expect(r.rolloutGates.length, 15));
  });

  group('kill switch', () {
    final ks = _design('review_frozen').killSwitch;
    test('exists', () => expect(ks.killSwitchExists, true));
    test('defaultState locked_off', () => expect(ks.defaultState, 'locked_off'));
    test('canDisableCalendarProvider', () => expect(ks.canDisableCalendarProviderIntegration, true));
    test('canDisablePage', () => expect(ks.canDisablePageDisplay, true));
    test('canDisableShare', () => expect(ks.canDisableShareExposure, true));
    test('canDisableSnapshot', () => expect(ks.canDisableSnapshotWrite, true));
    test('canDisableGanzhi', () => expect(ks.canDisableGanzhiDependency, true));
    test('canDisableClash', () => expect(ks.canDisableClashDependency, true));
    test('rollbackToUnavailable', () => expect(ks.rollbackToUnavailable, true));
    test('preserveLunarAndZodiac', () => expect(ks.preserveLunarAndZodiac, true));
  });

  group('guard flags', () {
    final r = _design('review_frozen');
    test('productionReady', () => expect(r.guard.productionReady, false));
    test('publicExposure', () => expect(r.guard.publicExposure, false));
    test('calProvider', () => expect(r.guard.calendarProviderIntegration, false));
    test('display', () => expect(r.guard.displayAllowed, false));
    test('share', () => expect(r.guard.shareAllowed, false));
    test('snapshot', () => expect(r.guard.snapshotAllowed, false));
    test('ganzhi', () => expect(r.guard.ganzhiDependencyAllowed, false));
    test('clash', () => expect(r.guard.clashDependencyAllowed, false));
  });

  group('switch_design_ready guards', () {
    final r = _design('review_frozen');
    test('status is ready', () => expect(r.switchDesignStatus, 'switch_design_ready'));
    test('prodReady false', () => expect(r.guard.productionReady, false));
    test('pubExp false', () => expect(r.guard.publicExposure, false));
    test('calProv false', () => expect(r.guard.calendarProviderIntegration, false));
    test('display false', () => expect(r.guard.displayAllowed, false));
    test('share false', () => expect(r.guard.shareAllowed, false));
    test('snapshot false', () => expect(r.guard.snapshotAllowed, false));
  });

  group('result toJson', () {
    final j = _design('review_frozen').toJson();
    test('contains rolloutGates', () => expect(j.containsKey('rolloutGates'), true));
    test('contains killSwitch', () => expect(j.containsKey('killSwitch'), true));
    test('contains rollbackPlan', () => expect(j.containsKey('rollbackPlan'), true));
    test('rollbackPlan has 10 steps', () => expect((j['rollbackPlan'] as List).length, 10));
  });

  group('debug', () {
    test('schemaVersion', () => expect(sd.buildDebugJson()['schemaVersion'], 'solar-term-controlled-rollout-switch-design-debug-v0_42'));
    test('conclusionNote', () => expect(sd.buildDebugJson()['conclusionNote'], contains('controlled switch')));
  });
}

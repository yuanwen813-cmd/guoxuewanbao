import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_controlled_rollout_switch_sandbox.dart';

void main() {
  final sb = const SolarTermControlledRolloutSwitchSandbox();

  SolarTermControlledRolloutSwitchSandboxResult _run(String design, {bool gates = true, bool killSwitch = false, bool rollback = true, bool highRisk = false, String from = 'sandbox_ready', String to = 'controlled_rollout_ready'}) {
    return sb.validate(switchDesignStatus: design, initialSwitchState: from, targetSwitchState: to, allGatesPassed: gates, killSwitchTriggered: killSwitch, rollbackSuccessful: rollback, hasHighRisk: highRisk, sampleName: 'test', dateRange: 'v0.22-v0.43');
  }

  group('generation', () { test('can generate', () { final r=_run('switch_design_ready'); expect(r.schemaVersion, 'solar-term-controlled-rollout-switch-sandbox-v0_43'); expect(r.sampleName, 'test'); }); test('dateRange', () { expect(_run('switch_design_ready').dateRange, 'v0.22-v0.43'); }); });

  group('sandboxStatus', () {
    test('design blocked→blocked', () => expect(_run('blocked').sandboxStatus, 'blocked'));
    test('design not_allowed→sandbox_not_allowed', () => expect(_run('design_not_allowed').sandboxStatus, 'sandbox_not_allowed'));
    test('design ready + gates passed→sandbox_passed', () => expect(_run('switch_design_ready').sandboxStatus, 'sandbox_passed'));
    test('required gate failed→sandbox_failed', () => expect(_run('switch_design_ready', gates: false).sandboxStatus, 'sandbox_failed'));
    test('killSwitch→killed_and_locked_off', () => expect(_run('switch_design_ready', killSwitch: true).sandboxStatus, 'killed_and_locked_off'));
    test('rollback failed→sandbox_failed', () => expect(_run('switch_design_ready', rollback: false).sandboxStatus, 'sandbox_failed'));
    test('highRisk→blocked', () => expect(_run('switch_design_ready', highRisk: true).sandboxStatus, 'blocked'));
  });

  group('state transitions', () {
    final r = _run('switch_design_ready');
    test('contains sandbox_ready→controlled_rollout_ready', () => expect(r.stateTransitions.any((t) => t.from == 'sandbox_ready' && t.to == 'controlled_rollout_ready'), true));
    test('sandbox_ready→controlled_rollout_ready allowed', () => expect(r.stateTransitions.first.allowed, true));
    test('locked_off→review_frozen allowed', () {
      final r2 = sb.validate(switchDesignStatus: 'switch_design_ready', initialSwitchState: 'locked_off', targetSwitchState: 'review_frozen', allGatesPassed: true, killSwitchTriggered: false, rollbackSuccessful: true, hasHighRisk: false);
      expect(r2.stateTransitions.first.allowed, true);
    });
  });

  group('kill switch → locked_off', () {
    test('killSwitch→locked_off', () { final r=_run('switch_design_ready', killSwitch: true); expect(r.finalSwitchState, 'locked_off'); });
    test('killSwitch forcedLockedOff', () => expect(_run('switch_design_ready', killSwitch: true).killSwitchResult.forcedLockedOff, true));
    test('killSwitch calProvider disabled', () => expect(_run('switch_design_ready', killSwitch: true).killSwitchResult.calendarProviderDisabled, true));
    test('killSwitch page disabled', () => expect(_run('switch_design_ready', killSwitch: true).killSwitchResult.pageDisplayDisabled, true));
    test('killSwitch share disabled', () => expect(_run('switch_design_ready', killSwitch: true).killSwitchResult.shareExposureDisabled, true));
    test('killSwitch snapshot disabled', () => expect(_run('switch_design_ready', killSwitch: true).killSwitchResult.snapshotWriteDisabled, true));
    test('killSwitch lunarPreserved', () => expect(_run('switch_design_ready', killSwitch: true).killSwitchResult.lunarAndZodiacPreserved, true));
  });

  group('rollback result', () {
    final r = _run('switch_design_ready').rollbackResult;
    test('rollbackExecuted', () => expect(r.rollbackExecuted, true));
    test('restoredUnavailable', () => expect(r.restoredUnavailableState, true));
    test('calProviderUnavailable', () => expect(r.calendarProviderStillUnavailable, true));
    test('pageHidden', () => expect(r.pageDisplayStillHidden, true));
    test('shareHidden', () => expect(r.shareStillHidden, true));
    test('snapshotClean', () => expect(r.snapshotStillClean, true));
    test('lunarPreserved', () => expect(r.lunarPreserved, true));
    test('zodiacPreserved', () => expect(r.zodiacPreserved, true));
  });

  group('gate checks', () {
    final ids = _run('switch_design_ready').gateChecks.map((g) => g.id).toSet();
    test('reviewFrozenConfirmed', () => expect(ids.contains('reviewFrozenConfirmed'), true));
    test('humanApprovalConfirmed', () => expect(ids.contains('humanApprovalConfirmed'), true));
    test('noGoRulesClear', () => expect(ids.contains('noGoRulesClear'), true));
    test('rollbackPlanReady', () => expect(ids.contains('rollbackPlanReady'), true));
    test('killSwitchReady', () => expect(ids.contains('killSwitchReady'), true));
    test('calendarProviderGuardReady', () => expect(ids.contains('calendarProviderGuardReady'), true));
    test('pageDisplayGuardReady', () => expect(ids.contains('pageDisplayGuardReady'), true));
    test('shareExposureGuardReady', () => expect(ids.contains('shareExposureGuardReady'), true));
    test('snapshotWriteGuardReady', () => expect(ids.contains('snapshotWriteGuardReady'), true));
  });

  group('guard flags', () {
    final r = _run('switch_design_ready');
    test('productionReady', () => expect(r.guard.productionReady, false));
    test('publicExposure', () => expect(r.guard.publicExposure, false));
    test('calProvider', () => expect(r.guard.calendarProviderIntegration, false));
    test('display', () => expect(r.guard.displayAllowed, false));
    test('share', () => expect(r.guard.shareAllowed, false));
    test('snapshot', () => expect(r.guard.snapshotAllowed, false));
    test('ganzhi', () => expect(r.guard.ganzhiDependencyAllowed, false));
    test('clash', () => expect(r.guard.clashDependencyAllowed, false));
  });

  group('sandbox_passed guards', () {
    final r = _run('switch_design_ready');
    test('status is passed', () => expect(r.sandboxStatus, 'sandbox_passed'));
    test('prodReady false', () => expect(r.guard.productionReady, false));
    test('pubExp false', () => expect(r.guard.publicExposure, false));
    test('calProv false', () => expect(r.guard.calendarProviderIntegration, false));
  });

  group('killed_and_locked_off guards', () {
    final r = _run('switch_design_ready', killSwitch: true);
    test('status is killed', () => expect(r.sandboxStatus, 'killed_and_locked_off'));
    test('prodReady false', () => expect(r.guard.productionReady, false));
  });

  group('result toJson', () {
    final j = _run('switch_design_ready').toJson();
    test('contains stateTransitions', () => expect(j.containsKey('stateTransitions'), true));
    test('contains gateChecks', () => expect(j.containsKey('gateChecks'), true));
    test('contains killSwitchResult', () => expect(j.containsKey('killSwitchResult'), true));
    test('contains rollbackResult', () => expect(j.containsKey('rollbackResult'), true));
  });

  group('debug', () {
    test('schemaVersion', () => expect(sb.buildDebugJson()['schemaVersion'], 'solar-term-controlled-rollout-switch-sandbox-debug-v0_43'));
    test('conclusionNote', () => expect(sb.buildDebugJson()['conclusionNote'], contains('controlled switch sandbox')));
  });
}

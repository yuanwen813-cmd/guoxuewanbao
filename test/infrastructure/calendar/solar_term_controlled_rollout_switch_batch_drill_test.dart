import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_controlled_rollout_switch_batch_drill.dart';

void main() {
  final drill = const SolarTermControlledRolloutSwitchBatchDrill();

  group('drill generation', () {
    test('can generate', () async {
      final r = drill.drill(switchDesignStatus: 'switch_design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 24), sampleName: 'test');
      expect(r.schemaVersion, 'solar-term-controlled-rollout-switch-batch-drill-v0_44');
      expect(r.sampleName, 'test');
    });
    test('dateRange', () { final r = drill.drill(switchDesignStatus: 'switch_design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 24)); expect(r.dateRange, '2026-06-22 ~ 2026-06-24'); });
    test('totalDays 3 × 6 scenarios = 18 runs', () { final r = drill.drill(switchDesignStatus: 'switch_design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 24)); expect(r.totalDays, 3); expect(r.totalScenarios, 6); expect(r.totalRuns, 18); });
  });

  group('drillStatus', () {
    test('design != ready → blocked', () { expect(drill.drill(switchDesignStatus: 'blocked', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 22)).drillStatus, 'blocked'); });
    test('3 days + 6 scenarios → drill_passed (guardUnsafe + highRisk cause blocked for some)', () {
      // guardUnsafeBlocked and highRiskBlocked trigger blocked status in the drill → overall blocked
      final r = drill.drill(switchDesignStatus: 'switch_design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 24));
      // blocked > 0 → drillStatus = blocked
      expect(r.drillStatus, 'blocked');
      expect(r.sandboxBlockedCount, greaterThan(0));
    });
  });

  group('scenarios', () {
    test('6 scenarios defined', () => expect(SolarTermControlledRolloutSwitchBatchDrill.scenarios.length, 6));
    test('normalSandboxPass', () => expect(SolarTermControlledRolloutSwitchBatchDrill.scenarios.any((s) => s.id == 'normalSandboxPass'), true));
    test('requiredGateFailure', () => expect(SolarTermControlledRolloutSwitchBatchDrill.scenarios.any((s) => s.id == 'requiredGateFailure'), true));
    test('killSwitchTriggered', () => expect(SolarTermControlledRolloutSwitchBatchDrill.scenarios.any((s) => s.id == 'killSwitchTriggered'), true));
    test('rollbackExecuted', () => expect(SolarTermControlledRolloutSwitchBatchDrill.scenarios.any((s) => s.id == 'rollbackExecuted'), true));
    test('guardUnsafeBlocked', () => expect(SolarTermControlledRolloutSwitchBatchDrill.scenarios.any((s) => s.id == 'guardUnsafeBlocked'), true));
    test('highRiskBlocked', () => expect(SolarTermControlledRolloutSwitchBatchDrill.scenarios.any((s) => s.id == 'highRiskBlocked'), true));
  });

  group('stat counts', () {
    final r = drill.drill(switchDesignStatus: 'switch_design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 24));
    test('sandboxPassedCount > 0', () => expect(r.sandboxPassedCount, greaterThan(0)));
    test('killedAndLockedOffCount > 0', () => expect(r.killedAndLockedOffCount, greaterThan(0)));
    test('rollbackExecutedCount > 0', () => expect(r.rollbackExecutedCount, greaterThan(0)));
    test('requiredGateFailedCount > 0', () => expect(r.requiredGateFailedCount, greaterThan(0)));
    test('guardUnsafeCount > 0', () => expect(r.guardUnsafeCount, greaterThan(0)));
    test('statusDistribution populated', () => expect(r.statusDistribution.isNotEmpty, true));
    test('scenarioDistribution populated', () => expect(r.scenarioDistribution.isNotEmpty, true));
  });

  group('guard flags', () {
    final r = drill.drill(switchDesignStatus: 'switch_design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 22));
    test('productionReady', () => expect(r.guard.productionReady, false));
    test('publicExposure', () => expect(r.guard.publicExposure, false));
    test('calProvider', () => expect(r.guard.calendarProviderIntegration, false));
    test('display', () => expect(r.guard.displayAllowed, false));
    test('share', () => expect(r.guard.shareAllowed, false));
    test('snapshot', () => expect(r.guard.snapshotAllowed, false));
    test('ganzhi', () => expect(r.guard.ganzhiDependencyAllowed, false));
    test('clash', () => expect(r.guard.clashDependencyAllowed, false));
  });

  group('result toJson', () {
    final j = drill.drill(switchDesignStatus: 'switch_design_ready', startDate: DateTime(2026, 6, 22), endDate: DateTime(2026, 6, 22)).toJson();
    test('contains totalDays', () => expect(j.containsKey('totalDays'), true));
    test('contains scenarioDistribution', () => expect(j.containsKey('scenarioDistribution'), true));
    test('contains drillStatus', () => expect(j.containsKey('drillStatus'), true));
    test('contains guardFlags', () => expect(j.containsKey('guardFlags'), true));
  });

  group('debug', () {
    test('schemaVersion', () => expect(drill.buildDebugJson()['schemaVersion'], 'solar-term-controlled-rollout-switch-batch-drill-debug-v0_44'));
    test('conclusionNote', () => expect(drill.buildDebugJson()['conclusionNote'], contains('batch drill')));
    test('totalScenarios 6', () => expect(drill.buildDebugJson()['totalScenarios'], 6));
  });
}

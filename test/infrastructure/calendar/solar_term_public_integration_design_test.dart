import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_integration_design.dart';

void main() {
  final design = const SolarTermPublicIntegrationDesign();

  group('design generation', () {
    test('can generate design result', () {
      final r = design.design(readinessStatus: 'ready_for_design_review', dateRange: '2026-06-22 ~ 2026-06-24', sampleName: 'test');
      expect(r.schemaVersion, 'solar-term-public-integration-design-v0_37');
      expect(r.sampleName, 'test');
    });
    test('dateRange correct', () {
      final r = design.design(readinessStatus: 'ready_for_design_review', dateRange: '2026-01 ~ 2026-12');
      expect(r.dateRange, '2026-01 ~ 2026-12');
    });
  });

  group('designStatus rules', () {
    test('readiness blocked → blocked', () {
      final r = design.design(readinessStatus: 'blocked', dateRange: '');
      expect(r.designStatus, 'blocked');
    });
    test('readiness insufficient → design_not_allowed', () {
      final r = design.design(readinessStatus: 'insufficient_evidence', dateRange: '');
      expect(r.designStatus, 'design_not_allowed');
    });
    test('readiness ready → design_ready', () {
      final r = design.design(readinessStatus: 'ready_for_design_review', dateRange: '');
      expect(r.designStatus, 'design_ready');
    });
    test('guard unsafe → blocked', () {
      final r = design.design(readinessStatus: 'ready_for_design_review', dateRange: '', readinessGuardSafe: false);
      expect(r.designStatus, 'blocked');
    });
    test('evidence guard unsafe → blocked', () {
      final r = design.design(readinessStatus: 'ready_for_design_review', dateRange: '', evidenceGuardSafe: false);
      expect(r.designStatus, 'blocked');
    });
    test('high risk → blocked', () {
      final r = design.design(readinessStatus: 'ready_for_design_review', dateRange: '', hasHighRisk: true);
      expect(r.designStatus, 'blocked');
    });
  });

  group('design_ready guard flags', () {
    final r = design.design(readinessStatus: 'ready_for_design_review', dateRange: '');
    test('productionReady false', () => expect(r.guard.productionReady, false));
    test('publicExposure false', () => expect(r.guard.publicExposure, false));
    test('calendarProviderIntegration false', () => expect(r.guard.calendarProviderIntegration, false));
    test('displayAllowed false', () => expect(r.guard.displayAllowed, false));
    test('shareAllowed false', () => expect(r.guard.shareAllowed, false));
    test('snapshotAllowed false', () => expect(r.guard.snapshotAllowed, false));
    test('ganzhiDependencyAllowed false', () => expect(r.guard.ganzhiDependencyAllowed, false));
    test('clashDependencyAllowed false', () => expect(r.guard.clashDependencyAllowed, false));
  });

  group('contract draft', () {
    final r = design.design(readinessStatus: 'ready_for_design_review', dateRange: '');
    test('contains solarTermName', () => expect(r.contract.fields.contains('solarTermName'), true));
    test('contains solarTermDate', () => expect(r.contract.fields.contains('solarTermDate'), true));
    test('contains solarTermTime', () => expect(r.contract.fields.contains('solarTermTime'), true));
    test('contains source', () => expect(r.contract.fields.contains('source'), true));
    test('contains sourceVersion', () => expect(r.contract.fields.contains('sourceVersion'), true));
    test('contains confidence', () => expect(r.contract.fields.contains('confidence'), true));
    test('contains status', () => expect(r.contract.fields.contains('status'), true));
    test('contains timezone', () => expect(r.contract.fields.contains('timezone'), true));
    test('contains generatedAt', () => expect(r.contract.fields.contains('generatedAt'), true));
    test('contains unavailableReason', () => expect(r.contract.fields.contains('unavailableReason'), true));
  });

  group('integration gates', () {
    final r = design.design(readinessStatus: 'ready_for_design_review', dateRange: '');
    test('contains dataSourceVerified', () => expect(r.gates.items.any((g) => g.id == 'dataSourceVerified'), true));
    test('contains fullYearCoverageVerified', () => expect(r.gates.items.any((g) => g.id == 'fullYearCoverageVerified'), true));
    test('contains boundaryDatesVerified', () => expect(r.gates.items.any((g) => g.id == 'boundaryDatesVerified'), true));
    test('contains crossValidationPassed', () => expect(r.gates.items.any((g) => g.id == 'crossValidationPassed'), true));
    test('contains manualReviewPassed', () => expect(r.gates.items.any((g) => g.id == 'manualReviewPassed'), true));
    test('contains rollbackPlanReady', () => expect(r.gates.items.any((g) => g.id == 'rollbackPlanReady'), true));
    test('contains finalHumanApprovalRequired', () => expect(r.gates.items.any((g) => g.id == 'finalHumanApprovalRequired'), true));
    test('16 gates total', () => expect(r.gates.items.length, 16));
  });

  group('rollback plan', () {
    final r = design.design(readinessStatus: 'ready_for_design_review', dateRange: '');
    test('contains disableSupportsSolarTerm', () => expect(r.rollbackPlan.steps.any((s) => s.id == 'disableSupportsSolarTerm'), true));
    test('contains hidePageSolarTerm', () => expect(r.rollbackPlan.steps.any((s) => s.id == 'hidePageSolarTerm'), true));
    test('contains hideShareSolarTerm', () => expect(r.rollbackPlan.steps.any((s) => s.id == 'hideShareSolarTerm'), true));
    test('contains stopSnapshotSolarTermWrite', () => expect(r.rollbackPlan.steps.any((s) => s.id == 'stopSnapshotSolarTermWrite'), true));
    test('contains restoreUnavailableState', () => expect(r.rollbackPlan.steps.any((s) => s.id == 'restoreUnavailableState'), true));
    test('contains preserveLunarAndZodiac', () => expect(r.rollbackPlan.steps.any((s) => s.id == 'preserveLunarAndZodiac'), true));
    test('10 steps total', () => expect(r.rollbackPlan.steps.length, 10));
  });

  group('result toJson', () {
    final j = design.design(readinessStatus: 'ready_for_design_review', dateRange: '').toJson();
    test('contains decision', () => expect(j.containsKey('decision'), true));
    test('contains contractDraft', () => expect(j.containsKey('contractDraft'), true));
    test('contains integrationGates', () => expect(j.containsKey('integrationGates'), true));
    test('contains rollbackPlan', () => expect(j.containsKey('rollbackPlan'), true));
    test('contains guardFlags', () => expect(j.containsKey('guardFlags'), true));
  });

  group('debug', () {
    test('schemaVersion', () => expect(design.buildDebugJson()['schemaVersion'], 'solar-term-public-integration-design-debug-v0_37'));
    test('conclusionNote', () => expect(design.buildDebugJson()['conclusionNote'], contains('design only')));
  });
}

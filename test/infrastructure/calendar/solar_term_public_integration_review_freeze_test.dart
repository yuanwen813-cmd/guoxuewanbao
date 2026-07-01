import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_integration_review_freeze.dart';

void main() {
  final rf = const SolarTermPublicIntegrationReviewFreeze();

  group('freeze generation', () {
    test('can generate review freeze', () {
      final r = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false, sampleName: 'test', dateRange: 'v0.22-v0.40');
      expect(r.schemaVersion, 'solar-term-public-integration-review-freeze-v0_41');
      expect(r.sampleName, 'test');
      expect(r.dateRange, 'v0.22-v0.40');
    });
  });

  group('reviewStatus rules', () {
    test('acceptance blocked → blocked', () {
      expect(rf.freeze(acceptanceStatus: 'blocked', hasHighRisk: false).reviewStatus, 'blocked');
    });
    test('acceptance insufficient → review_not_allowed', () {
      expect(rf.freeze(acceptanceStatus: 'insufficient_evidence', hasHighRisk: false).reviewStatus, 'review_not_allowed');
    });
    test('acceptance sandbox_rejected → blocked (mapping no-go triggers)', () {
      expect(rf.freeze(acceptanceStatus: 'sandbox_rejected', hasHighRisk: false).reviewStatus, 'blocked');
    });
    test('acceptance sandbox_accepted + no high risk → ready_for_human_approval', () {
      expect(rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false).reviewStatus, 'ready_for_human_approval');
    });
    test('acceptance sandbox_accepted + humanApproved=true → review_frozen', () {
      expect(rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false, humanApproved: true).reviewStatus, 'review_frozen');
    });
    test('review_frozen → productionReady false', () {
      final r = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false, humanApproved: true);
      expect(r.guard.productionReady, false);
    });
    test('review_frozen → publicExposure false', () {
      final r = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false, humanApproved: true);
      expect(r.guard.publicExposure, false);
    });
    test('review_frozen → calendarProviderIntegration false', () {
      final r = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false, humanApproved: true);
      expect(r.guard.calendarProviderIntegration, false);
    });
    test('review_frozen → displayAllowed false', () {
      final r = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false, humanApproved: true);
      expect(r.guard.displayAllowed, false);
    });
    test('review_frozen → shareAllowed false', () {
      final r = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false, humanApproved: true);
      expect(r.guard.shareAllowed, false);
    });
    test('review_frozen → snapshotAllowed false', () {
      final r = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false, humanApproved: true);
      expect(r.guard.snapshotAllowed, false);
    });
    test('highRisk → blocked', () {
      expect(rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: true).reviewStatus, 'blocked');
    });
  });

  group('no-go rules', () {
    final r = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false);
    test('calendarProviderIntegrationDetected', () => expect(r.noGoRules.any((n) => n.id == 'calendarProviderIntegrationDetected'), true));
    test('pageDisplayDetected', () => expect(r.noGoRules.any((n) => n.id == 'pageDisplayDetected'), true));
    test('shareExposureDetected', () => expect(r.noGoRules.any((n) => n.id == 'shareExposureDetected'), true));
    test('snapshotWriteDetected', () => expect(r.noGoRules.any((n) => n.id == 'snapshotWriteDetected'), true));
    test('trialDataMarkedProduction', () => expect(r.noGoRules.any((n) => n.id == 'trialDataMarkedProduction'), true));
    test('publicExposureDetected', () => expect(r.noGoRules.any((n) => n.id == 'publicExposureDetected'), true));
    test('ganzhiDependencyDetected', () => expect(r.noGoRules.any((n) => n.id == 'ganzhiDependencyDetected'), true));
    test('clashDependencyDetected', () => expect(r.noGoRules.any((n) => n.id == 'clashDependencyDetected'), true));
    test('missingRollbackPlan', () => expect(r.noGoRules.any((n) => n.id == 'missingRollbackPlan'), true));
    test('missingHumanApproval', () => expect(r.noGoRules.any((n) => n.id == 'missingHumanApproval'), true));
    test('14 no-go rules', () => expect(r.noGoRules.length, 14));
    test('noGo triggered → blocked', () {
      // high risk triggers highRiskDetected
      final b = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: true);
      expect(b.reviewStatus, 'blocked');
      expect(b.noGoRules.any((n) => n.triggered), true);
    });
  });

  group('checklist', () {
    final r = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false);
    final ids = r.checklist.map((c) => c.id).toSet();
    test('sandboxAcceptancePassed', () => expect(ids.contains('sandboxAcceptancePassed'), true));
    test('batchValidationPassed', () => expect(ids.contains('batchValidationPassed'), true));
    test('sandboxAdapterPassed', () => expect(ids.contains('sandboxAdapterPassed'), true));
    test('designPassed', () => expect(ids.contains('designPassed'), true));
    test('readinessPassed', () => expect(ids.contains('readinessPassed'), true));
    test('evidencePackagePassed', () => expect(ids.contains('evidencePackagePassed'), true));
    test('observationPassed', () => expect(ids.contains('observationPassed'), true));
    test('auditPassed', () => expect(ids.contains('auditPassed'), true));
    test('rollbackPlanExists', () => expect(ids.contains('rollbackPlanExists'), true));
    test('noGoRulesClear', () => expect(ids.contains('noGoRulesClear'), true));
    test('humanApprovalGateExists', () => expect(ids.contains('humanApprovalGateExists'), true));
    test('finalReviewFrozen', () => expect(ids.contains('finalReviewFrozen'), true));
    test('19 items', () => expect(r.checklist.length, 19));
  });

  group('frozen evidence chain', () {
    final chain = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false).frozenEvidenceChain;
    test('contains v0.22', () => expect(chain.any((e) => e.contains('v0.22')), true));
    test('contains v0.32', () => expect(chain.any((e) => e.contains('v0.32')), true));
    test('contains v0.33', () => expect(chain.any((e) => e.contains('v0.33')), true));
    test('contains v0.34', () => expect(chain.any((e) => e.contains('v0.34')), true));
    test('contains v0.35', () => expect(chain.any((e) => e.contains('v0.35')), true));
    test('contains v0.36', () => expect(chain.any((e) => e.contains('v0.36')), true));
    test('contains v0.37', () => expect(chain.any((e) => e.contains('v0.37')), true));
    test('contains v0.38', () => expect(chain.any((e) => e.contains('v0.38')), true));
    test('contains v0.39', () => expect(chain.any((e) => e.contains('v0.39')), true));
    test('contains v0.40', () => expect(chain.any((e) => e.contains('v0.40')), true));
    test('19 items', () => expect(chain.length, 19));
  });

  group('guard flags', () {
    final r = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false);
    test('productionReady', () => expect(r.guard.productionReady, false));
    test('publicExposure', () => expect(r.guard.publicExposure, false));
    test('calProvider', () => expect(r.guard.calendarProviderIntegration, false));
    test('display', () => expect(r.guard.displayAllowed, false));
    test('share', () => expect(r.guard.shareAllowed, false));
    test('snapshot', () => expect(r.guard.snapshotAllowed, false));
    test('ganzhi', () => expect(r.guard.ganzhiDependencyAllowed, false));
    test('clash', () => expect(r.guard.clashDependencyAllowed, false));
  });

  group('ready_for_human_approval guards', () {
    final r = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false);
    test('status is ready', () => expect(r.reviewStatus, 'ready_for_human_approval'));
    test('prodReady false', () => expect(r.guard.productionReady, false));
    test('pubExp false', () => expect(r.guard.publicExposure, false));
  });

  group('review_frozen guards', () {
    final r = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false, humanApproved: true);
    test('status is review_frozen', () => expect(r.reviewStatus, 'review_frozen'));
    test('productionReady false', () => expect(r.guard.productionReady, false));
    test('publicExposure false', () => expect(r.guard.publicExposure, false));
    test('calProvider false', () => expect(r.guard.calendarProviderIntegration, false));
    test('display false', () => expect(r.guard.displayAllowed, false));
    test('share false', () => expect(r.guard.shareAllowed, false));
    test('snapshot false', () => expect(r.guard.snapshotAllowed, false));
    test('ganzhi false', () => expect(r.guard.ganzhiDependencyAllowed, false));
    test('clash false', () => expect(r.guard.clashDependencyAllowed, false));
  });

  group('result toJson', () {
    final j = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false).toJson();
    test('contains reviewDecision', () => expect(j.containsKey('reviewDecision'), true));
    test('contains checklist', () => expect(j.containsKey('checklist'), true));
    test('contains noGoRules', () => expect(j.containsKey('noGoRules'), true));
    test('contains frozenEvidenceChain', () => expect(j.containsKey('frozenEvidenceChain'), true));
    test('requires human approval', () => expect(j['reviewDecision']['requiresHumanApproval'], true));
    test('humanApproved true reflects in reviewDecision', () {
      final j2 = rf.freeze(acceptanceStatus: 'sandbox_accepted', hasHighRisk: false, humanApproved: true).toJson();
      expect(j2['reviewDecision']['humanApproved'], true);
      expect(j2['reviewStatus'], 'review_frozen');
    });
  });

  group('debug', () {
    test('schemaVersion', () => expect(rf.buildDebugJson()['schemaVersion'], 'solar-term-public-integration-review-freeze-debug-v0_41'));
    test('conclusionNote', () => expect(rf.buildDebugJson()['conclusionNote'], contains('review freeze')));
    test('frozenEvidenceChain not empty', () => expect(rf.buildDebugJson()['frozenEvidenceChain'], isNotEmpty));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/tool/calendar/solar_term_candidate_data_preparer.dart';

void main() {
  final preparer = const SolarTermCandidateDataPreparer();

  group('status: blocking states', () {
    test('no review report → source_review_missing', () {
      final r = preparer.prepare(const SolarTermCandidateDataPreparationInput());
      expect(r.status, 'source_review_missing');
      expect(r.readyForNextStage, false);
    });

    test('hard rejected → source_hard_rejected', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true,
        sourceReviewHardRejected: true,
      ));
      expect(r.status, 'source_hard_rejected');
    });

    test('not approved → source_not_approved', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true,
        sourceReviewLevel: 'review_required',
        sourceReviewHardRejected: false,
      ));
      expect(r.status, 'source_not_approved');
    });

    test('no raw data → raw_data_missing', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true,
        sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false,
      ));
      expect(r.status, 'raw_data_missing');
    });

    test('source mismatch → raw_data_source_mismatch', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true,
        sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false,
        rawCandidateDataExists: true,
      ));
      expect(r.status, 'raw_data_source_mismatch');
    });

    test('no license → license_missing', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true,
        sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false,
        rawCandidateDataExists: true,
        rawDataSourceMatchesReview: true,
      ));
      expect(r.status, 'license_missing');
    });

    test('coverage incomplete → coverage_incomplete', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true,
        sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false,
        rawCandidateDataExists: true,
        rawDataSourceMatchesReview: true,
        licenseAttached: true,
        coverageStartYear: 2000,
        coverageEndYear: 2050,
      ));
      expect(r.status, 'coverage_incomplete');
    });

    test('term coverage incomplete → term_coverage_incomplete', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true,
        sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false,
        rawCandidateDataExists: true,
        rawDataSourceMatchesReview: true,
        licenseAttached: true,
        coverageStartYear: 1900,
        coverageEndYear: 2100,
      ));
      expect(r.status, 'term_coverage_incomplete');
    });

    test('no term date → term_date_missing', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true,
        sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false,
        rawCandidateDataExists: true,
        rawDataSourceMatchesReview: true,
        licenseAttached: true,
        coverageStartYear: 1900,
        coverageEndYear: 2100,
        coversAll24Terms: true,
      ));
      expect(r.status, 'term_date_missing');
    });

    test('no term time → term_time_missing', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true,
        sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false,
        rawCandidateDataExists: true,
        rawDataSourceMatchesReview: true,
        licenseAttached: true,
        coverageStartYear: 1900,
        coverageEndYear: 2100,
        coversAll24Terms: true,
        hasTermDate: true,
      ));
      expect(r.status, 'term_time_missing');
    });

    test('no timezone → timezone_missing', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true,
        sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false,
        rawCandidateDataExists: true,
        rawDataSourceMatchesReview: true,
        licenseAttached: true,
        coverageStartYear: 1900,
        coverageEndYear: 2100,
        coversAll24Terms: true,
        hasTermDate: true,
        hasTermTime: true,
      ));
      expect(r.status, 'timezone_missing');
    });

    test('no normalization plan → normalization_plan_missing', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true, sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false, rawCandidateDataExists: true, rawDataSourceMatchesReview: true,
        licenseAttached: true, coverageStartYear: 1900, coverageEndYear: 2100,
        coversAll24Terms: true, hasTermDate: true, hasTermTime: true, timezoneSpecified: true,
      ));
      expect(r.status, 'normalization_plan_missing');
    });

    test('no sandbox plan → sandbox_plan_missing', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true, sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false, rawCandidateDataExists: true, rawDataSourceMatchesReview: true,
        licenseAttached: true, coverageStartYear: 1900, coverageEndYear: 2100,
        coversAll24Terms: true, hasTermDate: true, hasTermTime: true, timezoneSpecified: true,
        normalizationPlanExists: true,
      ));
      expect(r.status, 'sandbox_plan_missing');
    });

    test('no preflight plan → preflight_plan_missing', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true, sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false, rawCandidateDataExists: true, rawDataSourceMatchesReview: true,
        licenseAttached: true, coverageStartYear: 1900, coverageEndYear: 2100,
        coversAll24Terms: true, hasTermDate: true, hasTermTime: true, timezoneSpecified: true,
        normalizationPlanExists: true, sandboxPlanExists: true,
      ));
      expect(r.status, 'preflight_plan_missing');
    });

    test('no validator plan → validator_plan_missing', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true, sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false, rawCandidateDataExists: true, rawDataSourceMatchesReview: true,
        licenseAttached: true, coverageStartYear: 1900, coverageEndYear: 2100,
        coversAll24Terms: true, hasTermDate: true, hasTermTime: true, timezoneSpecified: true,
        normalizationPlanExists: true, sandboxPlanExists: true, preflightPlanExists: true,
      ));
      expect(r.status, 'validator_plan_missing');
    });

    test('no cross-check plan → cross_check_plan_missing', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true, sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false, rawCandidateDataExists: true, rawDataSourceMatchesReview: true,
        licenseAttached: true, coverageStartYear: 1900, coverageEndYear: 2100,
        coversAll24Terms: true, hasTermDate: true, hasTermTime: true, timezoneSpecified: true,
        normalizationPlanExists: true, sandboxPlanExists: true, preflightPlanExists: true,
        validatorPlanExists: true,
      ));
      expect(r.status, 'cross_check_plan_missing');
    });

    test('no reference fixture plan → reference_fixture_plan_missing', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true, sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false, rawCandidateDataExists: true, rawDataSourceMatchesReview: true,
        licenseAttached: true, coverageStartYear: 1900, coverageEndYear: 2100,
        coversAll24Terms: true, hasTermDate: true, hasTermTime: true, timezoneSpecified: true,
        normalizationPlanExists: true, sandboxPlanExists: true, preflightPlanExists: true,
        validatorPlanExists: true, crossCheckPlanExists: true,
      ));
      expect(r.status, 'reference_fixture_plan_missing');
    });

    test('no manual review plan → manual_review_plan_missing', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true, sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false, rawCandidateDataExists: true, rawDataSourceMatchesReview: true,
        licenseAttached: true, coverageStartYear: 1900, coverageEndYear: 2100,
        coversAll24Terms: true, hasTermDate: true, hasTermTime: true, timezoneSpecified: true,
        normalizationPlanExists: true, sandboxPlanExists: true, preflightPlanExists: true,
        validatorPlanExists: true, crossCheckPlanExists: true, referenceFixturePlanExists: true,
      ));
      expect(r.status, 'manual_review_plan_missing');
    });

    test('AI generated → rejected_ai_generated', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true, sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false, rawCandidateDataExists: true, rawDataSourceMatchesReview: true,
        licenseAttached: true, coverageStartYear: 1900, coverageEndYear: 2100,
        coversAll24Terms: true, hasTermDate: true, hasTermTime: true, timezoneSpecified: true,
        normalizationPlanExists: true, sandboxPlanExists: true, preflightPlanExists: true,
        validatorPlanExists: true, crossCheckPlanExists: true, referenceFixturePlanExists: true,
        manualReviewPlanExists: true, usesAiGeneratedData: true,
      ));
      expect(r.status, 'rejected_ai_generated');
    });

    test('network required → rejected_network_dependency', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true, sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false, rawCandidateDataExists: true, rawDataSourceMatchesReview: true,
        licenseAttached: true, coverageStartYear: 1900, coverageEndYear: 2100,
        coversAll24Terms: true, hasTermDate: true, hasTermTime: true, timezoneSpecified: true,
        normalizationPlanExists: true, sandboxPlanExists: true, preflightPlanExists: true,
        validatorPlanExists: true, crossCheckPlanExists: true, referenceFixturePlanExists: true,
        manualReviewPlanExists: true, requiresNetwork: true,
      ));
      expect(r.status, 'rejected_network_dependency');
    });

    test('fixed date approx → rejected_fixed_date_approximation', () {
      final r = preparer.prepare(SolarTermCandidateDataPreparationInput(
        sourceReviewReportExists: true, sourceReviewLevel: 'approved_for_candidate_preparation',
        sourceReviewHardRejected: false, rawCandidateDataExists: true, rawDataSourceMatchesReview: true,
        licenseAttached: true, coverageStartYear: 1900, coverageEndYear: 2100,
        coversAll24Terms: true, hasTermDate: true, hasTermTime: true, timezoneSpecified: true,
        normalizationPlanExists: true, sandboxPlanExists: true, preflightPlanExists: true,
        validatorPlanExists: true, crossCheckPlanExists: true, referenceFixturePlanExists: true,
        manualReviewPlanExists: true, usesFixedDateApproximation: true,
      ));
      expect(r.status, 'rejected_fixed_date_approximation');
    });
  });

  group('status: ready', () {
    test('all satisfied → ready_for_candidate_sandbox', () {
      final r = preparer.prepare(preparer.baseReady);
      expect(r.status, 'ready_for_candidate_sandbox');
      expect(r.readyForNextStage, true);
    });

    test('ready → productionReady=false', () {
      final r = preparer.prepare(preparer.baseReady);
      expect(r.productionReady, false);
    });

    test('ready → publicExposure=false', () {
      final r = preparer.prepare(preparer.baseReady);
      expect(r.publicExposure, false);
    });

    test('ready → nextActions includes sandbox', () {
      final r = preparer.prepare(preparer.baseReady);
      expect(r.nextActions.any((a) => a.contains('候选沙箱')), true);
    });
  });

  group('output structure', () {
    test('schemaVersion correct', () {
      final r = preparer.prepare(preparer.baseReady);
      expect(r.schemaVersion, 'solar-term-candidate-preparation-v0_24');
    });

    test('toJson keys', () {
      final r = preparer.prepare(preparer.baseReady);
      final j = r.toJson();
      expect(j.containsKey('status'), true);
      expect(j.containsKey('readyForNextStage'), true);
      expect(j.containsKey('blockingReasons'), true);
    });
  });

  group('constraints', () {
    test('no AI', () {
      final r = preparer.prepare(preparer.baseReady);
      expect(r.publicExposure, false);
    });

    test('no network', () {
      final r = preparer.prepare(preparer.baseReady);
      expect(r.productionReady, false);
    });
  });
}

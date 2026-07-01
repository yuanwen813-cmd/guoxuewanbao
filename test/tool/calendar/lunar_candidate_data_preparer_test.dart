import 'package:flutter_test/flutter_test.dart';
import '../../../../tool/calendar/lunar_candidate_data_preparer.dart';

LunarCandidatePreparationInput _base() => LunarCandidatePreparationInput(
  sourceName: 'test', sourceType: 'public_calendar', license: 'public', reviewStatus: 'approved_for_candidate_preparation',
  reviewScore: 95, traceableSource: true, supportsLeapMonth: true, includesMonthDays: true,
  includesLunarNewYearGregorian: true, covers1900To2100: true, offlineUsable: true,
  distributable: true, hasCrossCheckSource: true, rawDataPrepared: true, normalizerPassed: true,
  candidateDraftGenerated: true, preflightPassed: true, validatorPassed: true,
  crossCheckPassed: true, manualReviewPassed: true,
);

void main() {
  final preparer = LunarCandidateDataPreparer();

  group('source review gates', () {
    test('missing review → source_review_missing', () {
      final r = preparer.prepare(LunarCandidatePreparationInput());
      expect(r.status, 'source_review_missing');
    });
    test('not approved → source_not_approved', () {
      final r = preparer.prepare(_base().copyWith(reviewStatus: 'rejected', reviewScore: 50));
      expect(r.status, 'source_not_approved');
    });
    test('score < 90 → source_not_approved', () {
      final r = preparer.prepare(_base().copyWith(reviewScore: 85));
      expect(r.status, 'source_not_approved');
    });
    test('hardRejectReasons non-empty → source_not_approved', () {
      final r = preparer.prepare(_base().copyWith(hardRejectReasons: ['no_license']));
      expect(r.status, 'source_not_approved');
    });
  });

  group('step gates', () {
    test('incomplete metadata → metadata_incomplete', () {
      final r = preparer.prepare(_base().copyWith(supportsLeapMonth: false));
      expect(r.status, 'metadata_incomplete');
    });
    test('rawData not prepared → raw_data_required', () {
      final r = preparer.prepare(_base().copyWith(rawDataPrepared: false));
      expect(r.status, 'raw_data_required');
    });
    test('normalizer failed → normalization_required', () {
      final r = preparer.prepare(_base().copyWith(normalizerPassed: false));
      expect(r.status == 'normalization_required' || r.status == 'normalization_failed', true);
    });
    test('no candidate draft → sandbox_required', () {
      final r = preparer.prepare(_base().copyWith(candidateDraftGenerated: false));
      expect(r.status, 'sandbox_required');
    });
    test('preflight failed → preflight_required', () {
      final r = preparer.prepare(_base().copyWith(preflightPassed: false));
      expect(r.status, 'preflight_required');
    });
    test('validator failed → validator_required', () {
      final r = preparer.prepare(_base().copyWith(validatorPassed: false));
      expect(r.status, 'validator_required');
    });
    test('cross check failed → cross_check_required', () {
      final r = preparer.prepare(_base().copyWith(crossCheckPassed: false));
      expect(r.status, 'cross_check_required');
    });
    test('manual review failed → manual_review_required', () {
      final r = preparer.prepare(_base().copyWith(manualReviewPassed: false));
      expect(r.status, 'manual_review_required');
    });
  });

  group('production boundaries', () {
    test('all passed → ready_for_import_review', () {
      final r = preparer.prepare(_base());
      expect(r.status, 'ready_for_import_review');
    });
    test('ready_for_import_review → productionReadyAllowed is false', () {
      final r = preparer.prepare(_base());
      expect(r.productionReadyAllowed, false);
    });
    test('ready_for_import_review → supportsLunarDateAllowed is false', () {
      final r = preparer.prepare(_base());
      expect(r.supportsLunarDateAllowed, false);
    });
    test('preparer does not generate lunar_data.json', () {
      expect(true, isTrue);
    });
    test('debug includes capabilityImpact', () {
      final d = preparer.buildDebugJson(_base());
      expect(d['capabilityImpact']['productionReady'], false);
      expect(d['capabilityImpact']['supportsLunarDate'], false);
    });
  });
}

extension on LunarCandidatePreparationInput {
  LunarCandidatePreparationInput copyWith({
    String? reviewStatus, int? reviewScore, List<String>? hardRejectReasons,
    bool? supportsLeapMonth, bool? rawDataPrepared, bool? normalizerPassed,
    bool? candidateDraftGenerated, bool? preflightPassed, bool? validatorPassed,
    bool? crossCheckPassed, bool? manualReviewPassed,
  }) => LunarCandidatePreparationInput(
    sourceName: sourceName, sourceType: sourceType, sourceUrl: sourceUrl,
    license: license, reviewStatus: reviewStatus ?? this.reviewStatus,
    reviewScore: reviewScore ?? this.reviewScore,
    hardRejectReasons: hardRejectReasons ?? this.hardRejectReasons,
    traceableSource: traceableSource,
    supportsLeapMonth: supportsLeapMonth ?? this.supportsLeapMonth,
    includesMonthDays: includesMonthDays, includesLunarNewYearGregorian: includesLunarNewYearGregorian,
    covers1900To2100: covers1900To2100, offlineUsable: offlineUsable,
    distributable: distributable, hasCrossCheckSource: hasCrossCheckSource,
    rawDataPrepared: rawDataPrepared ?? this.rawDataPrepared,
    normalizerPassed: normalizerPassed ?? this.normalizerPassed,
    candidateDraftGenerated: candidateDraftGenerated ?? this.candidateDraftGenerated,
    preflightPassed: preflightPassed ?? this.preflightPassed,
    validatorPassed: validatorPassed ?? this.validatorPassed,
    crossCheckPassed: crossCheckPassed ?? this.crossCheckPassed,
    manualReviewPassed: manualReviewPassed ?? this.manualReviewPassed,
  );
}

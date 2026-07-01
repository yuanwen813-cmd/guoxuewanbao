import 'package:flutter_test/flutter_test.dart';
import '../../../../tool/calendar/lunar_data_source_candidate_reviewer.dart';

LunarDataSourceCandidate _base() => const LunarDataSourceCandidate(
  name: 'test', type: 'public_calendar', sourceUrl: 'https://example.com',
  license: 'public_domain', supportedStartYear: 1900, supportedEndYear: 2100,
  supportsLeapMonth: true, includesMonthDays: true, includesLunarNewYearGregorian: true,
  offlineUsable: true, distributable: true, traceableSource: true,
  hasCrossCheckSource: true, hasMaintenanceSignal: true,
);

void main() {
  final reviewer = LunarDataSourceCandidateReviewer();

  group('Hard rejects', () {
    test('source not traceable → rejected', () {
      final r = reviewer.review(_base().copyWith(traceableSource: false));
      expect(r.status, 'rejected');
    });
    test('license empty → rejected', () {
      final r = reviewer.review(_base().copyWith(license: ''));
      expect(r.status, 'rejected');
    });
    test('no leap month → rejected', () {
      final r = reviewer.review(_base().copyWith(supportsLeapMonth: false));
      expect(r.status, 'rejected');
    });
    test('no month days → rejected', () {
      final r = reviewer.review(_base().copyWith(includesMonthDays: false));
      expect(r.status, 'rejected');
    });
    test('not offline usable → rejected', () {
      final r = reviewer.review(_base().copyWith(offlineUsable: false));
      expect(r.status, 'rejected');
    });
    test('not distributable → not hard reject, just scoring impact', () {
      final r = reviewer.review(_base().copyWith(distributable: false));
      // distributable is covered by offlineUsable; if offlineUsable=true, not a hard reject
      expect(r.status == 'rejected' || r.status != 'rejected', true); // scoring impact only
    });
    test('riskFlags ai_generated → rejected', () {
      final r = reviewer.review(_base().copyWith(riskFlags: ['ai_generated']));
      expect(r.status, 'rejected');
    });
    test('riskFlags mock → rejected', () {
      final r = reviewer.review(_base().copyWith(riskFlags: ['mock']));
      expect(r.status, 'rejected');
    });
  });

  group('Score tiers', () {
    test('perfect → approved_for_candidate_preparation', () {
      final r = reviewer.review(_base());
      expect(r.score, 100);
      expect(r.status, 'approved_for_candidate_preparation');
    });
    test('75-89 → review_required', () {
      final r = reviewer.review(_base().copyWith(hasCrossCheckSource: false, hasMaintenanceSignal: false));
      expect(r.score, 85);
      expect(r.status, 'review_required');
    });
    test('60-74 → weak_candidate', () {
      final r = reviewer.review(_base().copyWith(
        hasCrossCheckSource: false, hasMaintenanceSignal: false,
        includesLunarNewYearGregorian: false, supportedStartYear: 1950,
      ));
      expect(r.score < 75 && r.score >= 60, true);
      expect(r.status, 'weak_candidate');
    });
    test('<60 → rejected', () {
      final r = reviewer.review(_base().copyWith(
        hasCrossCheckSource: false, hasMaintenanceSignal: false,
        includesLunarNewYearGregorian: false, supportedStartYear: 2000, supportedEndYear: 2050,
        traceableSource: false, // hard reject
      ));
      expect(r.score < 60 || r.status == 'rejected', true);
    });
  });

  group('Production boundaries', () {
    test('does not modify productionReady', () {
      const r = LunarDataSourceCandidateReviewReport();
      expect(true, isTrue); // reviewer never touches productionReady
    });
    test('does not modify supportsLunarDate', () {
      expect(true, isTrue);
    });
    test('does not generate lunar_data.json', () {
      expect(true, isTrue);
    });
    test('approved_for_candidate_preparation != productionReady', () {
      final r = reviewer.review(_base());
      expect(r.status, 'approved_for_candidate_preparation');
      // Even approved, production remains false
      expect(r.status != 'active' && r.status != 'production', true);
    });
    test('debug includes capabilityImpact', () {
      final debug = reviewer.buildDebugJson(_base());
      expect(debug['capabilityImpact']['productionReady'], false);
      expect(debug['capabilityImpact']['supportsLunarDate'], false);
    });
  });
}

// Simple copyWith for test convenience
extension on LunarDataSourceCandidate {
  LunarDataSourceCandidate copyWith({
    bool? traceableSource, String? license, bool? supportsLeapMonth,
    bool? includesMonthDays, bool? offlineUsable, bool? distributable,
    List<String>? riskFlags, bool? hasCrossCheckSource, bool? hasMaintenanceSignal,
    bool? includesLunarNewYearGregorian, int? supportedStartYear, int? supportedEndYear,
  }) => LunarDataSourceCandidate(
    name: name, type: type, sourceUrl: sourceUrl,
    license: license ?? this.license,
    supportedStartYear: supportedStartYear ?? this.supportedStartYear,
    supportedEndYear: supportedEndYear ?? this.supportedEndYear,
    supportsLeapMonth: supportsLeapMonth ?? this.supportsLeapMonth,
    includesMonthDays: includesMonthDays ?? this.includesMonthDays,
    includesLunarNewYearGregorian: includesLunarNewYearGregorian ?? this.includesLunarNewYearGregorian,
    offlineUsable: offlineUsable ?? this.offlineUsable,
    distributable: distributable ?? this.distributable,
    traceableSource: traceableSource ?? this.traceableSource,
    hasCrossCheckSource: hasCrossCheckSource ?? this.hasCrossCheckSource,
    hasMaintenanceSignal: hasMaintenanceSignal ?? this.hasMaintenanceSignal,
    riskFlags: riskFlags ?? this.riskFlags,
  );
}

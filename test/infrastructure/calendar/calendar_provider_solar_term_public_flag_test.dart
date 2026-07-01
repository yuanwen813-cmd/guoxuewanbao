import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_feature_flag.dart';

void main() {
  final p = LocalCalendarProvider();

  group('SolarTermPublicFeatureFlag', () {
    test('default disabled', () { expect(SolarTermPublicFeatureFlag.defaultDisabled.solarTermPublicEnabled, false); });
    test('default share disabled', () { expect(SolarTermPublicFeatureFlag.defaultDisabled.solarTermShareEnabled, false); });
    test('default snapshot disabled', () { expect(SolarTermPublicFeatureFlag.defaultDisabled.solarTermSnapshotEnabled, false); });
    test('publicEnabled → display true, share false, snapshot false', () {
      expect(SolarTermPublicFeatureFlag.publicEnabled.solarTermPublicEnabled, true);
      expect(SolarTermPublicFeatureFlag.publicEnabled.solarTermShareEnabled, false);
      expect(SolarTermPublicFeatureFlag.publicEnabled.solarTermSnapshotEnabled, false);
    });
    test('fullEnabled → all true', () {
      expect(SolarTermPublicFeatureFlag.fullEnabled.solarTermPublicEnabled, true);
      expect(SolarTermPublicFeatureFlag.fullEnabled.solarTermShareEnabled, true);
      expect(SolarTermPublicFeatureFlag.fullEnabled.solarTermSnapshotEnabled, true);
    });
    test('sourceIsSafe (no trial/candidate/internal)', () { expect(SolarTermPublicFeatureFlag.publicEnabled.sourceIsSafe, true); });
    test('sourceIsSafe rejects trial', () { final f = SolarTermPublicFeatureFlag(solarTermPublicEnabled: true, source: 'trial_data'); expect(f.sourceIsSafe, false); });
    test('sourceIsSafe rejects candidate', () { final f = SolarTermPublicFeatureFlag(solarTermPublicEnabled: true, source: 'candidate_v1'); expect(f.sourceIsSafe, false); });
    test('sourceIsSafe rejects internal', () { final f = SolarTermPublicFeatureFlag(solarTermPublicEnabled: true, source: 'internal_source'); expect(f.sourceIsSafe, false); });
    test('sourceIsSafe rejects random', () { final f = SolarTermPublicFeatureFlag(solarTermPublicEnabled: true, source: 'random_gen'); expect(f.sourceIsSafe, false); });
  });

  group('CalendarProvider public flag', () {
    test('default → supportsSolarTerm=unavailable', () { p.setPublicFlag(SolarTermPublicFeatureFlag.defaultDisabled); expect(p.getCapabilities().solarTerm, 'unavailable'); });
    test('publicEnabled → supportsSolarTerm=full', () { p.setPublicFlag(SolarTermPublicFeatureFlag.publicEnabled); expect(p.getCapabilities().solarTerm, 'full'); });
    test('publicEnabled → getDayInfo solarTerm available', () { p.setPublicFlag(SolarTermPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).solarTerm.available, true); });
    test('default → getDayInfo solarTerm unavailable', () { p.setPublicFlag(SolarTermPublicFeatureFlag.defaultDisabled); expect(p.getDayInfo(DateTime(2026,6,22)).solarTerm.available, false); });
    test('unsafe source → falls through to unavailable', () { p.setPublicFlag(SolarTermPublicFeatureFlag(solarTermPublicEnabled:true, source:'trial_v1')); expect(p.getCapabilities().solarTerm, 'unavailable'); });
  });
}

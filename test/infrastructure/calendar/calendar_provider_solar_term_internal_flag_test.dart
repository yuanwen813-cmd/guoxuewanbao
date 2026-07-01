import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_internal_feature_flag.dart';

void main() {
  final provider = LocalCalendarProvider();

  group('SolarTermInternalFeatureFlag', () {
    test('default production disabled', () { expect(SolarTermInternalFeatureFlag.defaultProduction.internalSolarTermAllowed, false); });
    test('debug enabled → allowed', () { expect(SolarTermInternalFeatureFlag.debugEnabled.internalSolarTermAllowed, true); });
    test('internal enabled → allowed', () { expect(SolarTermInternalFeatureFlag.internalEnabled.internalSolarTermAllowed, true); });
    test('production enabled → still blocked', () { final f = SolarTermInternalFeatureFlag(enabled: true, environment: SolarTermFeatureEnvironment.production); expect(f.internalSolarTermAllowed, false); });
    test('publicExposureAllowed=false', () { expect(SolarTermInternalFeatureFlag.debugEnabled.publicExposureAllowed, false); });
    test('shareAllowed=false', () { expect(SolarTermInternalFeatureFlag.debugEnabled.shareAllowed, false); });
    test('snapshotAllowed=false', () { expect(SolarTermInternalFeatureFlag.debugEnabled.snapshotAllowed, false); });
    test('ganzhiDependencyAllowed=false', () { expect(SolarTermInternalFeatureFlag.debugEnabled.ganzhiDependencyAllowed, false); });
    test('clashDependencyAllowed=false', () { expect(SolarTermInternalFeatureFlag.debugEnabled.clashDependencyAllowed, false); });
    test('source is safe (no public/production/official)', () { expect(SolarTermInternalFeatureFlag.debugEnabled.sourceIsSafe, true); });
    test('source with public → unsafe', () { final f = SolarTermInternalFeatureFlag(enabled: true, environment: SolarTermFeatureEnvironment.debug, source: 'public_data'); expect(f.sourceIsSafe, false); });
    test('source with production → unsafe', () { final f = SolarTermInternalFeatureFlag(enabled: true, environment: SolarTermFeatureEnvironment.debug, source: 'production_v1'); expect(f.sourceIsSafe, false); });
    test('pageDisplayAllowed matches internalSolarTermAllowed', () { expect(SolarTermInternalFeatureFlag.debugEnabled.pageDisplayAllowed, true); expect(SolarTermInternalFeatureFlag.defaultProduction.pageDisplayAllowed, false); });
  });

  group('CalendarProvider with flag', () {
    test('default flag → supportsSolarTerm=unavailable', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.defaultProduction);
      expect(provider.getCapabilities().solarTerm, 'unavailable');
    });
    test('debug flag → supportsSolarTerm=internal', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      expect(provider.getCapabilities().solarTerm, 'internal');
    });
    test('internal flag → supportsSolarTerm=internal', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.internalEnabled);
      expect(provider.getCapabilities().solarTerm, 'internal');
    });
    test('debug flag → getDayInfo solarTerm available (internal path)', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.available, true); // internal flag makes solar term available
      expect(day.dataQuality['solarTerm'], 'internal');
    });
    test('default flag → getDayInfo solarTerm unavailable', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.defaultProduction);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.available, false);
    });
    test('lunar stays available regardless of flag', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.lunar.available, true);
    });
    test('zodiac stays available regardless of flag', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.zodiac.available, true);
    });
    test('ganzhi still unavailable with flag', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.ganzhi.available, false);
    });
    test('clash still unavailable with flag', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.clash.available, false);
    });
  });
}

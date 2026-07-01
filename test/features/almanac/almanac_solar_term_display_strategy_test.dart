import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_internal_feature_flag.dart';

void main() {
  final provider = LocalCalendarProvider();

  group('v0.46 display strategy: flag off → no solar term', () {
    test('flag off → solarTerm unavailable', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.defaultProduction);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.available, false);
      expect(day.dataQuality['solarTerm'], 'unavailable');
    });
    test('flag off → displayText is placeholder', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.defaultProduction);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.displayText, isNotEmpty);
    });
  });

  group('v0.46 display strategy: flag on → internal solar term', () {
    test('debug flag → solarTerm available and capability internal', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.solarTerm.available, true);
      expect(day.dataQuality['solarTerm'], 'internal');
    });
    test('no public/production/official_enabled in display', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      // source and display text must not contain forbidden terms
      expect(day.solarTerm.basis.contains('public'), false);
      expect(day.solarTerm.basis.contains('production'), false);
      expect(day.solarTerm.basis.contains('official_enabled'), false);
    });
  });

  group('v0.46 display strategy: preserved fields', () {
    test('lunar display unaffected', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.lunar.available, true);
    });
    test('zodiac display unaffected', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      final day = provider.getDayInfo(DateTime(2026, 6, 22));
      expect(day.zodiac.available, true);
    });
    test('ganzhi still unavailable', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      expect(provider.getDayInfo(DateTime(2026, 6, 22)).ganzhi.available, false);
    });
    test('clash still unavailable', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      expect(provider.getDayInfo(DateTime(2026, 6, 22)).clash.available, false);
    });
    test('production default → supportsSolarTerm=unavailable', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.defaultProduction);
      expect(provider.getCapabilities().solarTerm, 'unavailable');
    });
    test('debug/internal → supportsSolarTerm=internal', () {
      provider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      expect(provider.getCapabilities().solarTerm, 'internal');
    });
  });
}

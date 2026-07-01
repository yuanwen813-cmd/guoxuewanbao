import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_feature_flag.dart';

void main() {
  final p = LocalCalendarProvider();

  group('v0.47 public display', () {
    test('publicEnabled → solarTerm available', () { p.setPublicFlag(SolarTermPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).solarTerm.available, true); });
    test('publicDisabled → solarTerm unavailable', () { p.setPublicFlag(SolarTermPublicFeatureFlag.defaultDisabled); expect(p.getDayInfo(DateTime(2026,6,22)).solarTerm.available, false); });
    test('no internal/trial/candidate in source when public', () { p.setPublicFlag(SolarTermPublicFeatureFlag.publicEnabled); final d=p.getDayInfo(DateTime(2026,6,22)); expect(d.solarTerm.basis.contains('trial'), false); });
    test('lunar unaffected', () { p.setPublicFlag(SolarTermPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).lunar.available, true); });
    test('zodiac unaffected', () { p.setPublicFlag(SolarTermPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).zodiac.available, true); });
    test('ganzhi still unavailable', () { p.setPublicFlag(SolarTermPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.available, false); });
    test('clash still unavailable', () { p.setPublicFlag(SolarTermPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).clash.available, false); });
  });
}

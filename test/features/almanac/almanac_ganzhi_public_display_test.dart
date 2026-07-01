import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
import 'package:guoxueapp/infrastructure/calendar/ganzhi_public_feature_flag.dart';
void main() {
  final p = LocalCalendarProvider();
  group('v0.49 public display', () {
    test('publicEnabled → ganzhi available', () { p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.available, true); });
    test('publicDisabled → ganzhi unavailable', () { p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.defaultDisabled); expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.available, false); });
    test('lunar unaffected', () { p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).lunar.available, true); });
    test('zodiac unaffected', () { p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).zodiac.available, true); });
    test('clash still unavailable', () { p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.publicEnabled); expect(p.getDayInfo(DateTime(2026,6,22)).clash.available, false); });
    test('no internal in source when public', () { p.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.publicEnabled); final b=p.getDayInfo(DateTime(2026,6,22)).ganzhi.basis; expect(b.toString().contains('internal'), false); });
  });
}

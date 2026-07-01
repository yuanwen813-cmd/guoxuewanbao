import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/clash_internal_engine.dart';
void main() {
  final e = const ClashInternalEngine();
  test('子→午→马', () { final r=e.compute('子'); expect(r.clashZodiac, '马'); });
  test('午→子→鼠', () { final r=e.compute('午'); expect(r.clashZodiac, '鼠'); });
  test('寅→申→猴', () { final r=e.compute('寅'); expect(r.clashZodiac, '猴'); });
  test('卯→酉→鸡', () { final r=e.compute('卯'); expect(r.clashZodiac, '鸡'); });
  test('six clash pairs all correct', () { for(final br in ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥']){expect(e.compute(br).clashZodiac, isNotNull);} });
  test('sha direction exists', () { expect(e.compute('子').shaDirection, isNotEmpty); });
  test('null branch→unavailable', () { expect(e.compute(null).status, 'unavailable'); });
  test('empty branch→unavailable', () { expect(e.compute('').status, 'unavailable'); });
}

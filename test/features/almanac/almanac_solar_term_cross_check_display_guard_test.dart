import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
void main(){final p=LocalCalendarProvider();
group('page during cross-check (v0.29)',(){
test('solarTerm',()=>expect(p.getDayInfo(DateTime(2026,6,22)).solarTerm.displayText,'节气信息暂未启用'));
test('ganzhi',()=>expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.displayText,'干支信息暂未启用'));
test('lunar',()=>expect(p.getDayInfo(DateTime(2026,6,22)).lunar.available,true));
test('zodiac',()=>expect(p.getDayInfo(DateTime(2026,6,22)).zodiac.available,true));
test('clash',()=>expect(p.getDayInfo(DateTime(2026,6,22)).clash.displayText,'冲煞信息暂未启用'));
});
}

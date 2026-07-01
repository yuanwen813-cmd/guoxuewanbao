import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
void main(){final p=LocalCalendarProvider();
group('CalendarProvider during manual review (v0.30)',() {
test('solarTerm',()=>expect(p.getCapabilities().solarTerm,'unavailable'));
test('ganzhiMonth',()=>expect(p.getCapabilities().monthGanzhi,'unavailable'));
test('lunar',()=>expect(p.getCapabilities().lunarDate,'full'));
test('zodiac',()=>expect(p.getCapabilities().zodiac,'full'));
test('clash',()=>expect(p.getCapabilities().clash,'unavailable'));
});
group('getDayInfo',() {
test('solarTerm',()=>expect(p.getDayInfo(DateTime(2026,6,22)).solarTerm.available,false));
test('ganzhi',()=>expect(p.getDayInfo(DateTime(2026,6,22)).ganzhi.available,false));
test('lunar',()=>expect(p.getDayInfo(DateTime(2026,6,22)).lunar.available,true));
test('zodiac',()=>expect(p.getDayInfo(DateTime(2026,6,22)).zodiac.available,true));
});
}

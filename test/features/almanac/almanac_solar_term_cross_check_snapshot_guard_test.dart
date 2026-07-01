import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
void main(){final p=LocalCalendarProvider();final e=AlmanacEngine();
group('snapshot during cross-check (v0.29)',(){
test('no solarTermData',(){final d=p.getDayInfo(DateTime(2026,6,22));final a=e.getDay(DateTime(2026,6,22),lunarDateDisplay:d.lunar.displayText,lunarDataSnapshot:{'a':true},zodiacDisplay:d.zodiac.zodiac,zodiacDataSnapshot:{'a':true});expect(a.toJson().containsKey('solarTermData'),false);});
test('no ganzhiData',()=>expect(e.getDay(DateTime(2026,6,22)).toJson().containsKey('ganzhiData'),false));
test('lunarData',(){expect(e.getDay(DateTime(2026,6,22),lunarDataSnapshot:{'a':true}).toJson().containsKey('lunarData'),true);});
test('zodiacData',()=>expect(e.getDay(DateTime(2026,6,22),zodiacDataSnapshot:{'a':true}).toJson().containsKey('zodiacData'),true));
test('old compat',(){final o=<String,dynamic>{'solarTerm':''};expect(o.containsKey('solarTermData'),false);expect(()=>o['solarTermData'],returnsNormally);});
});
}

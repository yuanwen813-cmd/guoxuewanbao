import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/almanac/almanac_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/calendar_provider.dart';
void main(){final p=LocalCalendarProvider();final e=AlmanacEngine();
group('snapshot during audit (v0.33)',(){
test('no solarTermData',(){final d=p.getDayInfo(DateTime(2026,6,22));final a=e.getDay(DateTime(2026,6,22),lunarDateDisplay:d.lunar.displayText,lunarDataSnapshot:{'a':true},zodiacDisplay:d.zodiac.zodiac,zodiacDataSnapshot:{'a':true});expect(a.toJson().containsKey('solarTermData'),false);});
test('no trialSolarTermData',(){expect(e.getDay(DateTime(2026,6,22)).toJson().containsKey('trialSolarTermData'),false);});
test('no ganzhiData',()=>expect(e.getDay(DateTime(2026,6,22)).toJson().containsKey('ganzhiData'),false));
test('lunarData',(){expect(e.getDay(DateTime(2026,6,22),lunarDataSnapshot:{'a':true}).toJson().containsKey('lunarData'),true);});
test('zodiacData',(){final a2=e.getDay(DateTime(2026,6,22),zodiacDataSnapshot:{'a':true});expect(a2.toJson().containsKey('zodiacData'),true);});
});
}

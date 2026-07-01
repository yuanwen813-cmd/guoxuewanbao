import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/calendar/ganzhi.dart';

void main() {
  group('DiZhi.fromHour', () {
    test('uses Beijing civil hour ranges for earthly branches', () {
      expect(DiZhi.fromHour(23), DiZhi.zi);
      expect(DiZhi.fromHour(0), DiZhi.zi);
      expect(DiZhi.fromHour(1), DiZhi.chou);
      expect(DiZhi.fromHour(3), DiZhi.yin);
      expect(DiZhi.fromHour(5), DiZhi.mao);
      expect(DiZhi.fromHour(7), DiZhi.chen);
      expect(DiZhi.fromHour(9), DiZhi.si);
      expect(DiZhi.fromHour(11), DiZhi.wu);
      expect(DiZhi.fromHour(13), DiZhi.wei);
      expect(DiZhi.fromHour(15), DiZhi.shen);
      expect(DiZhi.fromHour(17), DiZhi.you);
      expect(DiZhi.fromHour(19), DiZhi.xu);
      expect(DiZhi.fromHour(21), DiZhi.hai);
    });
  });
}

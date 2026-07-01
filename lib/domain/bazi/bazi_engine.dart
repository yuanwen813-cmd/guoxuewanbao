import '../calendar/ganzhi.dart';
import 'bazi_chart.dart';
import 'bazi_input.dart';
import 'pillar.dart';

/// 八字排盘引擎（简版 MVP）
///
/// 默认规则：
/// - 时区：北京时间
/// - 月柱：以节气切月（简化使用节气近似）
/// - 日柱：按北京时间日期计算
/// - 子时：默认晚子时换日
/// - 真太阳时：第一版不启用
class BaziEngine {
  const BaziEngine();

  /// 年柱：以立春为界
  /// 简化算法：使用公历年份推算
  GanZhi _calculateYearPillar(int year) {
    // 年天干：(year - 4) % 10
    // 年地支：(year - 4) % 12
    final tgIndex = (year - 4) % 10;
    final dzIndex = (year - 4) % 12;
    return GanZhi(TianGan.fromOrder(tgIndex), DiZhi.fromOrder(dzIndex));
  }

  /// 月柱：按节气切月，简化使用五虎遁
  GanZhi _calculateMonthPillar(int yearGanIndex, int month) {
    // 五虎遁：甲己之年丙作首，乙庚之岁戊为头...
    const monthGanOffset = [2, 4, 6, 8, 0, 2, 4, 6, 8, 0]; // 按年干定正月天干
    final januaryGan = monthGanOffset[yearGanIndex % 10];
    final monthGan = (januaryGan + month - 1) % 10;

    // 月支：正月寅(2) ... 十二月丑(1)
    final monthZhi = (month + 1) % 12;

    return GanZhi(TianGan.fromOrder(monthGan), DiZhi.fromOrder(monthZhi));
  }

  /// 日柱：简化计算（使用公历日期基数推算）
  GanZhi _calculateDayPillar(int year, int month, int day) {
    // 1900-01-01 的干支基数
    final days = _daysSince1900(year, month, day);
    final tgIndex = (days + 10) % 10;
    final dzIndex = (days + 12) % 12;
    return GanZhi(TianGan.fromOrder(tgIndex), DiZhi.fromOrder(dzIndex));
  }

  /// 时柱：五鼠遁
  GanZhi _calculateHourPillar(int dayGanIndex, int hour) {
    // 五鼠遁：甲己还加甲，乙庚丙作初...
    const hourGanOffset = [0, 2, 4, 6, 8, 0, 2, 4, 6, 8];
    final ziHourGan = (hourGanOffset[dayGanIndex % 10]) % 10;

    final hourZhiIndex = DiZhi.fromHour(hour).order;
    final hourGan = (ziHourGan + hourZhiIndex) % 10;

    return GanZhi(TianGan.fromOrder(hourGan), DiZhi.fromOrder(hourZhiIndex));
  }

  /// 自 1900-01-01 的天数
  int _daysSince1900(int year, int month, int day) {
    int days = 0;
    for (int y = 1900; y < year; y++) {
      days += _isLeapYear(y) ? 366 : 365;
    }
    const monthDays = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    days += monthDays[month - 1];
    days += day - 1;
    if (month > 2 && _isLeapYear(year)) days++;
    return days;
  }

  bool _isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);

  BaziChart calculate(BaziInput input) {
    if (!input.isValid()) {
      throw ArgumentError('八字输入不合法');
    }

    final yearPillarGz = _calculateYearPillar(input.year);
    final monthPillarGz = _calculateMonthPillar(yearPillarGz.tianGan.order, input.month);
    final dayPillarGz = _calculateDayPillar(input.year, input.month, input.day);
    final hourPillarGz = _calculateHourPillar(dayPillarGz.tianGan.order, input.hour);

    return BaziChart(
      yearPillar: Pillar(ganzhi: yearPillarGz, name: '年柱'),
      monthPillar: Pillar(ganzhi: monthPillarGz, name: '月柱'),
      dayPillar: Pillar(ganzhi: dayPillarGz, name: '日柱'),
      hourPillar: Pillar(ganzhi: hourPillarGz, name: '时柱'),
    );
  }
}

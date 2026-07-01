import 'ganzhi.dart';
import 'lunar_date.dart';
import 'solar_term.dart';

/// 历法引擎 —— 公历与农历互转、干支计算、节气查询
class CalendarEngine {
  const CalendarEngine();

  /// 公历转农历（简化实现，MVP 使用占位数据）
  LunarDate toLunar(int year, int month, int day) {
    // TODO: 接入完整农历转换表
    // 参考寿星万年历算法或香港天文台数据
    return LunarDate(year: year, month: month, day: day);
  }

  /// 获取日干支
  GanZhi dayGanZhi(int year, int month, int day) {
    int days = 0;
    for (int y = 1900; y < year; y++) {
      days += _isLeapYear(y) ? 366 : 365;
    }
    const monthDays = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    days += monthDays[month - 1];
    days += day - 1;
    if (month > 2 && _isLeapYear(year)) days++;

    return GanZhi(
      TianGan.fromOrder((days + 10) % 10),
      DiZhi.fromOrder((days + 12) % 12),
    );
  }

  /// 获取当前近似节气
  SolarTerm currentSolarTerm(int month, int day) {
    return SolarTerm.approximate(month, day);
  }

  /// 获取时辰的地支
  DiZhi hourZhi(int hour) => DiZhi.fromHour(hour);

  bool _isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

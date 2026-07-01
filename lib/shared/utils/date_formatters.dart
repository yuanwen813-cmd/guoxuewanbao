/// 日期格式化工具
class DateFormatters {
  DateFormatters._();

  /// 格式化八字显示
  static String formatBaziChart(Map<String, dynamic> chart) {
    final year = chart['yearPillar'] ?? '';
    final month = chart['monthPillar'] ?? '';
    final day = chart['dayPillar'] ?? '';
    final hour = chart['hourPillar'] ?? '';
    return '$year $month $day $hour';
  }

  /// 格式化农历日期
  static String formatLunarDate(int year, int month, int day, {bool isLeap = false}) {
    final leap = isLeap ? '闰' : '';
    return '农历$year年$leap$month月$day';
  }
}

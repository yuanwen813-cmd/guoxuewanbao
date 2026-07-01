/// 农历日期模型
class LunarDate {
  final int year;
  final int month;
  final int day;
  final bool isLeapMonth;

  const LunarDate({
    required this.year,
    required this.month,
    required this.day,
    this.isLeapMonth = false,
  });

  @override
  String toString() {
    final leap = isLeapMonth ? '闰' : '';
    return '农历$year年$leap${month}月$day';
  }
}

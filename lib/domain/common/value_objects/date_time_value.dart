/// 日期时间值对象
class DateTimeValue {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;

  const DateTimeValue({
    required this.year,
    required this.month,
    required this.day,
    this.hour = 0,
    this.minute = 0,
  });

  bool isValid() {
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (hour < 0 || hour > 23) return false;
    if (minute < 0 || minute > 59) return false;
    return true;
  }

  @override
  String toString() => '$year-$month-$day $hour:$minute';

  @override
  bool operator ==(Object other) =>
      other is DateTimeValue &&
      other.year == year &&
      other.month == month &&
      other.day == day &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(year, month, day, hour, minute);
}

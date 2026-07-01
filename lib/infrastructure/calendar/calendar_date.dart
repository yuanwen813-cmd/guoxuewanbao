/// UTC-noon 日期规范化工具 v0.54
/// 避免时区/DST 边界导致的日期偏移
class CalendarDate {
  final int year;
  final int month;
  final int day;

  const CalendarDate(this.year, this.month, this.day);

  factory CalendarDate.fromDateTime(DateTime date) =>
      CalendarDate(date.year, date.month, date.day);

  DateTime toUtcNoon() => DateTime.utc(year, month, day, 12);

  int daysUntil(CalendarDate other) =>
      other.toUtcNoon().difference(toUtcNoon()).inDays;

  @override
  String toString() => '$year-${month.toString().padLeft(2,'0')}-${day.toString().padLeft(2,'0')}';
}

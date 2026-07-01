/// 通用校验器
class Validators {
  Validators._();

  static String? required(String? value, [String fieldName = '此字段']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName不能为空';
    }
    return null;
  }

  static bool isValidYear(int year) => year >= 1900 && year <= 2100;

  static bool isValidMonth(int month) => month >= 1 && month <= 12;

  static bool isValidDay(int day) => day >= 1 && day <= 31;

  static bool isValidHour(int hour) => hour >= 0 && hour <= 23;

  static bool isValidDate(int year, int month, int day) {
    return isValidYear(year) && isValidMonth(month) && isValidDay(day);
  }
}

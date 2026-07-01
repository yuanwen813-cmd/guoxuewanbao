/// 性别
enum Gender { male('男'), female('女');

  final String chinese;
  const Gender(this.chinese);
}

/// 八字输入
class BaziInput {
  /// 出生年份（公历）
  final int year;

  /// 出生月份（公历，1-12）
  final int month;

  /// 出生日（公历，1-31）
  final int day;

  /// 出生小时（0-23）
  final int hour;

  /// 性别
  final Gender gender;

  const BaziInput({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    this.gender = Gender.male,
  });

  bool isValid() {
    if (year < 1900 || year > 2100) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (hour < 0 || hour > 23) return false;
    return true;
  }

  @override
  String toString() => '${year}年${month}月${day}日 $hour时 (${gender.chinese})';
}

import '../calendar/ganzhi.dart';

/// 小六壬输入
class XiaoLiuRenInput {
  /// 农历月 (1-12)
  final int lunarMonth;

  /// 农历日 (1-30)
  final int lunarDay;

  /// 时辰（地支）
  final DiZhi hourBranch;

  const XiaoLiuRenInput({
    required this.lunarMonth,
    required this.lunarDay,
    required this.hourBranch,
  });

  bool isValid() {
    return lunarMonth >= 1 && lunarMonth <= 12 &&
        lunarDay >= 1 && lunarDay <= 30;
  }
}

import 'xiaoliuren_input.dart';
import 'xiaoliuren_result.dart';

/// 小六壬掌诀推算引擎
/// 算法：月上起日，日上起时
///   1. 从寅位（大安）起正月，顺数至月 → 得月位
///   2. 从月位起初一，顺数至日 → 得日位
///   3. 从日位起子时，顺数至时辰 → 得最终掌位
class XiaoLiuRenEngine {
  const XiaoLiuRenEngine();

  /// 推算掌诀位置
  XiaoLiuRenResult calculate(XiaoLiuRenInput input) {
    if (!input.isValid()) {
      throw ArgumentError('小六壬输入不合法：月=${input.lunarMonth}, 日=${input.lunarDay}');
    }

    // 第一步：月上起日
    // 从寅位（大安=0）起正月，顺数至输入月份
    int monthPosition = (input.lunarMonth - 1) % 6;

    // 第二步：从月位起初一，顺数至输入日期
    int dayPosition = (monthPosition + input.lunarDay - 1) % 6;

    // 第三步：从日位起子时（子=0），顺数至输入时辰
    int finalPosition = (dayPosition + input.hourBranch.order) % 6;

    final result = PalmPosition.values[finalPosition];

    return XiaoLiuRenResult(
      position: result,
      month: input.lunarMonth,
      day: input.lunarDay,
      hourBranchName: input.hourBranch.chinese,
    );
  }
}

import 'wuxing.dart';

/// 五行生克关系
enum ShengKe {
  same('同我'),
  iGenerate('我生'),
  generateMe('生我'),
  iOvercome('我克'),
  overcomeMe('克我');

  final String label;
  const ShengKe(this.label);

  /// 计算 a 相对于 b 的生克关系
  static ShengKe relation(WuXing a, WuXing b) {
    if (a == b) return ShengKe.same;
    if (a.generates == b) return ShengKe.iGenerate;
    if (a.generatedBy == b) return ShengKe.generateMe;
    if (a.overcomes == b) return ShengKe.iOvercome;
    return ShengKe.overcomeMe;
  }
}

import '../hexagram/yao.dart';

/// 一次铜钱摇卦结果
class CoinThrow {
  /// 三枚铜钱的正面向上的数量 (0-3)
  final int heads;

  const CoinThrow(this.heads);

  /// 对应的爻
  Yao get yao => Yao.fromCoinToss(heads);

  /// 摇卦描述
  String get description {
    switch (heads) {
      case 3: return '三正 → 老阳 ○';
      case 2: return '两正一反 → 少阳 —';
      case 1: return '一正两反 → 少阴 --';
      case 0: return '三反 → 老阴 ×';
      default: return '未知';
    }
  }
}

/// 六次摇卦结果（从初爻到上爻）
class SixCoinThrows {
  final List<CoinThrow> throws; // length == 6, index 0 = 初爻

  const SixCoinThrows(this.throws) : assert(throws.length == 6);

  List<Yao> get yaos => throws.map((t) => t.yao).toList();
}

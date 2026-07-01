/// 爻
enum Yao {
  yang(1, '⚊', '—', '阳爻'),
  yin(0, '⚋', '--', '阴爻'),
  oldYang(3, '⚌', '○→--', '老阳（变爻）'),
  oldYin(2, '⚍', '×→—', '老阴（变爻）');

  final int value;
  final String symbol;
  final String notation;
  final String label;

  const Yao(this.value, this.symbol, this.notation, this.label);

  /// 是否为变爻
  bool get isChanging => this == oldYang || this == oldYin;

  /// 变爻后的爻
  Yao get changed {
    switch (this) {
      case oldYang: return yin;
      case oldYin: return yang;
      default: return this;
    }
  }

  /// 从钱币（3枚铜钱的正反面数）推爻
  /// 三个正面 = 老阳 (9)
  /// 两正一反 = 少阴 (8)
  /// 一正两反 = 少阳 (7)
  /// 三个反面 = 老阴 (6)
  static Yao fromCoinToss(int heads) {
    switch (heads) {
      case 3: return oldYang;
      case 2: return yang;
      case 1: return yin;
      case 0: return oldYin;
      default: throw ArgumentError('Invalid coin toss count: $heads');
    }
  }
}

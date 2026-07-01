/// 五行
enum WuXing {
  wood(0, '木'),
  fire(1, '火'),
  earth(2, '土'),
  metal(3, '金'),
  water(4, '水');

  final int order;
  final String chinese;

  const WuXing(this.order, this.chinese);

  /// 五行相生：木→火→土→金→水→木
  WuXing get generates => WuXing.values[(order + 1) % 5];

  /// 五行相克：木→土→水→火→金→木
  WuXing get overcomes => WuXing.values[(order + 2) % 5];

  /// 我生者（子女）
  WuXing get generatedBy => WuXing.values[(order + 4) % 5];

  /// 克我者（官杀）
  WuXing get overcomeBy => WuXing.values[(order + 3) % 5];
}

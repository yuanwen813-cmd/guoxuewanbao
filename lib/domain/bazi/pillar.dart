import '../calendar/ganzhi.dart';
import '../wuxing/wuxing.dart';

/// 四柱之一（年柱/月柱/日柱/时柱）
class Pillar {
  final GanZhi ganzhi;
  final String name; // '年柱', '月柱', '日柱', '时柱'

  const Pillar({required this.ganzhi, required this.name});

  TianGan get tianGan => ganzhi.tianGan;
  DiZhi get diZhi => ganzhi.diZhi;
  WuXing get wuxing => WuXing.values.firstWhere(
        (w) => w.chinese == tianGan.wuxing,
        orElse: () => WuXing.wood,
      );

  @override
  String toString() => '$name: ${ganzhi.chineseName}';
}

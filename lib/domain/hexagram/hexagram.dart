import 'yao.dart';

/// 八卦
enum BaGua {
  qian(0, '乾', '☰', '天'),
  dui(1, '兑', '☱', '泽'),
  li(2, '离', '☲', '火'),
  zhen(3, '震', '☳', '雷'),
  xun(4, '巽', '☴', '风'),
  kan(5, '坎', '☵', '水'),
  gen(6, '艮', '☶', '山'),
  kun(7, '坤', '☷', '地');

  final int order;
  final String chinese;
  final String symbol;
  final String nature;

  const BaGua(this.order, this.chinese, this.symbol, this.nature);

  /// 从三条爻组成八卦
  static BaGua fromYaoList(List<Yao> yaos) {
    assert(yaos.length == 3);
    final key = yaos.map((y) => y.value % 2).join();
    const mapping = {
      '111': BaGua.qian,
      '110': BaGua.dui,
      '101': BaGua.li,
      '100': BaGua.zhen,
      '011': BaGua.xun,
      '010': BaGua.kan,
      '001': BaGua.gen,
      '000': BaGua.kun,
    };
    return mapping[key]!;
  }
}

/// 六十四卦
class LiuSiGua {
  final int index;        // 0-63, 按《周易》顺序
  final String name;      // 卦名
  final BaGua upperGua;   // 上卦（外卦）
  final BaGua lowerGua;   // 下卦（内卦）
  final String judgment;  // 卦辞（简版）
  final List<String> yaoTexts; // 六条爻辞

  const LiuSiGua({
    required this.index,
    required this.name,
    required this.upperGua,
    required this.lowerGua,
    required this.judgment,
    required this.yaoTexts,
  });

  /// 从上下卦组合构建
  factory LiuSiGua.fromGuaPair(BaGua upper, BaGua lower) {
    final idx = upper.order * 8 + lower.order;
    // 基础数据将从 assets/data/hexagram/ 加载
    // 这里是占位实现
    return LiuSiGua(
      index: idx,
      name: '${upper.chinese}${lower.chinese}卦',
      upperGua: upper,
      lowerGua: lower,
      judgment: '',
      yaoTexts: List.filled(6, ''),
    );
  }

  /// 本卦与变卦
  static ({LiuSiGua original, LiuSiGua? changed}) resolve(
    List<Yao> sixYaos,
  ) {
    final upperYao = sixYaos.sublist(3, 6);
    final lowerYao = sixYaos.sublist(0, 3);

    final original = LiuSiGua.fromGuaPair(
      BaGua.fromYaoList(upperYao),
      BaGua.fromYaoList(lowerYao),
    );

    final hasChange = sixYaos.any((y) => y.isChanging);
    if (!hasChange) return (original: original, changed: null);

    final changedUpper = upperYao.map((y) => y.changed).toList();
    final changedLower = lowerYao.map((y) => y.changed).toList();

    final changed = LiuSiGua.fromGuaPair(
      BaGua.fromYaoList(changedUpper),
      BaGua.fromYaoList(changedLower),
    );

    return (original: original, changed: changed);
  }
}

import '../hexagram/hexagram.dart';
import '../hexagram/yao.dart';

/// 金钱卦计算结果
class MoneyHexagramResult {
  /// 本卦
  final LiuSiGua originalHexagram;

  /// 变卦（无变爻时为 null）
  final LiuSiGua? changedHexagram;

  /// 六条爻
  final List<Yao> sixYaos;

  /// 变爻位置 (1-6，从初爻起)
  final List<int> changingYaoPositions;

  const MoneyHexagramResult({
    required this.originalHexagram,
    this.changedHexagram,
    required this.sixYaos,
    required this.changingYaoPositions,
  });

  Map<String, dynamic> toJson() => {
    'method': 'money_hexagram',
    'originalHexagram': {
      'index': originalHexagram.index,
      'name': originalHexagram.name,
      'judgment': originalHexagram.judgment,
      'upperGua': originalHexagram.upperGua.chinese,
      'lowerGua': originalHexagram.lowerGua.chinese,
    },
    if (changedHexagram != null)
      'changedHexagram': {
        'index': changedHexagram!.index,
        'name': changedHexagram!.name,
        'judgment': changedHexagram!.judgment,
      },
    'yaos': sixYaos.asMap().entries.map((e) => {
      'position': e.key + 1,
      'type': e.value.label,
      'isChanging': e.value.isChanging,
    }).toList(),
    'changingYaoPositions': changingYaoPositions,
  };
}

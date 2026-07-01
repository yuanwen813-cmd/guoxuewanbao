import 'hexagram.dart';
import 'yao.dart';

/// 六十四卦引擎
class HexagramEngine {
  const HexagramEngine();

  /// 从六条爻解析卦象（从初爻到上爻）
  ({LiuSiGua original, LiuSiGua? changed}) resolveHexagram(List<Yao> sixYaos) {
    assert(sixYaos.length == 6);
    return LiuSiGua.resolve(sixYaos);
  }

  /// 获取八卦
  BaGua getGuaFromYaos(List<Yao> threeYaos) {
    return BaGua.fromYaoList(threeYaos);
  }
}

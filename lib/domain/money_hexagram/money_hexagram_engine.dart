import 'dart:math';

import '../hexagram/hexagram.dart';
import '../hexagram/yao.dart';
import 'coin_throw.dart';
import 'money_hexagram_input.dart';
import 'money_hexagram_result.dart';

/// 金钱卦引擎
/// 六次摇卦，每次三枚铜钱，从初爻到上爻
class MoneyHexagramEngine {
  final Random? _random;

  const MoneyHexagramEngine({Random? random}) : _random = random;

  /// 生成一次随机摇卦（3 枚铜钱的正反面数）
  int _tossCoins(Random rng) {
    // 每枚铜钱：0=反面, 1=正面
    return [rng.nextInt(2), rng.nextInt(2), rng.nextInt(2)]
        .fold(0, (sum, v) => sum + v);
  }

  /// 计算金钱卦
  MoneyHexagramResult calculate(MoneyHexagramInput input) {
    final rng = _random ?? Random();

    final tosses = <CoinThrow>[];
    for (int i = 0; i < 6; i++) {
      final heads = input.coinTossHeads?[i] ?? _tossCoins(rng);
      tosses.add(CoinThrow(heads));
    }

    final sixCoinThrows = SixCoinThrows(tosses);
    final yaos = sixCoinThrows.yaos;

    final (:original, :changed) = LiuSiGua.resolve(yaos);

    final changingPositions = <int>[];
    for (int i = 0; i < yaos.length; i++) {
      if (yaos[i].isChanging) changingPositions.add(i + 1); // 1-indexed
    }

    return MoneyHexagramResult(
      originalHexagram: original,
      changedHexagram: changed,
      sixYaos: yaos,
      changingYaoPositions: changingPositions,
    );
  }
}

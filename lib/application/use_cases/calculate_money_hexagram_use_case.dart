import '../../domain/common/result.dart';
import '../../domain/money_hexagram/money_hexagram_engine.dart';
import '../../domain/money_hexagram/money_hexagram_input.dart';
import '../../domain/money_hexagram/money_hexagram_result.dart';

/// 金钱卦计算用例
class CalculateMoneyHexagramUseCase {
  final MoneyHexagramEngine _engine;

  const CalculateMoneyHexagramUseCase(this._engine);

  DomainResult<MoneyHexagramResult> execute(MoneyHexagramInput input) {
    try {
      final result = _engine.calculate(input);
      return Success(result);
    } catch (e) {
      return Failure('金钱卦计算失败', cause: e);
    }
  }
}

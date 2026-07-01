import '../../domain/bazi/bazi_chart.dart';
import '../../domain/bazi/bazi_engine.dart';
import '../../domain/bazi/bazi_input.dart';
import '../../domain/common/result.dart';

/// 八字计算用例
class CalculateBaziUseCase {
  final BaziEngine _engine;

  const CalculateBaziUseCase(this._engine);

  DomainResult<BaziChart> execute(BaziInput input) {
    try {
      final result = _engine.calculate(input);
      return Success(result);
    } on ArgumentError catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('八字排盘失败', cause: e);
    }
  }
}

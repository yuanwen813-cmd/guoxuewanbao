import '../../domain/common/result.dart';
import '../../domain/xiaoliuren/xiaoliuren_engine.dart';
import '../../domain/xiaoliuren/xiaoliuren_input.dart';
import '../../domain/xiaoliuren/xiaoliuren_result.dart';

/// 小六壬计算用例
class CalculateXiaoLiuRenUseCase {
  final XiaoLiuRenEngine _engine;

  const CalculateXiaoLiuRenUseCase(this._engine);

  DomainResult<XiaoLiuRenResult> execute(XiaoLiuRenInput input) {
    try {
      final result = _engine.calculate(input);
      return Success(result);
    } on ArgumentError catch (e) {
      return Failure(e.message);
    } catch (e) {
      return Failure('小六壬计算失败', cause: e);
    }
  }
}

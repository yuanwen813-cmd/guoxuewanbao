import '../dto/interpretation.dart';
import '../ports/ai_port.dart';

/// AI 结果解读用例
class InterpretResultUseCase {
  final AiPort _aiPort;

  const InterpretResultUseCase(this._aiPort);

  Future<Interpretation> execute({
    required String methodId,
    required Map<String, dynamic> resultData,
    required String userQuestion,
  }) async {
    try {
      return await _aiPort.interpret(
        methodId: methodId,
        resultData: resultData,
        userQuestion: userQuestion,
      );
    } catch (_) {
      return Interpretation.fallback();
    }
  }
}

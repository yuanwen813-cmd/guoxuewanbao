import '../dto/interpretation.dart';
import '../dto/method_recommendation.dart';

/// AI 服务抽象接口
abstract class AiPort {
  /// 方法推荐
  Future<List<MethodRecommendation>> recommendMethods(String userIntent);

  /// 结果解读
  Future<Interpretation> interpret({
    required String methodId,
    required Map<String, dynamic> resultData,
    required String userQuestion,
  });
}

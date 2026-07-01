import '../../application/dto/interpretation.dart';
import '../../application/dto/method_recommendation.dart';
import '../../application/ports/ai_port.dart';
import 'ai_json_repair.dart';
import 'ai_response_parser.dart';
import 'deepseek_client.dart';
import 'prompt_registry.dart';

/// AI 网关 —— 实现 AiPort，封装 DeepSeek 调用、解析、修复、兜底全流程
class AiGateway implements AiPort {
  final DeepSeekClient _client;
  final PromptRegistry _promptRegistry;
  final AiResponseParser _parser;
  final AiJsonRepair _repair;

  AiGateway({
    String? apiKey,
    String? proxyUrl,
    PromptRegistry? promptRegistry,
  })  : _client = DeepSeekClient(apiKey: apiKey, proxyUrl: proxyUrl),
        _promptRegistry = promptRegistry ?? PromptRegistry.instance,
        _parser = const AiResponseParser(),
        _repair = AiJsonRepair(apiKey: apiKey ?? '');

  @override
  Future<List<MethodRecommendation>> recommendMethods(String userIntent) async {
    try {
      final prompt = await _promptRegistry.buildRecommendationPrompt(
        userIntent: userIntent,
      );

      final raw = await _client.chat(
        systemPrompt: '你是国学命理方法推荐助手。只返回 JSON。',
        userPrompt: prompt,
      );

      return _parser.parseRecommendations(raw);
    } on AiParseException catch (_) {
      // 解析失败，可以尝试修复，MVP 阶段直接返回空列表
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Interpretation> interpret({
    required String methodId,
    required Map<String, dynamic> resultData,
    required String userQuestion,
  }) async {
    try {
      final prompt = await _promptRegistry.buildInterpretationPrompt(
        methodId: methodId,
        resultData: resultData,
        userQuestion: userQuestion,
      );

      final raw = await _client.chat(
        systemPrompt: '你是国学命理解读专家。只返回 JSON，格式：{"classical":"","vernacular":"","advice":"","tags":[]}',
        userPrompt: prompt,
        temperature: 0.8,
        maxTokens: 2048,
      );

      return _parser.parseInterpretation(raw);
    } on AiParseException {
      // TODO: 触发 JSON 修复
      return Interpretation.fallback();
    } on DeepSeekException {
      return Interpretation.fallback();
    } catch (_) {
      return Interpretation.fallback();
    }
  }
}

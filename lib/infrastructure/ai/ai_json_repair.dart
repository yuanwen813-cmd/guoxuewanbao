import 'package:dio/dio.dart';

/// JSON 修复器 —— 当 AI 返回非法 JSON 时尝试修复
class AiJsonRepair {
  final Dio _dio;
  final String _apiKey;

  AiJsonRepair({required String apiKey, String? baseUrl})
      : _apiKey = apiKey,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? 'https://api.deepseek.com',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ));

  /// 尝试修复非法 JSON
  Future<String> repair({
    required String raw,
    required String expectedSchema,
  }) async {
    try {
      final response = await _dio.post('/v1/chat/completions', data: {
        'model': 'deepseek-chat',
        'messages': [
          {
            'role': 'system',
            'content': '你是一个 JSON 修复器。请修复以下非法 JSON，只返回合法的 JSON，不要任何解释。\n'
                '期望格式：$expectedSchema',
          },
          {
            'role': 'user',
            'content': '修复以下内容为合法 JSON：\n$raw',
          },
        ],
        'temperature': 0.0,
        'max_tokens': 1024,
      });

      return response.data['choices'][0]['message']['content'] as String;
    } catch (_) {
      rethrow;
    }
  }
}

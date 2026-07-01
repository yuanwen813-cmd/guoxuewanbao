import 'package:dio/dio.dart';

/// DeepSeek API 客户端
/// 支持两种模式：
/// - 直连：baseUrl = https://api.deepseek.com，需 API Key
/// - 代理：proxyUrl = http://localhost:3000/api/interpret，Key 由代理持有
class DeepSeekClient {
  final Dio _dio;
  final String? _apiKey;
  final String? _proxyUrl;
  final bool _useProxy;

  DeepSeekClient({String? apiKey, String? baseUrl, String? proxyUrl})
      : _apiKey = apiKey,
        _proxyUrl = proxyUrl,
        _useProxy = proxyUrl != null && proxyUrl.isNotEmpty,
        _dio = Dio(BaseOptions(
          baseUrl: proxyUrl ?? baseUrl ?? 'https://api.deepseek.com',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
          headers: (proxyUrl != null && proxyUrl.isNotEmpty)
              ? {'Content-Type': 'application/json'}
              : {
                  'Authorization': 'Bearer ${apiKey ?? ''}',
                  'Content-Type': 'application/json',
                },
        ));

  /// 发送对话请求
  Future<String> chat({
    required String systemPrompt,
    required String userPrompt,
    String model = 'deepseek-chat',
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    try {
      final path = _useProxy ? '' : '/v1/chat/completions';
      final response = await _dio.post(path, data: {
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      });

      // 代理返回格式与 DeepSeek 一致
      return response.data['choices'][0]['message']['content'] as String;
    } on DioException catch (e) {
      throw DeepSeekException.fromDioError(e);
    }
  }
}

/// DeepSeek 异常
class DeepSeekException implements Exception {
  final String message;
  final int? statusCode;

  const DeepSeekException(this.message, {this.statusCode});

  factory DeepSeekException.fromDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = switch (statusCode) {
      401 => 'API Key 无效，请在设置中配置有效的 Key。',
      402 => 'API 额度不足，请检查账户余额。',
      429 => '请求过于频繁，请稍后重试。',
      _ => 'AI 服务暂时不可用（${e.message}）',
    };
    return DeepSeekException(message, statusCode: statusCode);
  }

  @override
  String toString() => 'DeepSeekException: $message';
}

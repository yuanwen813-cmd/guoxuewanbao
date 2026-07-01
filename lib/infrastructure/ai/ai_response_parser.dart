import 'dart:convert';

import '../../application/dto/interpretation.dart';
import '../../application/dto/method_recommendation.dart';

/// AI 响应解析器
class AiResponseParser {
  const AiResponseParser();

  /// 解析解读结果
  Interpretation parseInterpretation(String raw) {
    try {
      final json = _safeJsonDecode(raw);
      return Interpretation.fromJson(json);
    } catch (e) {
      throw AiParseException('AI 解读结果解析失败: $raw', cause: e);
    }
  }

  /// 解析方法推荐结果
  List<MethodRecommendation> parseRecommendations(String raw) {
    try {
      final json = _safeJsonDecode(raw);
      final list = json['recommendations'] as List;
      return list
          .map((e) => MethodRecommendation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AiParseException('方法推荐解析失败: $raw', cause: e);
    }
  }

  /// 安全 JSON 解析（处理 markdown code block 包裹）
  Map<String, dynamic> _safeJsonDecode(String raw) {
    String trimmed = raw.trim();

    // 去除 markdown 代码块包裹
    if (trimmed.startsWith('```')) {
      final endIdx = trimmed.lastIndexOf('```');
      if (endIdx > 3) {
        trimmed = trimmed.substring(3, endIdx).trim();
        // 移除语言标识
        final newlineIdx = trimmed.indexOf('\n');
        if (newlineIdx > 0) {
          trimmed = trimmed.substring(newlineIdx + 1).trim();
        }
      }
    }

    return json.decode(trimmed) as Map<String, dynamic>;
  }
}

/// AI 解析异常
class AiParseException implements Exception {
  final String message;
  final Object? cause;

  const AiParseException(this.message, {this.cause});

  @override
  String toString() => 'AiParseException: $message';
}

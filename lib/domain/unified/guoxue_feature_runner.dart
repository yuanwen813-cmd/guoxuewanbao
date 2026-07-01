import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../app/registry/feature_registry.dart';
import '../../infrastructure/ai/deepseek_client_factory.dart';
import '../../infrastructure/ai/prompt_registry.dart';
import 'guoxue_engine.dart';
import 'unified_models.dart';

/// 统一功能运行器
///
/// 职责：
/// 1. 调用本地引擎计算
/// 2. 可选调用 AI 生成解读
/// 3. 合并结果
/// 4. 处理 AI 失败兜底
///
/// 使用方式：
///   final runner = GuoxueFeatureRunner(feature: config, engine: myEngine);
///   final result = await runner.run(input, question: '我的问题');
class GuoxueFeatureRunner {
  final FeatureConfig feature;
  final GuoxueEngine _engine;
  final PromptRegistry _promptRegistry;

  GuoxueFeatureRunner({
    required this.feature,
    required GuoxueEngine engine,
    PromptRegistry? promptRegistry,
  })  : _engine = engine,
        _promptRegistry = promptRegistry ?? PromptRegistry.instance;

  /// 运行功能（本地计算 + 可选 AI）
  Future<GuoxueResult> run(
    dynamic input, {
    String? userQuestion,
    bool enableAI = true,
  }) async {
    // 1. 验证输入
    final error = _engine.validate(input);
    if (error != null) {
      throw ArgumentError(error);
    }

    // 2. 本地计算
    debugPrint('[FeatureRunner] ${feature.id} → 本地计算');
    final result = _engine.calculate(input);

    // 3. AI 解读（可选）
    if (enableAI && feature.supportsAI) {
      try {
        debugPrint('[FeatureRunner] ${feature.id} → AI解读');
        final aiResult = await _callAI(result, userQuestion ?? '');
        return result.withAi(aiResult);
      } catch (e) {
        debugPrint('[FeatureRunner] ${feature.id} → AI失败，使用本地结果: $e');
        return result.withAi(AiInterpretation.fallback());
      }
    }

    return result;
  }

  /// 调用 AI 解读
  Future<AiInterpretation> _callAI(
    GuoxueResult result,
    String userQuestion,
  ) async {
    // 构建提示词
    final prompt = await _promptRegistry.buildInterpretationPrompt(
      methodId: feature.promptTemplateId ?? feature.id,
      resultData: result.rawData,
      userQuestion: userQuestion.isNotEmpty
          ? userQuestion
          : '${feature.title}推算',
    );

    // 调用 AI 网关（通过代理，API Key 由服务端持有）
    final client = await createDeepSeekClient();
    final raw = await client.chat(
      systemPrompt: '你是国学命理解读专家。必须返回合法JSON，格式为：{"classical":"专业解读...","vernacular":"白话释义...","advice":"建议...","tags":["标签1"]}',
      userPrompt: prompt,
      temperature: 0.8,
      maxTokens: 2048,
    );

    // 解析
    return _parseAIResponse(raw);
  }

  /// 解析 AI 返回
  AiInterpretation _parseAIResponse(String raw) {
    try {
      final json = _cleanJson(raw);
      return AiInterpretation(
        classical: json['classical'] as String? ?? '',
        vernacular: json['vernacular'] as String? ?? '',
        advice: json['advice'] as String? ?? '',
        tags: (json['tags'] as List?)?.cast<String>() ?? [],
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[FeatureRunner] JSON解析失败: $e');
      return AiInterpretation.fallback();
    }
  }

  Map<String, dynamic> _cleanJson(String raw) {
    String s = raw.trim();
    if (s.startsWith('```')) {
      final end = s.lastIndexOf('```');
      if (end > 3) s = s.substring(3, end).trim();
      final nl = s.indexOf('\n');
      if (nl > 0 && nl < 20) s = s.substring(nl + 1).trim();
    }
    return json.decode(s) as Map<String, dynamic>;
  }
}

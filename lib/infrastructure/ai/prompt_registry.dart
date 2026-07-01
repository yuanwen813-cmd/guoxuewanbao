import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

/// Prompt 注册中心 —— 从 assets/prompts/ 加载 YAML 模板
class PromptRegistry {
  PromptRegistry._();

  static final PromptRegistry instance = PromptRegistry._();

  final Map<String, String> _cache = {};

  /// 初始化：预加载所有 prompt 模板
  Future<void> init() async {
    final manifests = [
      'recommend_method',
      'xiaoliuren_interpret',
      'money_hexagram_interpret',
      'bazi_interpret',
      'almanac_interpret',
    ];

    for (final name in manifests) {
      try {
        final yamlStr = await rootBundle.loadString('assets/prompts/$name.yaml');
        _cache[name] = yamlStr;
      } catch (_) {
        // 模板文件可能尚未添加，静默跳过
      }
    }

    // 加载安全规则
    try {
      final safety = await rootBundle.loadString(
        'assets/prompts/common/safety_rules.yaml',
      );
      _cache['safety_rules'] = safety;
    } catch (_) {}
  }

  /// 构建解读提示词
  Future<String> buildInterpretationPrompt({
    required String methodId,
    required Map<String, dynamic> resultData,
    required String userQuestion,
  }) async {
    final templateName = '${methodId}_interpret';
    final template = _cache[templateName] ?? '';
    final safetyRules = _cache['safety_rules'] ?? '';

    final resultStr = resultData.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');

    return '''
$safetyRules

$template

【用户占卜事项】
$userQuestion

【本地推算结果】
$resultStr

【输出要求】
你必须严格按照以下3部分输出，每部分至少150字，内容充实详细：

第1部分：专业术语解读
- 用国学、术数、命理的专业术语，详细解释本次推算结果的含义
- 引用相关古籍、典故，说明推算依据
- 解释各要素之间的生克关系和吉凶判断

第2部分：白话文释义
- 把第1部分的专业内容翻译成通俗易懂的白话文
- 让完全没有国学基础的普通人也能完全理解
- 详细说明各项结果在实际生活中代表什么

第3部分：事项解读与建议
- 针对用户所问的"$userQuestion"，结合推算结果给出白话解读
- 说明此结果对用户所问事项的具体影响和趋势
- 给出3-5条切实可行的参考建议（仅供传统文化研究参考，不构成决策依据）

输出JSON格式：{"classical":"第1部分内容","vernacular":"第2部分内容","advice":"第3部分内容","tags":["标签1","标签2"]}
''';
  }

  /// 构建方法推荐提示词
  Future<String> buildRecommendationPrompt({
    required String userIntent,
  }) async {
    final template = _cache['recommend_method'] ?? '';
    final safetyRules = _cache['safety_rules'] ?? '';

    return '''
$safetyRules

$template

用户想了解：$userIntent

请推荐最合适的术数方法。
''';
  }

  /// 获取安全规则
  String getSafetyRules() {
    return _cache['safety_rules'] ?? _defaultSafetyRules;
  }

  static const String _defaultSafetyRules = '''
1. 不得使用"必死、必破财、一定离婚、马上发财"等绝对化表达。
2. 不得诱导用户做医疗、法律、投资、婚姻等重大决策。
3. 只能以传统文化、民俗、娱乐参考的方式表达。
4. 涉及健康、法律、投资问题时，建议用户咨询专业人士。
5. 不得恐吓用户，不得制造焦虑。
6. 请避免绝对化、恐吓式、承诺式表达。
7. 不要声称可以保证改命、发财、复合、避灾。
''';
}

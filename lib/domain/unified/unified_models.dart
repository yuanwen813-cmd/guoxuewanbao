/// 统一结果模型 —— 所有国学功能的输出都归一化为这个结构
///
/// 设计原则：
/// - 任何功能的结果都是 sections 列表
/// - 每个 section 可以是纯文本、键值对、表格、或占位符
/// - AI 解读是可选附件
/// - 本地计算结果与 AI 解读分离，AI 失败不影响本地结果展示

/// 功能状态
enum FeatureStatus { stable, beta, aiOnly, comingSoon }

/// 结果区块
class ResultSection {
  final String title;       // 区块标题，如"八字排盘"、"掌诀结果"
  final String? icon;       // 可选 Material Icon 名
  final ResultSectionType type;
  final String? text;       // type=text 时使用
  final List<MapEntry<String, String>>? kvPairs; // type=kvTable 时使用
  final List<String>? tags; // type=tags 时使用
  final List<List<String>>? table; // type=table 时使用（第一行为表头）

  const ResultSection({
    required this.title,
    this.icon,
    this.type = ResultSectionType.text,
    this.text,
    this.kvPairs,
    this.tags,
    this.table,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'icon': icon,
    'type': type.name,
    if (text != null) 'text': text,
    if (kvPairs != null) 'kvPairs': kvPairs!.map((e) => {'k': e.key, 'v': e.value}).toList(),
    if (tags != null) 'tags': tags,
    if (table != null) 'table': table,
  };
}

enum ResultSectionType { text, kvTable, tags, table }

/// AI 解读
class AiInterpretation {
  final String classical;    // 专业术语版
  final String vernacular;   // 白话释义
  final String advice;       // 事项解读+建议
  final List<String> tags;
  final DateTime? generatedAt;
  final bool isFallback;     // 是否为兜底内容

  const AiInterpretation({
    required this.classical,
    required this.vernacular,
    required this.advice,
    this.tags = const [],
    this.generatedAt,
    this.isFallback = false,
  });

  factory AiInterpretation.fallback() => AiInterpretation(
    classical: '本地推算已生成，AI 解读暂时不可用。',
    vernacular: '测算结果已基于传统算法生成。由于 AI 服务暂时不可用，本次无法生成白话解读。你可以稍后重试。',
    advice: '请稍后重试 AI 解读，或先查看本地推算的原始结果。',
    tags: ['AI暂不可用'],
    isFallback: true,
  );

  factory AiInterpretation.fromInterpretation(
    dynamic interp, {bool isFallback = false}
  ) {
    // 兼容旧 Interpretation 模型
    return AiInterpretation(
      classical: interp.classical?.toString() ?? '',
      vernacular: interp.vernacular?.toString() ?? '',
      advice: interp.advice?.toString() ?? '',
      tags: (interp.tags as List?)?.cast<String>() ?? [],
      isFallback: isFallback,
    );
  }

  Map<String, dynamic> toJson() => {
    'classical': classical,
    'vernacular': vernacular,
    'advice': advice,
    'tags': tags,
    'isFallback': isFallback,
  };
}

/// 统一国学结果
class GuoxueResult {
  final String featureId;
  final String featureTitle;
  final String categoryId;
  final DateTime createdAt;
  final List<ResultSection> sections;
  final AiInterpretation? aiInterpretation;
  final Map<String, dynamic> rawData; // 原始数据，用于 AI 提示词构建

  const GuoxueResult({
    required this.featureId,
    required this.featureTitle,
    required this.categoryId,
    required this.createdAt,
    required this.sections,
    this.aiInterpretation,
    this.rawData = const {},
  });

  /// 带 AI 解读的副本
  GuoxueResult withAi(AiInterpretation ai) => GuoxueResult(
    featureId: featureId,
    featureTitle: featureTitle,
    categoryId: categoryId,
    createdAt: createdAt,
    sections: sections,
    aiInterpretation: ai,
    rawData: rawData,
  );

  Map<String, dynamic> toJson() => {
    'featureId': featureId,
    'featureTitle': featureTitle,
    'categoryId': categoryId,
    'createdAt': createdAt.toIso8601String(),
    'sections': sections.map((s) => s.toJson()).toList(),
    'aiInterpretation': aiInterpretation?.toJson(),
    'rawData': rawData,
  };
}

/// 统一历史记录
class HistoryRecord {
  final String id;
  final String featureId;
  final String featureTitle;
  final String categoryId;
  final String? userQuestion;
  final Map<String, dynamic> inputData;
  final Map<String, dynamic> resultJson;
  final DateTime createdAt;
  final bool favorite;

  const HistoryRecord({
    required this.id,
    required this.featureId,
    required this.featureTitle,
    required this.categoryId,
    this.userQuestion,
    this.inputData = const {},
    required this.resultJson,
    required this.createdAt,
    this.favorite = false,
  });

  factory HistoryRecord.fromGuoxueResult(
    GuoxueResult result, {
    String? userQuestion,
    Map<String, dynamic> inputData = const {},
    String? id,
  }) {
    return HistoryRecord(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      featureId: result.featureId,
      featureTitle: result.featureTitle,
      categoryId: result.categoryId,
      userQuestion: userQuestion,
      inputData: inputData,
      resultJson: result.toJson(),
      createdAt: result.createdAt,
    );
  }
}

/// 输入字段配置
class InputFieldConfig {
  final String key;
  final String label;
  final InputFieldType type;
  final bool required;
  final String? hint;
  final dynamic defaultValue;
  final List<dynamic>? options; // 下拉选项
  final int? maxLength;
  final int? maxLines;
  final num? min;
  final num? max;

  const InputFieldConfig({
    required this.key,
    required this.label,
    this.type = InputFieldType.text,
    this.required = false,
    this.hint,
    this.defaultValue,
    this.options,
    this.maxLength,
    this.maxLines = 1,
    this.min,
    this.max,
  });
}

enum InputFieldType {
  text,       // 单行文本
  multiline,  // 多行文本
  number,     // 数字
  dropdown,   // 下拉选择
  date,       // 日期选择
  gender,     // 性别选择
}

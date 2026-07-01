/// AI 解读结果
class Interpretation {
  final String classical;   // 国学术语版
  final String vernacular;  // 通俗白话版
  final String advice;      // 可执行建议
  final String? riskNote;   // 风险提示
  final List<String> tags;  // 标签

  const Interpretation({
    required this.classical,
    required this.vernacular,
    required this.advice,
    this.riskNote,
    this.tags = const [],
  });

  factory Interpretation.fromJson(Map<String, dynamic> json) {
    return Interpretation(
      classical: json['classical'] as String? ?? '',
      vernacular: json['vernacular'] as String? ?? '',
      advice: json['advice'] as String? ?? '',
      riskNote: json['riskNote'] as String?,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'classical': classical,
    'vernacular': vernacular,
    'advice': advice,
    if (riskNote != null) 'riskNote': riskNote,
    'tags': tags,
  };

  /// 兜底解读
  factory Interpretation.fallback() => const Interpretation(
    classical: '测算结果已生成，AI 解读暂时不可用。',
    vernacular: '本地测算结果已生成，但 AI 解读暂时失败。你可以稍后重试，或先查看基础结果。',
    advice: '请稍后重试 AI 解读。',
    riskNote: '本结果基于传统术数模型计算，仅供文化研究参考。',
    tags: ['待解读'],
  );
}

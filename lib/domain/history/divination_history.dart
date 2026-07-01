import 'dart:convert';

/// 占卜历史记录
class DivinationHistory {
  final String id;
  final String featureId;
  final String featureName;
  final String? question;
  final DateTime createdAt;
  final String summary;
  final String resultJson;
  final List<String> tags;
  final bool isFavorite;

  const DivinationHistory({
    required this.id,
    required this.featureId,
    required this.featureName,
    this.question,
    required this.createdAt,
    required this.summary,
    required this.resultJson,
    this.tags = const [],
    this.isFavorite = false,
  });

  Map<String, dynamic> get resultSnapshot => json.decode(resultJson) as Map<String, dynamic>;

  Map<String, dynamic> toJson() => {
    'id': id, 'featureId': featureId, 'featureName': featureName,
    'question': question, 'createdAt': createdAt.toIso8601String(),
    'summary': summary, 'resultJson': resultJson, 'tags': tags, 'isFavorite': isFavorite,
  };

  factory DivinationHistory.fromJson(Map<String, dynamic> j) => DivinationHistory(
    id: j['id'] as String, featureId: j['featureId'] as String,
    featureName: j['featureName'] as String, question: j['question'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
    summary: j['summary'] as String? ?? '', resultJson: j['resultJson'] as String? ?? '{}',
    tags: (j['tags'] as List?)?.cast<String>() ?? [],
    isFavorite: j['isFavorite'] as bool? ?? false,
  );
}

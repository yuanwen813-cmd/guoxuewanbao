/// 占卜历史记录
class DivinationRecord {
  final String id;
  final String methodId;
  final String methodName;
  final String question;
  final Map<String, dynamic> inputJson;
  final Map<String, dynamic> resultJson;
  final Map<String, dynamic>? interpretationJson;
  final DateTime createdAt;
  final bool favorite;

  const DivinationRecord({
    required this.id,
    required this.methodId,
    required this.methodName,
    required this.question,
    required this.inputJson,
    required this.resultJson,
    this.interpretationJson,
    required this.createdAt,
    this.favorite = false,
  });
}

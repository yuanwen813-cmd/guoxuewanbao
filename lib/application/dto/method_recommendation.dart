/// AI 方法推荐结果
class MethodRecommendation {
  final String methodId;
  final String methodName;
  final String reason;
  final List<String> requiredInputs;
  final int priority;

  const MethodRecommendation({
    required this.methodId,
    required this.methodName,
    required this.reason,
    required this.requiredInputs,
    required this.priority,
  });

  factory MethodRecommendation.fromJson(Map<String, dynamic> json) {
    return MethodRecommendation(
      methodId: json['methodId'] as String,
      methodName: json['methodName'] as String,
      reason: json['reason'] as String,
      requiredInputs: List<String>.from(json['requiredInputs'] as List),
      priority: json['priority'] as int,
    );
  }
}

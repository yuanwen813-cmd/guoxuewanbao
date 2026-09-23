import 'dart:convert';

import 'ai_report_product_config.dart';

String buildAiReportUserPrompt({
  required AiReportProductConfig config,
  required String focus,
  String? sourceJson,
  String? sourceSummary,
}) {
  var source = sourceJson?.trim().isNotEmpty == true
      ? sourceJson!.trim()
      : (sourceSummary ?? '').trim();
  final isNatal = config.featureKey == AiReportFeatureKeys.bazi ||
      config.featureKey == AiReportFeatureKeys.ziweiDoushu ||
      config.featureKey == AiReportFeatureKeys.tiebanShenshu;
  String? timeDescription = isNatal ? null : '起卦时间：原始记录未提供。';
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(decoded)
        ..remove('aiReports')
        ..remove('interpretation');
      final rawTime = data['castTimeUtc'] ?? data['createdAt'];
      if (!isNatal && rawTime is String) {
        final time = DateTime.tryParse(rawTime);
        final hasZone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(rawTime);
        if (time != null && hasZone) {
          final beijing = time.toUtc().add(const Duration(hours: 8));
          final display = beijing.toIso8601String().replaceFirst('Z', '');
          timeDescription = '原始起卦时间：$display+08:00（北京时间 UTC+8，不作真太阳时换算）。';
        } else {
          timeDescription = '原始记录时间：$rawTime；旧记录未保存可靠时区。';
        }
      }
      source = jsonEncode(data);
    }
  } on FormatException {
    // Natal pages already provide a labelled plain-text birth/chart summary.
  }
  return [
    config.featureName,
    '所问之事或关注方向：$focus',
    if (timeDescription != null) timeDescription,
    '原始资料：',
    source,
    '请解读。',
  ].join('\n');
}

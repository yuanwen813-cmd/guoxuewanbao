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
  String? timeDescription;
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      final data = Map<String, dynamic>.from(decoded)
        ..remove('aiReports')
        ..remove('interpretation');
      final rawTime = data['castTimeUtc'] ?? data['createdAt'];
      if (rawTime is String) {
        final time = DateTime.tryParse(rawTime);
        final hasZone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(rawTime);
        if (time != null && hasZone) {
          final beijing = time.toUtc().add(const Duration(hours: 8));
          final display = beijing.toIso8601String().replaceFirst('Z', '');
          timeDescription = '原始起卦时间：$display+08:00（北京时间 UTC+8，不作真太阳时换算）。';
        } else {
          timeDescription = '原始记录时间：$rawTime；旧记录未保存可靠时区，不据此臆定日辰、月建或精确应期。';
        }
      }
      source = jsonEncode(data);
    }
  } on FormatException {
    // Natal pages already provide a labelled plain-text birth/chart summary.
  }
  return [
    '功能：${config.featureKey}；报告类型：${config.reportType}。',
    '所问之事或关注方向：$focus',
    '篇幅：${config.minWords}-${config.maxWords} 字。',
    AiReportPromptTemplates.templates[config.promptTemplateId] ?? '',
    if (timeDescription != null) timeDescription,
    '以下为原始资料，请据此解读：',
    source,
  ].join('\n');
}

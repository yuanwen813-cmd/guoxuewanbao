import 'package:flutter/material.dart';

import '../ai_reports/ai_report_product_config.dart';
import '../ai_reports/ai_report_product_panel.dart';

class DestinyAiExplanationCard extends StatelessWidget {
  final String title;
  final String description;
  final String systemPrompt;
  final String contextText;
  final String inputKeyName;
  final String buttonKeyName;

  const DestinyAiExplanationCard({
    super.key,
    required this.title,
    required this.description,
    required this.systemPrompt,
    required this.contextText,
    required this.inputKeyName,
    required this.buttonKeyName,
  });

  @override
  Widget build(BuildContext context) {
    return AiReportProductPanel(
      featureKey: _featureKey,
      sourceSummary: contextText,
      sourceJson: contextText,
    );
  }

  String get _featureKey {
    if (buttonKeyName.contains('tieban') || inputKeyName.contains('tieban')) {
      return AiReportFeatureKeys.tiebanShenshu;
    }
    if (buttonKeyName.contains('ziwei') || inputKeyName.contains('ziwei')) {
      return AiReportFeatureKeys.ziweiDoushu;
    }
    return AiReportFeatureKeys.bazi;
  }
}

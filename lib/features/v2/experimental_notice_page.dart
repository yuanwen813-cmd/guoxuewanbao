import 'package:flutter/material.dart';

import 'feature_catalog_v2.dart';
import 'v2_page_scaffold.dart';

class ExperimentalNoticePage extends StatelessWidget {
  final String featureId;

  const ExperimentalNoticePage({super.key, required this.featureId});

  @override
  Widget build(BuildContext context) {
    final content = _contentById[featureId] ??
        _ExperimentalContent.defaultContent(featureId);
    return V2PageScaffold(
      title: content.title,
      subtitle: content.subtitle,
      icon: content.icon,
      showAppBar: true,
      children: [
        V2FeatureTile(
          entry: FeatureEntryV2(
            id: featureId,
            title: content.title,
            subtitle: content.detail,
            route: '',
            icon: content.icon,
            category: content.category,
            status: FeatureStatusV2.trialPlanned,
            actionLabel: FeatureStatusV2.trialPlanned.label,
          ),
        ),
      ],
    );
  }
}

class _ExperimentalContent {
  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;
  final FeatureCategoryV2 category;

  const _ExperimentalContent({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.icon,
    required this.category,
  });

  factory _ExperimentalContent.defaultContent(String featureId) {
    return _ExperimentalContent(
      title: '试运行规划',
      subtitle: '此能力尚未进入正式可用状态。',
      detail: '当前标识：$featureId。未成熟能力不会公开宣称准确，也不会接真实支付。',
      icon: Icons.science_outlined,
      category: FeatureCategoryV2.home,
    );
  }
}

const _contentById = {
  'tieban-shenshu': _ExperimentalContent(
    title: '铁板神数',
    subtitle: '传统流派复杂，先标记为试运行规划。',
    detail: '本版本只做命盘区入口，不实现正式推算、不做准确性承诺、不接商业化。',
    icon: Icons.functions,
    category: FeatureCategoryV2.natal,
  ),
};

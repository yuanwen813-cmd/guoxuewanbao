import 'package:flutter/material.dart';

import 'feature_catalog_v2.dart';

enum NatalResultSectionType {
  lifeOverview('life_overview'),
  baziPillars('bazi_pillars'),
  annualFortune('annual_fortune'),
  monthlyFortune('monthly_fortune'),
  tiebanShenshu('tieban_shenshu');

  final String routeValue;

  const NatalResultSectionType(this.routeValue);

  static NatalResultSectionType fromRouteValue(String value) {
    return NatalResultSectionType.values.firstWhere(
      (type) => type.routeValue == value,
      orElse: () => NatalResultSectionType.lifeOverview,
    );
  }
}

class NatalResultSectionSpec {
  final NatalResultSectionType type;
  final String title;
  final IconData icon;
  final FeatureStatusV2 status;
  final String statusText;
  final String positioning;

  const NatalResultSectionSpec({
    required this.type,
    required this.title,
    required this.icon,
    required this.status,
    required this.statusText,
    required this.positioning,
  });
}

const natalResultSectionSpecs = [
  NatalResultSectionSpec(
    type: NatalResultSectionType.lifeOverview,
    title: '本命总览',
    icon: Icons.account_tree_outlined,
    status: FeatureStatusV2.stable,
    statusText: '已生成命盘结构、本命摘要、五行分布与日主参考。',
    positioning: '汇总出生资料、四柱结构、生肖、五行摘要和本命基础参考。',
  ),
  NatalResultSectionSpec(
    type: NatalResultSectionType.baziPillars,
    title: '八字四柱',
    icon: Icons.calendar_month_outlined,
    status: FeatureStatusV2.stable,
    statusText: '已生成年柱、月柱、日柱与时柱结构。',
    positioning: '查看年柱、月柱、日柱、时柱，以及天干地支、五行和阴阳属性。',
  ),
  NatalResultSectionSpec(
    type: NatalResultSectionType.annualFortune,
    title: '流年运势',
    icon: Icons.insights_outlined,
    status: FeatureStatusV2.stable,
    statusText: '已生成近五年流年参考。',
    positioning: '按流年干支与日主五行关系，查看年度节奏和行动参考。',
  ),
  NatalResultSectionSpec(
    type: NatalResultSectionType.monthlyFortune,
    title: '月度运势',
    icon: Icons.calendar_view_month_outlined,
    status: FeatureStatusV2.stable,
    statusText: '已生成当前年份十二个月参考。',
    positioning: '按月令与日主五行关系，查看每月阶段性节奏。',
  ),
];

NatalResultSectionSpec natalResultSectionSpecOf(
  NatalResultSectionType type,
) {
  return natalResultSectionSpecs.firstWhere((spec) => spec.type == type);
}

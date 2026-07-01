import 'package:flutter/material.dart';

import 'feature_catalog_v2.dart';
import 'v2_page_scaffold.dart';

class ComingSoonPage extends StatelessWidget {
  final String featureId;

  const ComingSoonPage({super.key, required this.featureId});

  @override
  Widget build(BuildContext context) {
    final content =
        _contentById[featureId] ?? _ComingSoonContent.defaultContent(featureId);
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
            status: content.status,
            actionLabel: content.status.label,
          ),
        ),
      ],
    );
  }
}

class _ComingSoonContent {
  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;
  final FeatureCategoryV2 category;
  final FeatureStatusV2 status;

  const _ComingSoonContent({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.icon,
    required this.category,
    required this.status,
  });

  factory _ComingSoonContent.defaultContent(String featureId) {
    return _ComingSoonContent(
      title: '功能占位',
      subtitle: '这个入口已经预留，后续版本会继续完善。',
      detail: '当前标识：$featureId。未完成验收的能力会继续保持预留状态。',
      icon: Icons.pending_outlined,
      category: FeatureCategoryV2.home,
      status: FeatureStatusV2.comingSoon,
    );
  }
}

const _contentById = {
  'birth-profile': _ComingSoonContent(
    title: '命盘档案',
    subtitle: '命盘档案将在 v0.57 建设。',
    detail: '当前只保留入口，后续会补齐 BirthProfile 资料采集、档案管理和档案详情。',
    icon: Icons.account_circle_outlined,
    category: FeatureCategoryV2.natal,
    status: FeatureStatusV2.comingSoon,
  ),
  'natal-profiles': _ComingSoonContent(
    title: '命盘档案',
    subtitle: '查看和管理已保存的出生资料档案。',
    detail: '命盘档案可用于自己、家人、朋友或客户。为他人保存出生资料前，请确认已获得对方同意。',
    icon: Icons.badge_outlined,
    category: FeatureCategoryV2.natal,
    status: FeatureStatusV2.comingSoon,
  ),
  'bazi-four-pillars': _ComingSoonContent(
    title: '八字四柱',
    subtitle: '后续试运行，不在本版正式推算。',
    detail: '节气换月、干支月柱等能力完成验收前，只作为命盘区占位。',
    icon: Icons.calendar_month_outlined,
    category: FeatureCategoryV2.natal,
    status: FeatureStatusV2.comingSoon,
  ),
  'yearly-fortune': _ComingSoonContent(
    title: '年度流年',
    subtitle: '后续承接年度趋势报告。',
    detail: '此能力依赖本命档案和命盘底座，本版本不生成正式报告。',
    icon: Icons.insights_outlined,
    category: FeatureCategoryV2.natal,
    status: FeatureStatusV2.comingSoon,
  ),
  'monthly-fortune': _ComingSoonContent(
    title: '月度运势',
    subtitle: '后续承接月度趋势报告。',
    detail: '此能力会在命盘底座完成后继续建设，本版本只预留入口。',
    icon: Icons.calendar_view_month_outlined,
    category: FeatureCategoryV2.natal,
    status: FeatureStatusV2.comingSoon,
  ),
  'daily-yiji': _ComingSoonContent(
    title: '每日宜忌',
    subtitle: '从今日黄历中提炼更清晰的宜忌入口。',
    detail: '当前请先查看今日黄历；独立宜忌页后续再补齐。',
    icon: Icons.checklist_outlined,
    category: FeatureCategoryV2.calendar,
    status: FeatureStatusV2.comingSoon,
  ),
  'solar-terms': _ComingSoonContent(
    title: '节气',
    subtitle: '保持审慎试运行。',
    detail: '节气能力此前以审计、观察和证据包方式推进，正式验收前不作为稳定功能公开主推。',
    icon: Icons.ac_unit,
    category: FeatureCategoryV2.calendar,
    status: FeatureStatusV2.experimental,
  ),
  'date-selection': _ComingSoonContent(
    title: '择日',
    subtitle: '复杂择日后续独立验证后再开放。',
    detail: '择日会涉及更复杂的规则和准确性边界，本版本只保留入口。',
    icon: Icons.event_available_outlined,
    category: FeatureCategoryV2.calendar,
    status: FeatureStatusV2.comingSoon,
  ),
  'takashima-reference': _ComingSoonContent(
    title: '高岛易断资料',
    subtitle: '作为资料参考，与问事功能区分。',
    detail: '高岛易断的断事能力已放在问事页；资料入口后续用于整理原文、案例和术语。',
    icon: Icons.travel_explore_outlined,
    category: FeatureCategoryV2.classics,
    status: FeatureStatusV2.comingSoon,
  ),
  'glossary': _ComingSoonContent(
    title: '术语解释',
    subtitle: '常见术语和概念后续补齐。',
    detail: '此入口用于降低阅读经典和占断结果时的理解门槛。',
    icon: Icons.manage_search_outlined,
    category: FeatureCategoryV2.classics,
    status: FeatureStatusV2.comingSoon,
  ),
  'my-natal': _ComingSoonContent(
    title: '命盘档案',
    subtitle: '命盘档案将在 v0.57 建设。',
    detail: '后续会沉淀 BirthProfile 出生资料档案，本版本不采集完整出生资料。',
    icon: Icons.account_box_outlined,
    category: FeatureCategoryV2.mine,
    status: FeatureStatusV2.comingSoon,
  ),
  'my-reports': _ComingSoonContent(
    title: '我的报告',
    subtitle: '后续承接月报、年报和专项报告。',
    detail: '报告复看会基于已生成的 AI 报告订单，不会重复扣费。',
    icon: Icons.description_outlined,
    category: FeatureCategoryV2.mine,
    status: FeatureStatusV2.comingSoon,
  ),
  'favorites': _ComingSoonContent(
    title: '收藏',
    subtitle: '沉淀常看资料和重点结果。',
    detail: '收藏能力会在用户资产体系中继续完善。',
    icon: Icons.bookmark_border,
    category: FeatureCategoryV2.mine,
    status: FeatureStatusV2.comingSoon,
  ),
};

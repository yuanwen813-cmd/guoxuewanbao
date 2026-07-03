import 'package:flutter/material.dart';

enum FeatureCategoryV2 {
  home,
  ask,
  natal,
  calendar,
  classics,
  mine,
}

enum FeatureStatusV2 {
  stable,
  beta,
  trialPlanned,
  comingSoon,
  experimental,
  hidden,
}

extension FeatureStatusV2Label on FeatureStatusV2 {
  String get label => switch (this) {
        FeatureStatusV2.stable => '可用',
        FeatureStatusV2.beta => '试用',
        FeatureStatusV2.trialPlanned => '试运行规划',
        FeatureStatusV2.comingSoon => '待开放',
        FeatureStatusV2.experimental => '实验',
        FeatureStatusV2.hidden => '隐藏',
      };

  bool get isVisible => this != FeatureStatusV2.hidden;
}

class FeatureEntryV2 {
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final FeatureCategoryV2 category;
  final FeatureStatusV2 status;
  final String actionLabel;

  const FeatureEntryV2({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.category,
    required this.status,
    required this.actionLabel,
  });

  bool get isVisible => status.isVisible;
}

class FeatureCatalogV2 {
  FeatureCatalogV2._();

  static const homeHighlights = [
    FeatureEntryV2(
      id: 'almanac',
      title: '今日黄历',
      subtitle: '查看今日宜忌，了解适合与不适合做的事。',
      route: '/tools/almanac',
      icon: Icons.today,
      category: FeatureCategoryV2.calendar,
      status: FeatureStatusV2.stable,
      actionLabel: '查看',
    ),
    FeatureEntryV2(
      id: 'daily_hexagram',
      title: '今日一卦',
      subtitle: '每日一卦，给今天一个传统文化参考。',
      route: '/daily_hexagram',
      icon: Icons.auto_awesome,
      category: FeatureCategoryV2.ask,
      status: FeatureStatusV2.stable,
      actionLabel: '抽取',
    ),
    FeatureEntryV2(
      id: 'quick_ask',
      title: '快速问事',
      subtitle: '有件事拿不准？用金钱卦、小六壬、梅花易数、高岛易断帮你理清当前局势。',
      route: '/ask',
      icon: Icons.question_answer_outlined,
      category: FeatureCategoryV2.ask,
      status: FeatureStatusV2.stable,
      actionLabel: '进入',
    ),
    FeatureEntryV2(
      id: 'natal_reading',
      title: '八字命理',
      subtitle: '输入出生信息，生成八字四柱、本命总览、流年与月度参考。',
      route: '/natal/reading',
      icon: Icons.account_circle_outlined,
      category: FeatureCategoryV2.natal,
      status: FeatureStatusV2.stable,
      actionLabel: '开始',
    ),
    FeatureEntryV2(
      id: 'zhouyi_benjing',
      title: '周易本经',
      subtitle: '查阅六十四卦、卦辞爻辞与三百八十四爻原文。',
      route: '/reference/zhouyi',
      icon: Icons.menu_book_outlined,
      category: FeatureCategoryV2.classics,
      status: FeatureStatusV2.stable,
      actionLabel: '查阅',
    ),
  ];

  static const askFeatures = [
    FeatureEntryV2(
      id: 'coin_hexagram',
      title: '金钱卦',
      subtitle: '传统正式问事，适合感情、事业、合作、选择等具体问题。',
      route: '/divination/coin_hexagram',
      icon: Icons.monetization_on_outlined,
      category: FeatureCategoryV2.ask,
      status: FeatureStatusV2.stable,
      actionLabel: '开始摇卦',
    ),
    FeatureEntryV2(
      id: 'small_liuren',
      title: '小六壬',
      subtitle: '快速判断，适合临时起意、短期趋势和当下取象。',
      route: '/divination/small_liuren',
      icon: Icons.pan_tool_alt,
      category: FeatureCategoryV2.ask,
      status: FeatureStatusV2.stable,
      actionLabel: '快速起课',
    ),
    FeatureEntryV2(
      id: 'meihua_yi',
      title: '梅花易数',
      subtitle: '以时间、事件和取象进行推演，适合灵感式断事。',
      route: '/divination/meihua',
      icon: Icons.local_florist_outlined,
      category: FeatureCategoryV2.ask,
      status: FeatureStatusV2.stable,
      actionLabel: '一念起卦',
    ),
    FeatureEntryV2(
      id: 'takashima_yi',
      title: '高岛易断',
      subtitle: '结合易卦与高岛易断思路，对具体事情进行分析。',
      route: '/divination/takashima',
      icon: Icons.grass_outlined,
      category: FeatureCategoryV2.ask,
      status: FeatureStatusV2.stable,
      actionLabel: '开始占断',
    ),
  ];

  static const natalFeatures = [
    FeatureEntryV2(
      id: 'natal_reading',
      title: '八字命理',
      subtitle: '查看结果说明，填写出生资料，生成八字四柱、本命总览、流年与月度参考，并支持 AI 详解。',
      route: '/natal/reading',
      icon: Icons.account_circle_outlined,
      category: FeatureCategoryV2.natal,
      status: FeatureStatusV2.stable,
      actionLabel: '进入',
    ),
    FeatureEntryV2(
      id: 'tieban_shenshu_standalone',
      title: '铁板神数',
      subtitle: '输入出生资料，生成铁板神数数序、核时要点与 AI 详解。',
      route: '/natal/tieban',
      icon: Icons.functions,
      category: FeatureCategoryV2.natal,
      status: FeatureStatusV2.stable,
      actionLabel: '进入',
    ),
    FeatureEntryV2(
      id: 'ziwei_doushu',
      title: '紫微斗数',
      subtitle: '输入出生资料，生成紫微斗数命盘结构、十二宫摘要与 AI 详解。',
      route: '/natal/ziwei',
      icon: Icons.stars_outlined,
      category: FeatureCategoryV2.natal,
      status: FeatureStatusV2.stable,
      actionLabel: '进入',
    ),
    FeatureEntryV2(
      id: 'birth_profiles',
      title: '命盘档案',
      subtitle: '查看和管理已保存的出生资料档案。',
      route: '/natal/profiles',
      icon: Icons.badge_outlined,
      category: FeatureCategoryV2.natal,
      status: FeatureStatusV2.stable,
      actionLabel: '管理',
    ),
  ];

  static const natalReadingModes = [
    FeatureEntryV2(
      id: 'temporary_natal_reading',
      title: '重新填写生辰信息',
      subtitle: '直接填写出生资料，生成新的八字命理结果。',
      route: '',
      icon: Icons.flash_on_outlined,
      category: FeatureCategoryV2.natal,
      status: FeatureStatusV2.stable,
      actionLabel: '当前模式',
    ),
    FeatureEntryV2(
      id: 'choose_birth_profile',
      title: '从命盘档案选择',
      subtitle: '使用已经主动保存过的出生资料，用于复看或生成新的推演结果。',
      route: '/natal/profiles',
      icon: Icons.folder_shared_outlined,
      category: FeatureCategoryV2.natal,
      status: FeatureStatusV2.stable,
      actionLabel: '选择',
    ),
  ];

  static const natalResultFeatures = [
    FeatureEntryV2(
      id: 'natal_overview',
      title: '本命总览',
      subtitle: '基于出生资料生成命盘结构、本命摘要、五行分布与日主参考。',
      route: '',
      icon: Icons.account_tree_outlined,
      category: FeatureCategoryV2.natal,
      status: FeatureStatusV2.stable,
      actionLabel: '查看',
    ),
    FeatureEntryV2(
      id: 'bazi_four_pillars',
      title: '八字四柱',
      subtitle: '根据出生年月日时生成年柱、月柱、日柱和时柱结构。',
      route: '',
      icon: Icons.calendar_month_outlined,
      category: FeatureCategoryV2.natal,
      status: FeatureStatusV2.stable,
      actionLabel: '查看',
    ),
    FeatureEntryV2(
      id: 'yearly_fortune',
      title: '流年运势',
      subtitle: '流年运势基于出生资料与指定年份进行推演，用于查看某一年事业、财运、感情与行动节奏参考。',
      route: '',
      icon: Icons.insights_outlined,
      category: FeatureCategoryV2.natal,
      status: FeatureStatusV2.stable,
      actionLabel: '查看',
    ),
    FeatureEntryV2(
      id: 'monthly_fortune',
      title: '月度运势',
      subtitle: '基于命盘与月令关系，生成十二个月的阶段性趋势参考。',
      route: '',
      icon: Icons.calendar_view_month_outlined,
      category: FeatureCategoryV2.natal,
      status: FeatureStatusV2.stable,
      actionLabel: '查看',
    ),
  ];

  static const calendarFeatures = [
    FeatureEntryV2(
      id: 'almanac',
      title: '今日黄历',
      subtitle: '查看今日宜忌、农历与生活建议',
      route: '/tools/almanac',
      icon: Icons.today,
      category: FeatureCategoryV2.calendar,
      status: FeatureStatusV2.stable,
      actionLabel: '查看',
    ),
    FeatureEntryV2(
      id: 'daily_yiji',
      title: '每日宜忌',
      subtitle: '聚合今日适合与不适合事项',
      route: '/coming-soon/daily-yiji',
      icon: Icons.checklist_outlined,
      category: FeatureCategoryV2.calendar,
      status: FeatureStatusV2.comingSoon,
      actionLabel: '占位',
    ),
    FeatureEntryV2(
      id: 'solar_terms',
      title: '节气',
      subtitle: '当前保持审慎试运行，不公开承诺稳定',
      route: '/coming-soon/solar-terms',
      icon: Icons.ac_unit,
      category: FeatureCategoryV2.calendar,
      status: FeatureStatusV2.experimental,
      actionLabel: '查看说明',
    ),
    FeatureEntryV2(
      id: 'date_selection',
      title: '择日',
      subtitle: '复杂择日后续独立验证后再开放',
      route: '/coming-soon/date-selection',
      icon: Icons.event_available_outlined,
      category: FeatureCategoryV2.calendar,
      status: FeatureStatusV2.comingSoon,
      actionLabel: '占位',
    ),
  ];

  static const classicsFeatures = [
    FeatureEntryV2(
      id: 'zhouyi_benjing',
      title: '周易本经',
      subtitle: '查阅六十四卦、卦辞爻辞与三百八十四爻原文。',
      route: '/reference/zhouyi',
      icon: Icons.menu_book_outlined,
      category: FeatureCategoryV2.classics,
      status: FeatureStatusV2.stable,
      actionLabel: '查阅',
    ),
    FeatureEntryV2(
      id: 'takashima_reference',
      title: '高岛易断资料',
      subtitle: '按六十四卦查阅卦辞、象辞、六爻、白话与高岛式断法参考。',
      route: '/reference/takashima',
      icon: Icons.library_books_outlined,
      category: FeatureCategoryV2.classics,
      status: FeatureStatusV2.stable,
      actionLabel: '查阅',
    ),
  ];

  static const mineFeatures = [
    FeatureEntryV2(
      id: 'wallet',
      title: '钱包充值',
      subtitle: '服务端钱包，用于余额充值和 AI 解析扣费。',
      route: '/wallet',
      icon: Icons.account_balance_wallet_outlined,
      category: FeatureCategoryV2.mine,
      status: FeatureStatusV2.stable,
      actionLabel: '充值',
    ),
    FeatureEntryV2(
      id: 'history',
      title: '历史记录',
      subtitle: '回看问事记录和结果快照',
      route: '/history',
      icon: Icons.history,
      category: FeatureCategoryV2.mine,
      status: FeatureStatusV2.stable,
      actionLabel: '查看',
    ),
    FeatureEntryV2(
      id: 'my_natal',
      title: '命盘档案',
      subtitle: '管理自己、家人、朋友或客户的出生资料档案',
      route: '/natal/profiles',
      icon: Icons.account_box_outlined,
      category: FeatureCategoryV2.mine,
      status: FeatureStatusV2.stable,
      actionLabel: '管理',
    ),
    FeatureEntryV2(
      id: 'my_reports',
      title: '我的报告',
      subtitle: '后续承接月报、年报和专项报告',
      route: '/coming-soon/my-reports',
      icon: Icons.description_outlined,
      category: FeatureCategoryV2.mine,
      status: FeatureStatusV2.comingSoon,
      actionLabel: '占位',
    ),
    FeatureEntryV2(
      id: 'settings',
      title: '设置',
      subtitle: '隐私声明、免责声明与本地数据管理',
      route: '/settings',
      icon: Icons.settings_outlined,
      category: FeatureCategoryV2.mine,
      status: FeatureStatusV2.stable,
      actionLabel: '进入',
    ),
  ];

  static const hiddenFeatures = [
    FeatureEntryV2(
      id: 'fengshui_suite',
      title: '风水类',
      subtitle: '准确性与产品定位未完成前不做用户侧入口',
      route: '',
      icon: Icons.explore_outlined,
      category: FeatureCategoryV2.home,
      status: FeatureStatusV2.hidden,
      actionLabel: '隐藏',
    ),
    FeatureEntryV2(
      id: 'physiognomy_suite',
      title: '相术类',
      subtitle: '准确性与合规边界未完成前不做用户侧入口',
      route: '',
      icon: Icons.face_outlined,
      category: FeatureCategoryV2.home,
      status: FeatureStatusV2.hidden,
      actionLabel: '隐藏',
    ),
  ];

  static List<FeatureEntryV2> visible(List<FeatureEntryV2> entries) {
    return entries.where((entry) => entry.isVisible).toList();
  }
}

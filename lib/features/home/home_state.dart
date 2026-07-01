import '../../domain/history/divination_history.dart';

enum DailyHexagramStatus { notDrawn, drawn, loading }

class FeatureCardConfig {
  final String featureId;
  final String featureName;
  final String subtitle;
  final String description;
  final String route;
  final String buttonLabel;
  const FeatureCardConfig({
    required this.featureId, required this.featureName,
    required this.subtitle, required this.description,
    required this.route, required this.buttonLabel,
  });
}

class HomeState {
  final String todayDate;
  final String todayTip;
  final DailyHexagramStatus dailyStatus;
  final String? dailySummary;
  final String? dailyVerdict;
  final List<DivinationHistory> recentHistories;
  final List<FeatureCardConfig> featureCards;

  const HomeState({
    required this.todayDate,
    required this.todayTip,
    required this.dailyStatus,
    this.dailySummary,
    this.dailyVerdict,
    this.recentHistories = const [],
    this.featureCards = const [],
  });

  static const tips = [
    '问事不迷信，观象为自省。',
    '一念起处，万象皆有端倪。',
    '吉凶不在卦中，进退在一念之间。',
    '以卦为镜，照见当下。',
    '今日宜静心观象，慎思而后行。',
  ];

  static const toolConfigs = [
    FeatureCardConfig(
      featureId: 'almanac', featureName: '黄历',
      subtitle: '每日宜忌，择事参考', description: '查看今日宜忌、干支与生活建议',
      route: '/tools/almanac', buttonLabel: '查看今日黄历',
    ),
  ];

  static const featureConfigs = [
    FeatureCardConfig(
      featureId: 'coin_hexagram', featureName: '金钱卦',
      subtitle: '三钱六摇，成卦问事', description: '适合有仪式感地问一件具体事情',
      route: '/divination/coin_hexagram', buttonLabel: '开始摇卦',
    ),
    FeatureCardConfig(
      featureId: 'small_liuren', featureName: '小六壬',
      subtitle: '月日时起课，临事速断', description: '适合临时问事、快速判断趋势',
      route: '/divination/small_liuren', buttonLabel: '快速起课',
    ),
    FeatureCardConfig(
      featureId: 'takashima_yi', featureName: '高岛易断',
      subtitle: '线段分策，动爻主断', description: '适合具体问题深度占断',
      route: '/divination/takashima', buttonLabel: '开始占断',
    ),
    FeatureCardConfig(
      featureId: 'meihua_yi', featureName: '梅花易数',
      subtitle: '一念三数，观象成卦', description: '适合临事起念、快速问事',
      route: '/divination/meihua', buttonLabel: '一念起卦',
    ),
  ];
}

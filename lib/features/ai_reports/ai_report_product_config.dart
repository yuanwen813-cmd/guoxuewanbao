class AiReportFeatureKeys {
  static const dailyHexagram = 'daily_hexagram';
  static const gaodaoYiduan = 'gaodao_yiduan';
  static const coinHexagram = 'coin_hexagram';
  static const xiaoliuren = 'xiaoliuren';
  static const meihuaYishu = 'meihua_yishu';
  static const bazi = 'bazi';
  static const ziweiDoushu = 'ziwei_doushu';
  static const tiebanShenshu = 'tieban_shenshu';
}

class AiReportModelIds {
  static const doubaoSeed21Pro = 'doubao-seed-2-1-pro-260915';
}

class AiReportProductConfig {
  final String id;
  final String featureKey;
  final String featureName;
  final String reportType;
  final String priceLabel;
  final String buttonTitle;
  final String buttonSubtitle;

  const AiReportProductConfig({
    required this.id,
    required this.featureKey,
    required this.featureName,
    required this.reportType,
    this.priceLabel = '¥5',
    this.buttonTitle = '¥5 AI 解析',
    this.buttonSubtitle = '根据当前事项与资料进行解析',
  });

  String get modelId => AiReportModelIds.doubaoSeed21Pro;
  String get priceTier => 'flat_5';
  bool get enabled => true;
  String? get disabledReason => null;

  static const uniformPriceCents = 500;
  int get priceCents => uniformPriceCents;
}

class AiReportProductCatalog {
  static const localTestPaymentCopy =
      'AI 报告按次从服务端钱包扣费，生成失败会自动退款。\nAI 解读基于本地生成的结构化结果生成，仅供传统文化参考。';

  static const reportFooterCopy =
      '以上内容由 AI 根据本地生成的命盘或卦象结构进行白话解读，仅供传统文化参考，不代表确定性结论，也不替代现实决策。';

  // Keep existing product IDs for wallet/history compatibility, not report tiers.
  static const all = <AiReportProductConfig>[
    AiReportProductConfig(
      id: 'daily_hexagram_brief',
      featureKey: AiReportFeatureKeys.dailyHexagram,
      featureName: '每日一卦',
      reportType: 'daily_brief',
    ),
    AiReportProductConfig(
      id: 'gaodao_yiduan_question_full',
      featureKey: AiReportFeatureKeys.gaodaoYiduan,
      featureName: '高岛易断问事',
      reportType: 'question_full',
    ),
    AiReportProductConfig(
      id: 'coin_hexagram_question_full',
      featureKey: AiReportFeatureKeys.coinHexagram,
      featureName: '金钱卦问事',
      reportType: 'question_full',
    ),
    AiReportProductConfig(
      id: 'xiaoliuren_question_full',
      featureKey: AiReportFeatureKeys.xiaoliuren,
      featureName: '小六壬问事',
      reportType: 'question_full',
    ),
    AiReportProductConfig(
      id: 'meihua_yishu_question_full',
      featureKey: AiReportFeatureKeys.meihuaYishu,
      featureName: '梅花易数问事',
      reportType: 'question_full',
    ),
    AiReportProductConfig(
      id: 'bazi_basic_3_9',
      featureKey: AiReportFeatureKeys.bazi,
      featureName: '八字命理',
      reportType: 'bazi_basic',
    ),
    AiReportProductConfig(
      id: 'ziwei_basic',
      featureKey: AiReportFeatureKeys.ziweiDoushu,
      featureName: '紫微斗数',
      reportType: 'ziwei_basic',
    ),
    AiReportProductConfig(
      id: 'tieban_basic',
      featureKey: AiReportFeatureKeys.tiebanShenshu,
      featureName: '铁板神数',
      reportType: 'tieban_basic',
    ),
  ];

  static List<AiReportProductConfig> forFeature(String featureKey) {
    return all.where((item) => item.featureKey == featureKey).toList();
  }

  static AiReportProductConfig? byId(String id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }
}

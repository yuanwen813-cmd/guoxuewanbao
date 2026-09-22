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
  final String reportType;
  final String priceTier;
  final String priceLabel;
  final String buttonTitle;
  final String buttonSubtitle;
  final int minWords;
  final int maxWords;
  final bool enabled;
  final String? disabledReason;
  final String promptTemplateId;

  const AiReportProductConfig({
    required this.id,
    required this.featureKey,
    required this.reportType,
    required this.priceTier,
    required this.priceLabel,
    required this.buttonTitle,
    required this.buttonSubtitle,
    required this.minWords,
    required this.maxWords,
    required this.enabled,
    required this.promptTemplateId,
    this.disabledReason,
  });

  String get modelId => AiReportModelIds.doubaoSeed21Pro;

  static const uniformPriceCents = 500;
  int get priceCents => uniformPriceCents;
}

class AiReportProductCatalog {
  static const localTestPaymentCopy =
      'AI 报告按次从服务端钱包扣费，生成失败会自动退款。\nAI 解读基于本地生成的结构化结果生成，仅供传统文化参考。';

  static const reportFooterCopy =
      '以上内容由 AI 根据本地生成的命盘或卦象结构进行白话解读，仅供传统文化参考，不代表确定性结论，也不替代现实决策。';

  static const all = <AiReportProductConfig>[
    AiReportProductConfig(
      id: 'daily_hexagram_brief',
      featureKey: AiReportFeatureKeys.dailyHexagram,
      reportType: 'daily_brief',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 AI 解析',
      buttonSubtitle: '基于今日卦象生成白话提醒',
      minWords: 500,
      maxWords: 800,
      enabled: true,
      promptTemplateId: 'ai_report_daily_hexagram_brief_v1',
    ),
    AiReportProductConfig(
      id: 'gaodao_yiduan_question_brief',
      featureKey: AiReportFeatureKeys.gaodaoYiduan,
      reportType: 'question_brief',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 简析',
      buttonSubtitle: '快速看卦意、趋势和提醒',
      minWords: 500,
      maxWords: 800,
      enabled: true,
      promptTemplateId: 'ai_report_gaodao_yiduan_question_brief_v1',
    ),
    AiReportProductConfig(
      id: 'gaodao_yiduan_question_full',
      featureKey: AiReportFeatureKeys.gaodaoYiduan,
      reportType: 'question_full',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 完整报告',
      buttonSubtitle: '卦象、趋势、风险和行动建议',
      minWords: 1500,
      maxWords: 2500,
      enabled: true,
      promptTemplateId: 'ai_report_gaodao_yiduan_question_full_v1',
    ),
    AiReportProductConfig(
      id: 'coin_hexagram_question_brief',
      featureKey: AiReportFeatureKeys.coinHexagram,
      reportType: 'question_brief',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 简析',
      buttonSubtitle: '快速看卦象方向',
      minWords: 500,
      maxWords: 800,
      enabled: true,
      promptTemplateId: 'ai_report_coin_hexagram_question_brief_v1',
    ),
    AiReportProductConfig(
      id: 'coin_hexagram_question_full',
      featureKey: AiReportFeatureKeys.coinHexagram,
      reportType: 'question_full',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 完整报告',
      buttonSubtitle: '本卦、动爻、变卦与行动建议',
      minWords: 1500,
      maxWords: 2500,
      enabled: true,
      promptTemplateId: 'ai_report_coin_hexagram_question_full_v1',
    ),
    AiReportProductConfig(
      id: 'xiaoliuren_question_brief',
      featureKey: AiReportFeatureKeys.xiaoliuren,
      reportType: 'question_brief',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 简析',
      buttonSubtitle: '快速看吉凶趋势',
      minWords: 400,
      maxWords: 700,
      enabled: true,
      promptTemplateId: 'ai_report_xiaoliuren_question_brief_v1',
    ),
    AiReportProductConfig(
      id: 'xiaoliuren_question_full',
      featureKey: AiReportFeatureKeys.xiaoliuren,
      reportType: 'question_full',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 完整报告',
      buttonSubtitle: '趋势、时机、风险和行动建议',
      minWords: 1000,
      maxWords: 1800,
      enabled: true,
      promptTemplateId: 'ai_report_xiaoliuren_question_full_v1',
    ),
    AiReportProductConfig(
      id: 'meihua_yishu_question_brief',
      featureKey: AiReportFeatureKeys.meihuaYishu,
      reportType: 'question_brief',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 简析',
      buttonSubtitle: '快速看体用生克与趋势',
      minWords: 600,
      maxWords: 900,
      enabled: true,
      promptTemplateId: 'ai_report_meihua_yishu_question_brief_v1',
    ),
    AiReportProductConfig(
      id: 'meihua_yishu_question_full',
      featureKey: AiReportFeatureKeys.meihuaYishu,
      reportType: 'question_full',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 完整报告',
      buttonSubtitle: '体用、生克、互变卦完整解析',
      minWords: 1500,
      maxWords: 2500,
      enabled: true,
      promptTemplateId: 'ai_report_meihua_yishu_question_full_v1',
    ),
    AiReportProductConfig(
      id: 'bazi_brief_1',
      featureKey: AiReportFeatureKeys.bazi,
      reportType: 'bazi_brief',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 命盘简析',
      buttonSubtitle: '快速了解日主、五行和整体气质',
      minWords: 800,
      maxWords: 1200,
      enabled: true,
      promptTemplateId: 'ai_report_bazi_brief_v1',
    ),
    AiReportProductConfig(
      id: 'bazi_basic_3_9',
      featureKey: AiReportFeatureKeys.bazi,
      reportType: 'bazi_basic',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 基础报告',
      buttonSubtitle: '命盘结构、日主五行、性格与发展建议',
      minWords: 3000,
      maxWords: 5000,
      enabled: true,
      promptTemplateId: 'ai_report_bazi_basic_v1',
    ),
    AiReportProductConfig(
      id: 'bazi_deep_6_9',
      featureKey: AiReportFeatureKeys.bazi,
      reportType: 'bazi_deep',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 深度报告',
      buttonSubtitle: '加入大运、近三年趋势和阶段建议',
      minWords: 6000,
      maxWords: 12000,
      enabled: true,
      promptTemplateId: 'ai_report_bazi_deep_v1',
    ),
    AiReportProductConfig(
      id: 'ziwei_brief',
      featureKey: AiReportFeatureKeys.ziweiDoushu,
      reportType: 'ziwei_brief',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 紫微简析',
      buttonSubtitle: '快速看命宫、主星和性格轮廓',
      minWords: 800,
      maxWords: 1200,
      enabled: true,
      promptTemplateId: 'ai_report_ziwei_brief_v1',
    ),
    AiReportProductConfig(
      id: 'ziwei_basic',
      featureKey: AiReportFeatureKeys.ziweiDoushu,
      reportType: 'ziwei_basic',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 十二宫基础报告',
      buttonSubtitle: '命宫、事业、财帛、迁移、夫妻等基础解读',
      minWords: 3000,
      maxWords: 5000,
      enabled: true,
      promptTemplateId: 'ai_report_ziwei_basic_v1',
    ),
    AiReportProductConfig(
      id: 'ziwei_deep',
      featureKey: AiReportFeatureKeys.ziweiDoushu,
      reportType: 'ziwei_deep',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 紫微深度报告',
      buttonSubtitle: '十二宫、大限、流年综合分析',
      minWords: 6000,
      maxWords: 9000,
      enabled: true,
      promptTemplateId: 'ai_report_ziwei_deep_v1',
    ),
    AiReportProductConfig(
      id: 'tieban_basic',
      featureKey: AiReportFeatureKeys.tiebanShenshu,
      reportType: 'tieban_basic',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 神数简读',
      buttonSubtitle: '条文含义、命局提示和参考建议',
      minWords: 1500,
      maxWords: 2500,
      enabled: true,
      promptTemplateId: 'ai_report_tieban_basic_v1',
    ),
    AiReportProductConfig(
      id: 'tieban_deep',
      featureKey: AiReportFeatureKeys.tiebanShenshu,
      reportType: 'tieban_deep',
      priceTier: 'flat_5',
      priceLabel: '¥5',
      buttonTitle: '¥5 高级推演',
      buttonSubtitle: '多条文综合、命盘交叉和阶段建议',
      minWords: 4000,
      maxWords: 6000,
      enabled: true,
      promptTemplateId: 'ai_report_tieban_deep_v1',
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

class AiReportPromptTemplates {
  static const templates = <String, String>{
    'ai_report_daily_hexagram_brief_v1':
        '按每日一卦解读，先给今日主题，再说明卦爻依据和提醒。',
    'ai_report_gaodao_yiduan_question_brief_v1':
        '按高岛易断问事简析，先给主判断，再解释关键卦爻依据。',
    'ai_report_gaodao_yiduan_question_full_v1':
        '按高岛易断完整解读，说明主判断、关键卦爻、阻碍、转机条件和建议。',
    'ai_report_coin_hexagram_question_brief_v1':
        '按金钱卦问事简析，先给主判断，再解释关键卦爻依据。',
    'ai_report_coin_hexagram_question_full_v1':
        '按金钱卦完整解读，结合原始起卦时间分析本卦、动爻、变卦；传统装卦推演应说明依据和必要假设。',
    'ai_report_xiaoliuren_question_brief_v1':
        '按小六壬问事简析，说明落宫与主判断。',
    'ai_report_xiaoliuren_question_full_v1':
        '按小六壬完整解读，说明主判断、趋势、时机、阻碍和建议。',
    'ai_report_meihua_yishu_question_brief_v1':
        '按梅花易数问事简析，说明体用生克及主判断。',
    'ai_report_meihua_yishu_question_full_v1':
        '按梅花易数完整解读，说明体用生克、互卦、变卦、主判断和转机条件。',
    'ai_report_bazi_brief_v1':
        '按八字命盘简洁版解读，说明日主、五行和整体特征。',
    'ai_report_bazi_basic_v1':
        '按八字命盘标准版解读，围绕命盘结构展开完整分析。',
    'ai_report_bazi_deep_v1':
        '按八字命盘详细版解读，展开结构、发展节奏和阶段建议；推演与已有排盘资料应明确区分。',
    'ai_report_ziwei_brief_v1':
        '按紫微斗数简洁版解读，说明命宫、主星和整体特征。',
    'ai_report_ziwei_basic_v1':
        '按紫微斗数标准版解读，围绕已提供的十二宫资料展开分析。',
    'ai_report_ziwei_deep_v1':
        '按紫微斗数详细版解读，综合已提供的十二宫、大限和流年资料。',
    'ai_report_tieban_basic_v1':
        '按铁板神数简读，解释所给条文和命盘含义，指出条文来源。',
    'ai_report_tieban_deep_v1':
        '按铁板神数详细解读，综合所给条文、命盘与阶段建议，不虚构条文编号或出处。',
  };
}

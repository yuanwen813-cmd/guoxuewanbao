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
  static const deepseekV4Flash = 'deepseek-v4-flash';
  static const deepseekV4Pro = 'deepseek-v4-pro';
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

  String get modelId {
    switch (priceTier) {
      case 'standard_3_9':
      case 'advanced_6_9':
      case 'custom_13_9':
        return AiReportModelIds.deepseekV4Pro;
      case 'one_yuan':
      default:
        return AiReportModelIds.deepseekV4Flash;
    }
  }

  int get priceCents {
    switch (priceTier) {
      case 'standard_3_9':
        return 390;
      case 'advanced_6_9':
        return 690;
      case 'custom_13_9':
        return 1390;
      case 'one_yuan':
        return 100;
      default:
        return 0;
    }
  }
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
      priceTier: 'one_yuan',
      priceLabel: '¥1',
      buttonTitle: '¥1 AI 解析',
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
      priceTier: 'one_yuan',
      priceLabel: '¥1',
      buttonTitle: '¥1 简析',
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
      priceTier: 'standard_3_9',
      priceLabel: '¥3.9',
      buttonTitle: '¥3.9 完整报告',
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
      priceTier: 'one_yuan',
      priceLabel: '¥1',
      buttonTitle: '¥1 简析',
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
      priceTier: 'standard_3_9',
      priceLabel: '¥3.9',
      buttonTitle: '¥3.9 完整报告',
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
      priceTier: 'one_yuan',
      priceLabel: '¥1',
      buttonTitle: '¥1 简析',
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
      priceTier: 'standard_3_9',
      priceLabel: '¥3.9',
      buttonTitle: '¥3.9 完整报告',
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
      priceTier: 'one_yuan',
      priceLabel: '¥1',
      buttonTitle: '¥1 简析',
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
      priceTier: 'standard_3_9',
      priceLabel: '¥3.9',
      buttonTitle: '¥3.9 完整报告',
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
      priceTier: 'one_yuan',
      priceLabel: '¥1',
      buttonTitle: '¥1 命盘简析',
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
      priceTier: 'standard_3_9',
      priceLabel: '¥3.9',
      buttonTitle: '¥3.9 基础报告',
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
      priceTier: 'advanced_6_9',
      priceLabel: '¥6.9',
      buttonTitle: '¥6.9 深度报告',
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
      priceTier: 'one_yuan',
      priceLabel: '¥1',
      buttonTitle: '¥1 紫微简析',
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
      priceTier: 'standard_3_9',
      priceLabel: '¥3.9',
      buttonTitle: '¥3.9 十二宫基础报告',
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
      priceTier: 'advanced_6_9',
      priceLabel: '¥6.9',
      buttonTitle: '¥6.9 紫微深度报告',
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
      priceTier: 'standard_3_9',
      priceLabel: '¥3.9',
      buttonTitle: '¥3.9 神数简读',
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
      priceTier: 'advanced_6_9',
      priceLabel: '¥6.9',
      buttonTitle: '¥6.9 高级推演',
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
        '根据每日一卦结构化结果生成 500-800 字白话提醒。只能读取 {{question}} 与 {{daily_hexagram_result_json}}，不得重新起卦，不得编造卦辞、爻辞或绝对化断语。输出：今日卦象简述、动爻提醒、可做之事、需谨慎之处、传统文化参考免责声明。',
    'ai_report_gaodao_yiduan_question_brief_v1':
        '根据高岛易断结构化结果生成 500-800 字简析。只能读取 {{question}} 与 {{gaodao_result_json}}，不得重新起卦，不得编造卦象、爻辞或断语。输出：卦意简述、事情趋势、需要注意、行动建议、免责声明。',
    'ai_report_gaodao_yiduan_question_full_v1':
        '根据高岛易断结构化结果生成 1500-2500 字完整问事报告。只能读取 {{question}} 与 {{gaodao_result_json}}，不得重新起卦或编造不存在的信息。输出：问题与卦象总观、本卦状态、关键爻提示、变卦趋势、有利因素、风险阻碍、行动建议、不宜事项、免责声明。',
    'ai_report_coin_hexagram_question_brief_v1':
        '根据金钱卦结构化结果生成 500-800 字简析。只能读取 {{question}} 与 {{coin_hexagram_result_json}}，不得重新摇卦，不得编造动爻、变卦、世应。输出：卦象简述、当前趋势、关键提醒、行动建议、免责声明。',
    'ai_report_coin_hexagram_question_full_v1':
        '根据金钱卦结构化结果生成 1500-2500 字完整问事报告。只能读取 {{question}} 与 {{coin_hexagram_result_json}}。若 JSON 未提供六亲、世应、应期等信息，必须说明当前结果未提供，不作展开。',
    'ai_report_xiaoliuren_question_brief_v1':
        '根据小六壬结构化结果生成 400-700 字简析。只能读取 {{question}} 与 {{xiaoliuren_result_json}}，不得重新起课或编造宫位。输出：落宫结果、事情趋势、注意事项、行动建议、免责声明。',
    'ai_report_xiaoliuren_question_full_v1':
        '根据小六壬结构化结果生成 1000-1800 字完整问事报告。不要强行扩写空话，只围绕当前趋势和行动建议展开，结尾加入免责声明。',
    'ai_report_meihua_yishu_question_brief_v1':
        '根据梅花易数结构化结果生成 600-900 字简析。只能读取 {{question}} 与 {{meihua_result_json}}，不得重新起卦或编造体卦、用卦、互卦、变卦。',
    'ai_report_meihua_yishu_question_full_v1':
        '根据梅花易数结构化结果生成 1500-2500 字完整问事报告。输出：问题与卦象总观、本卦、体用、生克、互卦、变卦、有利因素、风险、行动建议、免责声明。',
    'ai_report_bazi_brief_v1':
        '根据八字命盘结构化 JSON 生成 800-1200 字命盘简析。输入：{{birth_profile_json}}、{{bazi_chart_json}}、可选 {{true_solar_bazi_chart_json}}。AI 不得重新排盘，不得输出正式批命断语。',
    'ai_report_bazi_basic_v1':
        '根据八字命盘结构化 JSON 生成 3000-5000 字基础报告。只能解释本地四柱、日主、五行摘要和已提供结构，不得编造大运、流年、神煞或格局。',
    'ai_report_bazi_deep_v1':
        '根据八字命盘结构化 JSON 生成 6000-12000 字深度报告，对应总控提示词中的命盘类详细版。大运、流年必须来自输入 JSON；如果未提供，必须写明当前结构化结果未提供，不作展开。',
    'ai_report_ziwei_brief_v1':
        '根据紫微斗数命盘 JSON 生成 800-1200 字简析。若没有命宫、主星、十二宫信息，不得生成报告。AI 不排盘，只解释输入 JSON。',
    'ai_report_ziwei_basic_v1':
        '根据紫微斗数命盘 JSON 生成 3000-5000 字基础报告。只解释本地 JSON 中已有的命宫、身宫、主星、十二宫信息，不得编造星曜和宫位。',
    'ai_report_ziwei_deep_v1':
        '根据紫微斗数命盘 JSON 生成 6000-9000 字深度报告。大限和流年必须来自 JSON；不得编造四化、大限、流年。',
    'ai_report_tieban_basic_v1':
        '根据铁板神数结构化结果生成 1500-2500 字神数简读报告。AI 不得自行推算条文，只解释 JSON 中已有条文，不得宣称精准预测。',
    'ai_report_tieban_deep_v1':
        '根据铁板神数结构化结果生成 4000-6000 字高级推演报告。只解释本地生成的神数条文和命盘 JSON，不自行推算新条文。',
  };
}

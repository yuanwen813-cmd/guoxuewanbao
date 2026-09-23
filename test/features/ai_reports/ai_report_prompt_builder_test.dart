import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/common/common_result_models.dart';
import 'package:guoxueapp/features/ai_reports/ai_report_product_config.dart';
import 'package:guoxueapp/features/ai_reports/ai_report_prompt_builder.dart';

void main() {
  final config = AiReportProductCatalog.byId('coin_hexagram_question_full')!;

  CommonDivinationResult sample() => CommonDivinationResult(
        featureId: 'coin_hexagram',
        featureName: '金钱卦',
        categoryId: 'divination',
        createdAt: DateTime.utc(2026, 9, 21, 1, 55),
        summary: '风山渐之巽为风',
        chartSections: const [
          ChartSection(title: '动爻', rows: [MapEntry('六二', '阴动变阳')]),
        ],
      );

  test('new history preserves original cast time and changing line details',
      () {
    final original = sample();
    final restored = CommonDivinationResult.fromJson(original.toJson());
    expect(restored.castTimeUtc, original.castTimeUtc);
    expect(restored.copyWith().castTimeUtc, original.castTimeUtc);
    expect(restored.chartSections!.single.rows.single.key, '六二');
    final prompt = buildAiReportUserPrompt(
      config: config,
      focus: '测试所问之事',
      sourceJson: jsonEncode(restored.toJson()),
    );
    expect(prompt, contains('2026-09-21T09:55:00.000+08:00'));
    expect(prompt, contains('北京时间 UTC+8'));
    expect(prompt, contains('六二'));
    expect(prompt, isNot(contains('价格档位')));
    expect(prompt, isNot(contains('promptTemplateId')));
  });

  test('legacy time without timezone is not silently converted to Beijing time',
      () {
    final legacy = sample().toJson()
      ..remove('castTimeUtc')
      ..['createdAt'] = '2026-09-21T09:55:00.000';
    final restored = CommonDivinationResult.fromJson(legacy);
    expect(restored.castTimeUtc, isNull);
    expect(restored.copyWith().toJson().containsKey('castTimeUtc'), isFalse);
    final prompt = buildAiReportUserPrompt(
      config: config,
      focus: '问题',
      sourceJson: jsonEncode(restored.toJson()),
    );
    expect(prompt, contains('旧记录未保存可靠时区'));
    expect(prompt, isNot(contains('+08:00')));
  });

  test('previous AI answer and conclusions are not reused as chart input', () {
    final source = sample().toJson()
      ..['aiReports'] = [
        {'text': '旧模型结论'}
      ]
      ..['interpretation'] = {'advice': '旧解读建议'};
    final prompt = buildAiReportUserPrompt(
      config: config,
      focus: '问题',
      sourceJson: jsonEncode(source),
    );
    expect(prompt, isNot(contains('旧模型结论')));
    expect(prompt, isNot(contains('旧解读建议')));
    expect(prompt, contains('风山渐之巽为风'));
  });

  test('natal plain-text source remains supported', () {
    final prompt = buildAiReportUserPrompt(
      config: AiReportProductCatalog.byId('bazi_basic_3_9')!,
      focus: '整体命盘详解',
      sourceJson: '公历出生：2000-01-01 09:00（北京时间）\n年柱：己卯',
    );
    expect(prompt, contains('年柱：己卯'));
    expect(prompt, contains('八字命理'));
    expect(prompt, isNot(contains('起卦时间')));
    expect(prompt, isNot(contains('3000-5000')));
  });

  test('every feature sends a minimal task without tiers or length rules', () {
    for (final product in AiReportProductCatalog.all) {
      final prompt = buildAiReportUserPrompt(
        config: product,
        focus: '所问之事',
        sourceSummary: '原始资料摘要',
      );
      expect(prompt, contains(product.featureName));
      expect(prompt, contains('所问之事'));
      expect(prompt, contains('原始资料摘要'));
      for (final directive in [
        '篇幅',
        '字数',
        '报告类型',
        '先给',
        '模板',
        '简洁版',
        '标准版',
        '详细版'
      ]) {
        expect(prompt, isNot(contains(directive)));
      }
    }
  });

  test('recorded cast time wins over later save or report time across days',
      () {
    final source = sample().toJson()
      ..['castTimeUtc'] = '2026-09-20T16:30:00Z'
      ..['createdAt'] = '2026-09-22T10:00:00Z';
    final prompt = buildAiReportUserPrompt(
      config: config,
      focus: '问题',
      sourceJson: jsonEncode(source),
    );
    expect(prompt, contains('原始起卦时间：2026-09-21T00:30:00.000+08:00'));
  });

  test('all divination tasks include the full original casting timestamp', () {
    for (final product in AiReportProductCatalog.all.where(
      (item) => ![
        AiReportFeatureKeys.bazi,
        AiReportFeatureKeys.ziweiDoushu,
        AiReportFeatureKeys.tiebanShenshu
      ].contains(item.featureKey),
    )) {
      final prompt = buildAiReportUserPrompt(
        config: product,
        focus: '问题',
        sourceJson: jsonEncode(sample().toJson()),
      );
      expect(prompt, contains('原始起卦时间：2026-09-21T09:55:00.000+08:00'));
    }
    final missing = buildAiReportUserPrompt(config: config, focus: '问题');
    expect(missing, contains('起卦时间：原始记录未提供'));
  });
}

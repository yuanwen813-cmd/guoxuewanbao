import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/common/common_result_models.dart';
import 'package:guoxueapp/features/ai_reports/ai_report_product_config.dart';
import 'package:guoxueapp/features/ai_reports/ai_report_product_panel.dart';
import 'package:guoxueapp/features/wallet/wallet_store.dart';

Widget panel(String feature, {List<AiReportSnapshot> reports = const []}) {
  return ProviderScope(
    overrides: [
      walletStoreProvider.overrideWith((ref) => WalletStore(useServer: false)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AiReportProductPanel(
              featureKey: feature, initialReports: reports),
        ),
      ),
    ),
  );
}

AiReportSnapshot saved(String productId, String text) => AiReportSnapshot(
      productId: productId,
      featureKey: AiReportFeatureKeys.bazi,
      title: '已购买的报告 $productId',
      reportType: 'bazi_basic',
      priceLabel: '¥3.9',
      text: text,
      reportId: 'saved-$productId',
      createdAt: DateTime(2026, 8, 1),
    );

void main() {
  for (final product in AiReportProductCatalog.all) {
    testWidgets(
        '${product.featureKey} exposes one option without length or tiers',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(panel(product.featureKey));
      await tester.pumpAndSettle();
      expect(find.text('¥5 AI 解析'), findsOneWidget);
      final buttons =
          find.byWidgetPredicate((widget) => widget is FilledButton);
      expect(buttons, findsOneWidget);
      expect(
          find.textContaining(RegExp(r'\d+\s*[-~]\s*\d+\s*字')), findsNothing);
      for (final tier in ['简析', '基础报告', '深度报告', '高级推演', '字数', '篇幅']) {
        expect(find.textContaining(tier), findsNothing);
      }
      await tester.ensureVisible(buttons);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('all paid legacy tiers remain readable without a new purchase',
      (tester) async {
    await tester.pumpWidget(panel(AiReportFeatureKeys.bazi, reports: [
      saved('bazi_brief_1', '旧简析正文'),
      saved('bazi_basic_3_9', '旧基础正文'),
      saved('bazi_deep_6_9', '旧深度正文'),
    ]));
    await tester.pumpAndSettle();
    for (final text in ['旧简析正文', '旧基础正文', '旧深度正文']) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.text('生成报告'), findsNothing);
    expect(find.text('重新解析'), findsNothing);
    expect(find.text('已生成'), findsNWidgets(3));
    expect(find.text('复制解析'), findsNWidgets(3));
    expect(find.text('系统分享'), findsNWidgets(3));
    final buttons = find.byWidgetPredicate((widget) => widget is FilledButton);
    expect(buttons, findsNWidgets(3));
    for (final button in tester.widgetList<FilledButton>(buttons)) {
      expect(button.onPressed, isNull);
    }
  });

  testWidgets('failed legacy tier retries through the single current option',
      (tester) async {
    await tester.pumpWidget(panel(AiReportFeatureKeys.bazi, reports: [
      saved('bazi_deep_6_9', 'AI 服务未返回内容。'),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('AI 服务未返回内容。'), findsNothing);
    expect(find.text('重新解析'), findsOneWidget);
    expect(find.text('¥5 AI 解析'), findsOneWidget);
    expect(find.byKey(const Key('ai_report_bazi_deep_6_9')), findsNothing);
    expect(
        tester
            .widget<FilledButton>(find.byKey(
              const Key('ai_report_bazi_basic_3_9'),
            ))
            .onPressed,
        isNotNull);
  });
}

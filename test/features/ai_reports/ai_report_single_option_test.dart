import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/common/common_result_models.dart';
import 'package:guoxueapp/features/ai_reports/ai_report_product_config.dart';
import 'package:guoxueapp/features/ai_reports/ai_report_product_panel.dart';
import 'package:guoxueapp/features/auth/auth_store.dart';
import 'package:guoxueapp/features/wallet/server_wallet_api.dart';
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
  for (final feature in [AiReportFeatureKeys.coinHexagram, AiReportFeatureKeys.bazi]) {
    testWidgets('$feature responds immediately without a wallet preflight',
        (tester) async {
      final wallet = PendingReportWallet();
      final product = AiReportProductCatalog.forFeature(feature).single;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          walletStoreProvider.overrideWith((ref) => wallet),
          authStoreProvider.overrideWith((ref) => AuthStore(
            initialState: const AuthState(
              initialized: true, token: 'test-token', user: AppUser(id: 'test-user'),
            ),
          )),
        ],
        child: MaterialApp(home: Scaffold(body: SingleChildScrollView(
          child: AiReportProductPanel(
            featureKey: feature,
            initialFocus: feature == AiReportFeatureKeys.bazi ? null : '合作是否顺利？',
            sourceSummary: '原始测试资料',
          ),
        ))),
      ));
      await tester.pumpAndSettle();
      final button = find.byKey(Key('ai_report_${product.id}'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(wallet.syncCalls, 0);
      expect(wallet.generateCalls, 1);
      expect(wallet.expectedPrice, 200);
      expect(wallet.prompt, [
        product.featureName,
        '所问之事或关注方向：${feature == AiReportFeatureKeys.bazi ? '整体命盘详解' : '合作是否顺利？'}',
        if (feature != AiReportFeatureKeys.bazi) '起卦时间：原始记录未提供。',
        '原始资料：', '原始测试资料', '请解读。',
      ].join('\n'));
      expect(find.text('生成中'), findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
      await tester.tap(button);
      expect(wallet.generateCalls, 1);
      wallet.response.completeError(const ServerWalletException(
        '测试失败，积分已退回', statusCode: 504, refunded: true,
      ));
      await tester.pumpAndSettle();
      expect(find.text('重新解析'), findsOneWidget);
      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    });
  }

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
      expect(find.text('2 积分 AI 解析'), findsOneWidget);
      expect(find.text('解析全部'), findsNothing);
      expect(find.text('5 积分 AI 解析'), findsNothing);
      final buttons =
          find.byWidgetPredicate((widget) => widget is FilledButton);
      expect(buttons, findsOneWidget);
      expect(
          find.textContaining(RegExp(r'\d+\s*[-~]\s*\d+\s*字')), findsNothing);
      for (final tier in ['简析', '基础报告', '深度报告', '高级推演', '字数', '篇幅']) {
        expect(find.textContaining(tier), findsNothing);
      }
      await tester.ensureVisible(buttons.first);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('old analysis-all report remains readable without a purchase option',
      (tester) async {
    await tester.pumpWidget(panel(AiReportFeatureKeys.bazi, reports: [
      AiReportSnapshot(
        productId: 'analysis_all_2_bazi',
        featureKey: AiReportFeatureKeys.bazi,
        title: '旧整体概览',
        reportType: 'analysis_all',
        priceLabel: '2 积分',
        text: '已购买的旧报告正文',
        reportId: 'old-analysis-all',
        createdAt: DateTime(2026, 9, 1),
      ),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('已购买的旧报告正文'), findsOneWidget);
    expect(find.text('生成报告'), findsNothing);
    expect(find.byKey(const Key('ai_report_analysis_all_2_bazi')), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('ai_report_analysis_all_2_bazi'))).onPressed,
      isNull,
    );
    expect(find.byKey(const Key('ai_report_bazi_basic_3_9')), findsNothing);
  });

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
    expect(find.text('2 积分 AI 解析'), findsOneWidget);
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

class PendingReportWallet extends WalletStore {
  PendingReportWallet() : super(useServer: false);

  final response = Completer<ServerAiReportResult>();
  int syncCalls = 0;
  int generateCalls = 0;
  int? expectedPrice;
  String? prompt;

  @override
  Future<void> syncFromServer() async {
    syncCalls += 1;
  }

  @override
  Future<ServerAiReportResult> generateAiReport({
    required String productId,
    required String featureKey,
    required String title,
    required String systemPrompt,
    required String userPrompt,
    required double temperature,
    required int expectedPointsCenti,
    required String requestId,
    String? sourceJson,
  }) {
    generateCalls += 1;
    expectedPrice = expectedPointsCenti;
    prompt = userPrompt;
    return response.future;
  }
}

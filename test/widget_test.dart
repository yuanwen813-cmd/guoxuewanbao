import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:guoxueapp/domain/common/common_result_models.dart';
import 'package:guoxueapp/features/ai_reports/ai_report_product_panel.dart';
import 'package:guoxueapp/features/ai_reports/ai_report_product_config.dart';
import 'package:guoxueapp/features/auth/auth_store.dart';
import 'package:guoxueapp/features/result_common/common_divination_result_page.dart';
import 'package:guoxueapp/features/v2/mine_home_page.dart';
import 'package:guoxueapp/features/wallet/wallet_page.dart';
import 'package:guoxueapp/features/wallet/wallet_store.dart';
import 'package:guoxueapp/domain/history/divination_history.dart';
import 'package:guoxueapp/infrastructure/history_service/history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AI report product catalog exposes final report tiers', () {
    final daily = AiReportProductCatalog.forFeature(
      AiReportFeatureKeys.dailyHexagram,
    );
    final ask = AiReportProductCatalog.forFeature(
      AiReportFeatureKeys.coinHexagram,
    );
    final bazi = AiReportProductCatalog.forFeature(AiReportFeatureKeys.bazi);
    final ziwei = AiReportProductCatalog.forFeature(
      AiReportFeatureKeys.ziweiDoushu,
    );
    final tieban = AiReportProductCatalog.forFeature(
      AiReportFeatureKeys.tiebanShenshu,
    );

    expect(daily.map((item) => item.priceTier), ['one_yuan']);
    expect(daily.single.priceCents, 100);
    expect(daily.single.modelId, AiReportModelIds.deepseekV4Flash);

    expect(ask.map((item) => item.priceTier), [
      'one_yuan',
      'standard_3_9',
    ]);
    expect(ask.any((item) => item.priceTier == 'advanced_6_9'), isFalse);
    expect(ask.any((item) => item.priceTier == 'premium_13_9'), isFalse);
    expect(ask.map((item) => item.modelId), [
      AiReportModelIds.deepseekV4Flash,
      AiReportModelIds.deepseekV4Pro,
    ]);

    expect(bazi.map((item) => item.priceTier), [
      'one_yuan',
      'standard_3_9',
      'advanced_6_9',
      'custom_13_9',
    ]);
    expect(bazi.map((item) => item.modelId), [
      AiReportModelIds.deepseekV4Flash,
      AiReportModelIds.deepseekV4Pro,
      AiReportModelIds.deepseekV4Pro,
      AiReportModelIds.deepseekV4Pro,
    ]);
    expect(bazi.every((item) => item.enabled), isTrue);
    expect(ziwei.map((item) => item.priceTier), [
      'one_yuan',
      'standard_3_9',
      'advanced_6_9',
      'custom_13_9',
    ]);
    expect(ziwei.map((item) => item.modelId), [
      AiReportModelIds.deepseekV4Flash,
      AiReportModelIds.deepseekV4Pro,
      AiReportModelIds.deepseekV4Pro,
      AiReportModelIds.deepseekV4Pro,
    ]);
    expect(ziwei.every((item) => item.enabled), isFalse);
    expect(tieban.map((item) => item.priceTier), [
      'standard_3_9',
      'advanced_6_9',
      'custom_13_9',
    ]);
    expect(
        tieban.every((item) => item.modelId == AiReportModelIds.deepseekV4Pro),
        isTrue);
    expect(tieban.every((item) => item.enabled), isFalse);
    expect(AiReportProductCatalog.byId('bazi_custom_13_9'), isNotNull);
  });

  test('local wallet supports recharge charge and refund', () async {
    final wallet = WalletStore(useServer: false);

    await wallet.rechargeYuan(6);
    expect(wallet.state.balanceCents, 600);

    final charge = await wallet.charge(
      amountCents: 390,
      title: 'AI 解析',
      featureKey: AiReportFeatureKeys.coinHexagram,
      productId: 'coin_hexagram_question_full',
    );
    expect(charge.success, isTrue);
    expect(wallet.state.balanceCents, 210);

    await wallet.refund(
      transactionId: charge.transactionId!,
      amountCents: 390,
      title: '失败退款',
    );
    expect(wallet.state.balanceCents, 600);

    await wallet.clearLocalSession();
    expect(wallet.state.balanceCents, 0);
    expect(wallet.state.transactions, isEmpty);

    expect(wallet.rechargeYuan(0), throwsArgumentError);
  });

  testWidgets('mine page shows logout confirmation for signed in user',
      (tester) async {
    final wallet = WalletStore(useServer: false);
    await wallet.rechargeYuan(10);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletStoreProvider.overrideWith((ref) => wallet),
          authStoreProvider.overrideWith(
            (ref) => AuthStore(
              initialState: const AuthState(
                initialized: true,
                token: 'test-token',
                user: AppUser(id: 'test-user', phone: '13800000000'),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: MineHomePage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('退出登录'), findsOneWidget);

    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();

    expect(find.text('确定退出当前账号吗？退出后不会删除你的余额、订单和 AI 报告，重新登录同一手机号仍可查看。'),
        findsOneWidget);
    expect(find.text('取消'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('退出登录'), findsOneWidget);
  });

  testWidgets('wallet custom amount switches from fixed options',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletStoreProvider.overrideWith(
            (ref) => WalletStore(useServer: false),
          ),
          authStoreProvider.overrideWith(
            (ref) => AuthStore(
              initialState: const AuthState(
                initialized: true,
                token: 'test-token',
                user: AppUser(id: 'test-user', phone: '13800000000'),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          home: WalletPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('wallet_recharge_100')), findsOneWidget);
    expect(find.byKey(const Key('wallet_custom_option')), findsOneWidget);
    expect(find.byKey(const Key('wallet_custom_amount')), findsNothing);
    expect(find.byKey(const Key('wallet_recharge_confirm_card')), findsNothing);
    expect(find.byKey(const Key('wallet_recharge_status')), findsNothing);

    await tester.tap(find.byKey(const Key('wallet_recharge_100')));
    await tester.pump();

    expect(
        find.byKey(const Key('wallet_recharge_confirm_card')), findsOneWidget);
    expect(find.byKey(const Key('wallet_confirm_recharge')), findsOneWidget);
    expect(find.byKey(const Key('wallet_recharge_status')), findsNothing);

    await tester.tap(find.byKey(const Key('wallet_custom_option')));
    await tester.pump();

    expect(find.byKey(const Key('wallet_recharge_100')), findsNothing);
    expect(find.byKey(const Key('wallet_custom_option')), findsNothing);
    expect(find.byKey(const Key('wallet_custom_amount')), findsOneWidget);
    expect(find.byKey(const Key('wallet_fixed_options')), findsOneWidget);
  });

  testWidgets(
      'ask result page generates report entry instead of preloading only',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletStoreProvider.overrideWith(
            (ref) => WalletStore(useServer: false),
          ),
        ],
        child: MaterialApp(
          home: CommonDivinationResultPage(
            result: _coinResult(),
            onAIInterpret: () {},
            aiInterpreting: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('ai_report_panel_coin_hexagram')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('ai_report_coin_hexagram_question_brief')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('ai_report_coin_hexagram_question_full')),
      findsOneWidget,
    );
    expect(find.textContaining('生成报告'), findsWidgets);
    expect(find.byKey(const Key('ai_report_wallet_balance')), findsOneWidget);
    expect(find.textContaining('服务端钱包'), findsWidgets);
    expect(find.textContaining('¥6.9'), findsNothing);
    expect(find.textContaining('¥13.9'), findsNothing);
    expect(find.text('AI 智能解读'), findsNothing);
  });

  testWidgets('AI report preloads the ask question as user focus',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletStoreProvider.overrideWith(
            (ref) => WalletStore(useServer: false),
          ),
        ],
        child: MaterialApp(
          home: CommonDivinationResultPage(
            result: _coinResult(),
          ),
        ),
      ),
    );
    await tester.pump();

    final focusField = tester.widget<TextField>(
      find.byKey(const Key('ai_report_focus_coin_hexagram')),
    );

    expect(focusField.controller?.text, '这次合作是否顺利？');
    expect(find.text('请先输入想重点了解的事项。'), findsNothing);
  });

  testWidgets('destiny AI report allows empty focus as whole chart reading',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletStoreProvider.overrideWith(
            (ref) => WalletStore(useServer: false),
          ),
          authStoreProvider.overrideWith(
            (ref) => AuthStore(
              initialState: const AuthState(
                initialized: true,
                token: 'test-token',
                user: AppUser(id: 'test-user', phone: '13800000000'),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiReportProductPanel(
                featureKey: AiReportFeatureKeys.bazi,
                sourceSummary: '八字命理结构已生成',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('想重点了解的方向（可选）'), findsOneWidget);
    expect(find.textContaining('不填写则生成整体命盘详解'), findsWidgets);

    await tester.tap(find.byKey(const Key('ai_report_bazi_brief_1')));
    await tester.pumpAndSettle();

    expect(find.text('请先输入想重点了解的事项。'), findsNothing);
  });

  testWidgets('question AI report still requires focus', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletStoreProvider.overrideWith(
            (ref) => WalletStore(useServer: false),
          ),
          authStoreProvider.overrideWith(
            (ref) => AuthStore(
              initialState: const AuthState(
                initialized: true,
                token: 'test-token',
                user: AppUser(id: 'test-user', phone: '13800000000'),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiReportProductPanel(
                featureKey: AiReportFeatureKeys.coinHexagram,
                sourceSummary: '金钱卦结构已生成',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const Key('ai_report_coin_hexagram_question_brief')),
    );
    await tester.pump();

    expect(find.text('请先输入想重点了解的事项。'), findsOneWidget);
  });

  test('share text includes saved AI report snapshots', () {
    final result = _coinResult(
      createdAt: DateTime(2026, 7, 6, 11),
      summary: '保存历史测试卦象',
    ).copyWithAiReport(
      AiReportSnapshot(
        productId: 'coin_hexagram_question_brief',
        featureKey: AiReportFeatureKeys.coinHexagram,
        title: '¥1 简析',
        reportType: 'question_brief',
        priceLabel: '¥1',
        text: '这是一段已经付费生成并保存的 AI 解析内容。',
        focus: '合作是否顺利',
        createdAt: DateTime(2026, 7, 3, 10),
      ),
    );

    final restored = CommonDivinationResult.fromJson(result.toJson());
    final shareText = CommonDivinationResultPage.buildShareText(restored);

    expect(restored.aiReports, hasLength(1));
    expect(shareText, contains('【AI 解析】'));
    expect(shareText, contains('这是一段已经付费生成并保存的 AI 解析内容。'));
  });

  test('history record can attach and restore AI report snapshot', () {
    final service = HistoryService();
    final result = _coinResult();
    final id =
        'history_ai_report_test_${DateTime.now().microsecondsSinceEpoch}';
    service.save(
      DivinationHistory(
        id: id,
        featureId: result.featureId,
        featureName: result.featureName,
        question: result.userQuestion,
        createdAt: result.createdAt,
        summary: result.summary,
        resultJson: jsonEncode(result.toJson()),
        tags: result.tags ?? const [],
      ),
    );

    final attached = service.attachAiReportToResult(
      result,
      AiReportSnapshot(
        productId: 'coin_hexagram_question_brief',
        featureKey: AiReportFeatureKeys.coinHexagram,
        title: '¥1 简析',
        reportType: 'question_brief',
        priceLabel: '¥1',
        text: '历史复看时应直接展示这段 AI 解析。',
        createdAt: DateTime(2026, 7, 3, 10),
      ),
    );

    final saved = service.getById(id)!;
    final restored = CommonDivinationResult.fromJson(saved.resultSnapshot);

    expect(attached, isTrue);
    expect(restored.aiReports.single.text, contains('历史复看时应直接展示'));
  });

  testWidgets('saved AI report is shown without another generate action',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletStoreProvider.overrideWith(
            (ref) => WalletStore(useServer: false),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiReportProductPanel(
                featureKey: AiReportFeatureKeys.coinHexagram,
                sourceSummary: 'coin result',
                initialReports: [
                  AiReportSnapshot(
                    productId: 'coin_hexagram_question_brief',
                    featureKey: AiReportFeatureKeys.coinHexagram,
                    title: '¥1 简析',
                    reportType: 'question_brief',
                    priceLabel: '¥1',
                    text: '已保存的 AI 解析内容。',
                    createdAt: DateTime(2026, 7, 3, 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('已保存的 AI 解析内容。'), findsOneWidget);
    expect(find.byKey(const Key('ai_report_copy_coin_hexagram_question_brief')),
        findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('ai_report_coin_hexagram_question_brief')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('result page save uses current AI report snapshot',
      (tester) async {
    final historyService = HistoryService();
    var parentSaveCalled = false;
    final result = _coinResult().copyWithAiReport(
      AiReportSnapshot(
        productId: 'coin_hexagram_question_brief',
        featureKey: AiReportFeatureKeys.coinHexagram,
        title: '¥1 简析',
        reportType: 'question_brief',
        priceLabel: '¥1',
        text: '保存历史时必须带上这段 AI 解析。',
        createdAt: DateTime(2026, 7, 6, 10),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyServiceProvider.overrideWith((ref) => historyService),
          walletStoreProvider.overrideWith(
            (ref) => WalletStore(useServer: false),
          ),
        ],
        child: MaterialApp(
          home: CommonDivinationResultPage(
            result: result,
            onSave: () => parentSaveCalled = true,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.bookmark_outline),
      ),
    );
    await tester.pump();

    final saved = historyService
        .getAll()
        .where((item) => item.summary == result.summary)
        .first;
    final restored = CommonDivinationResult.fromJson(saved.resultSnapshot);

    expect(parentSaveCalled, isFalse);
    expect(restored.aiReports.single.text, contains('保存历史时必须带上'));
  });

  testWidgets('result page share uses current AI report snapshot',
      (tester) async {
    var parentShareCalled = false;
    final result = _coinResult(
      createdAt: DateTime(2026, 7, 6, 12),
      summary: '分享结果测试卦象',
    ).copyWithAiReport(
      AiReportSnapshot(
        productId: 'coin_hexagram_question_brief',
        featureKey: AiReportFeatureKeys.coinHexagram,
        title: '¥1 简析',
        reportType: 'question_brief',
        priceLabel: '¥1',
        text: '分享结果时必须带上这段 AI 解析。',
        createdAt: DateTime(2026, 7, 6, 10),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletStoreProvider.overrideWith(
            (ref) => WalletStore(useServer: false),
          ),
        ],
        child: MaterialApp(
          home: CommonDivinationResultPage(
            result: result,
            onShare: () => parentShareCalled = true,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.share),
      ),
    );
    await tester.pumpAndSettle();

    expect(parentShareCalled, isFalse);
    expect(find.textContaining('分享结果时必须带上这段 AI 解析。'), findsWidgets);
  });

  test('stable route paths remain registered', () {
    final routerSource =
        File('lib/app/router/app_router.dart').readAsStringSync();
    const expectedRoutes = [
      "path: '/tools/almanac'",
      "path: '/daily_hexagram'",
      "path: '/divination/coin_hexagram'",
      "path: '/divination/small_liuren'",
      "path: '/divination/meihua'",
      "path: '/divination/takashima'",
      "path: '/reference/zhouyi'",
      "path: '/reference/takashima'",
      "path: '/natal/reading'",
      "path: '/natal/tieban'",
      "path: '/natal/ziwei'",
      "path: '/wallet'",
      "path: '/login'",
      "path: '/history'",
      "path: '/legacy-home'",
    ];

    for (final route in expectedRoutes) {
      expect(routerSource, contains(route));
    }
  });
}

CommonDivinationResult _coinResult({
  DateTime? createdAt,
  String? summary,
}) {
  return CommonDivinationResult(
    featureId: 'coin_hexagram',
    featureName: '金钱卦',
    categoryId: 'ask',
    userQuestion: '这次合作是否顺利？',
    createdAt: createdAt ?? DateTime(2026, 6, 29, 16, 30),
    summary: summary ?? '本卦乾为天，动爻一处，供传统文化参考。',
    type: DivinationType.hexagram,
    primaryHexagram: const HexagramCard(
      index: 1,
      name: '乾',
      symbol: '☰',
      judgment: '元亨利贞。',
      image: '天行健，君子以自强不息。',
    ),
    rawSnapshot: const {
      'localResult': {
        'primaryHexagram': '乾',
        'movingLines': [1],
      },
    },
  );
}

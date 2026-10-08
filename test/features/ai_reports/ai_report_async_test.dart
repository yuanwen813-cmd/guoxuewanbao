import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/features/ai_reports/ai_report_content.dart';
import 'package:guoxueapp/features/ai_reports/ai_report_detail_sheet.dart';
import 'package:guoxueapp/features/ai_reports/ai_report_product_panel.dart';
import 'package:guoxueapp/features/auth/auth_store.dart';
import 'package:guoxueapp/features/daily_hexagram/daily_hexagram_page.dart';
import 'package:guoxueapp/features/wallet/server_wallet_api.dart';
import 'package:guoxueapp/features/wallet/wallet_store.dart';
import 'package:guoxueapp/domain/common/common_result_models.dart';
import 'package:guoxueapp/domain/history/divination_history.dart';
import 'package:guoxueapp/infrastructure/history_service/history_service.dart';

class DailyHistory extends HistoryService {
  DailyHistory() : super(ownerKey: 'daily-page-test');
  int deletions = 0;
  @override
  void delete(String id) {
    deletions++;
    super.delete(id);
  }
}

class DailyApi extends ServerWalletApi {
  ServerAiReport? daily;
  Completer<ServerAiReport?>? waiting;
  int dailyReads = 0;
  int detailReads = 0;

  @override
  Future<ServerAiReport?> fetchTodayDailyReport() async {
    dailyReads++;
    return waiting != null ? await waiting!.future : daily;
  }

  @override
  Future<ServerAiReport> fetchAiReportDetail(String orderId) async {
    detailReads++;
    return const ServerAiReport(
        id: 'today',
        productId: 'daily_hexagram_brief',
        status: 'completed',
        priceCents: 200,
        resultText: '## 今日解析\n\n**已生成的内容**');
  }
}

Widget panel(DailyApi api, {AuthStore? auth}) => ProviderScope(
        overrides: [
          authStoreProvider.overrideWith((ref) =>
              auth ??
              AuthStore(
                  initialState: const AuthState(
                      initialized: true,
                      token: 'test',
                      user: AppUser(id: 'owner')))),
          walletStoreProvider
              .overrideWith((ref) => WalletStore(useServer: false)),
        ],
        child: MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: AiReportProductPanel(
                        featureKey: 'daily_hexagram', api: api)))));

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets(
      'daily page restores server report without deleting existing history',
      (tester) async {
    await tester.runAsync(() async {
      await rootBundle.loadString('assets/data/iching/hexagrams_64.json');
      await rootBundle.loadString('assets/data/iching/yao_384.json');
    });
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    final dateKey =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final result = CommonDivinationResult(
        featureId: 'daily_hexagram',
        featureName: '每日一卦',
        categoryId: 'divination',
        userQuestion: '今日整体运势如何？',
        createdAt: DateTime.now(),
        summary: '今日卦象',
        type: DivinationType.hexagram);
    final history = DailyHistory();
    await tester.pump();
    history.save(DivinationHistory(
        id: 'daily-existing',
        featureId: 'daily_hexagram',
        featureName: '每日一卦',
        question: result.userQuestion,
        createdAt: result.createdAt,
        summary: result.summary,
        isFavorite: true,
        resultJson: jsonEncode({'dateKey': dateKey, ...result.toJson()})));
    final api = DailyApi()
      ..daily = ServerAiReport(
          id: 'today',
          productId: 'daily_hexagram_brief',
          status: 'completed',
          priceCents: 200,
          resultText: '今日已付费报告',
          source: result.toJson());
    await tester.pumpWidget(ProviderScope(overrides: [
      authStoreProvider.overrideWith((ref) => AuthStore(
          initialState: const AuthState(
              initialized: true, token: 'test', user: AppUser(id: 'owner')))),
      historyServiceProvider.overrideWith((ref) => history),
      walletStoreProvider.overrideWith((ref) => WalletStore(useServer: false)),
    ], child: MaterialApp(home: DailyHexagramPage(api: api))));
    for (var attempt = 0; attempt < 10 && api.dailyReads < 2; attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
    await tester.pump();
    expect(api.dailyReads, 2);
    expect(history.deletions, 0);
    expect(history.getAll(), hasLength(1));
    expect(history.getAll().single.id, 'daily-existing');
    expect(history.getAll().single.isFavorite, true);
    expect(history.getAll().single.resultJson, contains('今日已付费报告'));
    expect(find.byType(AiReportContent), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Markdown headings and tables fit phone and desktop',
      (tester) async {
    for (final width in [320.0, 1100.0]) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: AiReportContent(
                          text:
                              '## 传统依据\n\n**重点内容**\n\n1. 第一条\n2. 第二条\n\n|爻位|依据|\n|---|---|\n|九三|守正，谨慎应对变化。|'))))));
      await tester.pumpAndSettle();
      expect(find.byType(Table), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets(
      'today daily report restores on each reopening without generation',
      (tester) async {
    final api = DailyApi()
      ..daily = const ServerAiReport(
          id: 'today',
          productId: 'daily_hexagram_brief',
          status: 'completed',
          priceCents: 200,
          resultText: '## 今日解析\n\n免费复看');
    for (var open = 0; open < 2; open++) {
      await tester.pumpWidget(panel(api));
      await tester.pumpAndSettle();
      expect(tester.widget<AiReportContent>(find.byType(AiReportContent)).text,
          contains('免费复看'));
      expect(
          tester
              .widget<FilledButton>(
                  find.byKey(const Key('ai_report_daily_hexagram_brief')))
              .onPressed,
          isNull);
      await tester.pumpWidget(const SizedBox());
    }
    expect(api.dailyReads, 2);
    expect(api.detailReads, 0);
  });

  testWidgets(
      'pending daily report resumes polling and shows completed content',
      (tester) async {
    final api = DailyApi()
      ..daily = const ServerAiReport(
          id: 'today',
          productId: 'daily_hexagram_brief',
          status: 'generating',
          priceCents: 200);
    await tester.pumpWidget(panel(api));
    await tester.pump();
    expect(find.text('生成中'), findsOneWidget);
    expect(find.byType(AiReportContent), findsNothing);
    await tester.pump(const Duration(seconds: 20));
    await tester.pumpAndSettle();
    expect(find.byType(AiReportContent), findsOneWidget);
    expect(api.detailReads, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('late daily response cannot leak after logout', (tester) async {
    final waiting = Completer<ServerAiReport?>();
    final api = DailyApi()..waiting = waiting;
    final auth = AuthStore(
        initialState: const AuthState(
            initialized: true, token: 'test', user: AppUser(id: 'owner')));
    await tester.pumpWidget(panel(api, auth: auth));
    await tester.pump();
    await auth.logout();
    await tester.pump();
    waiting.complete(const ServerAiReport(
        id: 'today',
        productId: 'daily_hexagram_brief',
        status: 'completed',
        priceCents: 200,
        resultText: 'private report'));
    await tester.pumpAndSettle();
    expect(find.byType(AiReportContent), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('open detail polls and formats the report without recharging',
      (tester) async {
    final api = DailyApi();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authStoreProvider.overrideWith((ref) => AuthStore(
              initialState: const AuthState(
                  initialized: true,
                  token: 'test',
                  user: AppUser(id: 'owner')))),
        ],
        child: MaterialApp(
            home: Scaffold(
                body: AiReportDetailSheet(
                    api: api,
                    ownerId: 'owner',
                    title: '今日报告',
                    report: const ServerAiReport(
                        id: 'today',
                        productId: 'daily_hexagram_brief',
                        status: 'generating',
                        priceCents: 200))))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    await tester.pumpAndSettle();
    expect(find.byType(AiReportContent), findsOneWidget);
    expect(find.text('复制报告'), findsOneWidget);
    expect(api.detailReads, 1);
    await tester.pumpWidget(const SizedBox());
  });
}

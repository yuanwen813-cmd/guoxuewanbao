import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/features/ai_reports/ai_report_product_panel.dart';
import 'package:guoxueapp/features/auth/auth_store.dart';
import 'package:guoxueapp/features/wallet/server_wallet_api.dart';
import 'package:guoxueapp/features/wallet/wallet_store.dart';
import 'package:guoxueapp/infrastructure/local_persistence/local_json_store.dart';

WalletState accountA() => WalletState(balanceCents: 1000, transactions: [
      WalletTransaction(
          id: 'a-recharge',
          type: WalletTransactionType.recharge,
          amountCents: 1000,
          title: 'Account A recharge',
          createdAt: DateTime(2026, 9, 28)),
    ]);

class AuditApi extends ServerWalletApi {
  WalletState response = accountA();
  Completer<WalletState>? delayedFetch;
  bool failFetch = false;
  Completer<ServerAiReportResult>? delayedReport;

  @override
  Future<WalletState> fetchWallet() async {
    if (failFetch) throw const ServerWalletException('offline');
    if (delayedFetch != null) return await delayedFetch!.future;
    return response;
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
  }) async {
    if (delayedReport != null) return await delayedReport!.future;
    response = response.copyWith(balanceCents: 800);
    return const ServerAiReportResult(
      answer: 'Completed report',
      model: 'test',
      reportId: 'report-1',
      wallet: WalletState(balanceCents: 800),
    );
  }
}

class RetryWallet extends WalletStore {
  RetryWallet({this.refusal = false}) : super(useServer: false);
  final bool refusal;
  final ids = <String>[];
  final prompts = <String>[];

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
  }) async {
    ids.add(requestId);
    prompts.add(userPrompt);
    if (ids.length == 1) {
      if (refusal) {
        throw const ServerWalletException('本次未完成解析，2 积分已退回。你可以修改问题后重新解析。',
            statusCode: 424, refunded: true);
      }
      throw const ServerWalletException(
          'Simulated connection loss after submission');
    }
    return const ServerAiReportResult(
        answer: 'Recovered',
        model: 'test',
        reportId: 'report-1',
        wallet: WalletState(balanceCents: 800));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('an offline server wallet never restores another account cache',
      () async {
    await writeLocalJson(
        'guoxueapp.wallet.v1', jsonEncode(accountA().toJson()));
    final wallet = WalletStore(api: AuditApi()..failFetch = true);
    addTearDown(wallet.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(wallet.state.balanceCents, 0);
    expect(wallet.state.transactions, isEmpty);
    expect(await readLocalJson('guoxueapp.wallet.v1'), isNull);
  });

  test('partial refund snapshot preserves ledger when refresh fails', () async {
    final api = AuditApi();
    final wallet = WalletStore(api: api);
    addTearDown(wallet.dispose);
    await Future<void>.delayed(Duration.zero);
    api.failFetch = true;
    await wallet
        .replaceFromServer(WalletState.fromJson({'balanceCents': 1200}));
    expect(wallet.state.balanceCents, 1200);
    expect(wallet.state.transactions, hasLength(1));
    await wallet.replaceFromServer(
        WalletState.fromJson({'balanceCents': 0, 'transactions': []}));
    expect(wallet.state.transactions, isEmpty);
  });

  test('late initial wallet load is discarded after logout', () async {
    final response = Completer<WalletState>();
    final wallet = WalletStore(api: AuditApi()..delayedFetch = response);
    addTearDown(wallet.dispose);
    await wallet.clearLocalSession();
    response.complete(accountA());
    await Future<void>.delayed(Duration.zero);
    expect(wallet.state.balanceCents, 0);
    expect(wallet.state.transactions, isEmpty);
  });

  test('late report cannot restore wallet after logout or disposal', () async {
    for (final dispose in [false, true]) {
      final response = Completer<ServerAiReportResult>();
      final wallet = WalletStore(api: AuditApi()..delayedReport = response);
      await Future<void>.delayed(Duration.zero);
      final pending = wallet.generateAiReport(
          productId: 'question_full_3_9',
          featureKey: 'coin_hexagram',
          title: 'report',
          systemPrompt: '',
          userPrompt: 'question',
          temperature: 0.45,
          expectedPointsCenti: 200,
          requestId: '44ca2c50-6cbf-479c-8f6f-0d70d01a2d01');
      await wallet.clearLocalSession();
      if (dispose) wallet.dispose();
      response.complete(const ServerAiReportResult(
          answer: 'Old result',
          model: 'test',
          wallet: WalletState(balanceCents: 800)));
      await pending;
      if (!dispose) {
        expect(wallet.state.balanceCents, 0);
        wallet.dispose();
      }
    }
  });

  test('AI result does not erase the current wallet ledger', () async {
    final wallet = WalletStore(api: AuditApi());
    addTearDown(wallet.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(wallet.state.transactions, hasLength(1));
    await wallet.generateAiReport(
        productId: 'question_full_3_9',
        featureKey: 'coin_hexagram',
        title: 'report',
        systemPrompt: '',
        userPrompt: 'question',
        temperature: 0.45,
        expectedPointsCenti: 200,
        requestId: '44ca2c50-6cbf-479c-8f6f-0d70d01a2d01');
    expect(wallet.state.balanceCents, 800);
    expect(wallet.state.transactions, isNotEmpty,
        reason:
            'Opening WalletPage while already signed in does not reload the ledger.');
  });

  test('late account A response cannot overwrite account B after logout',
      () async {
    final api = AuditApi();
    final wallet = WalletStore(api: api);
    addTearDown(wallet.dispose);
    await Future<void>.delayed(Duration.zero);
    final oldResponse = Completer<WalletState>();
    api.delayedFetch = oldResponse;
    final pendingA = wallet.syncFromServer();
    await wallet.clearLocalSession();
    api.delayedFetch = null;
    api.response = const WalletState(balanceCents: 200);
    await wallet.syncFromServer();
    expect(wallet.state.balanceCents, 200);
    oldResponse.complete(accountA());
    await pendingA;
    expect(wallet.state.balanceCents, 200,
        reason: 'The late request belongs to the logged-out account.');
    expect(wallet.state.transactions.where((tx) => tx.id == 'a-recharge'),
        isEmpty);
  });

  for (final scenario in [0, 1, 2, 3]) {
    final editQuestion = scenario.isOdd;
    final refusal = scenario >= 2;
    testWidgets('retry identity, edit=$editQuestion, refunded=$refusal',
        (tester) async {
      final wallet = RetryWallet(refusal: refusal);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            walletStoreProvider.overrideWith((ref) => wallet),
            authStoreProvider.overrideWith((ref) => AuthStore(
                initialState: const AuthState(
                    initialized: true, token: 'test', user: AppUser(id: 'a')))),
          ],
          child: const MaterialApp(
              home: Scaffold(
                  body: SingleChildScrollView(
            child: AiReportProductPanel(
                featureKey: 'coin_hexagram',
                initialFocus: 'First question',
                sourceSummary: 'test hexagram'),
          )))));
      await tester.pumpAndSettle();
      final button =
          find.byKey(const Key('ai_report_coin_hexagram_question_full'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      if (refusal) {
        expect(find.textContaining('2 积分已退回'), findsOneWidget);
        expect(find.text('重新解析'), findsOneWidget);
      }
      if (editQuestion) {
        final edit =
            find.byKey(const Key('ai_report_edit_coin_hexagram_question_full'));
        await tester.ensureVisible(edit);
        await tester.tap(edit);
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<TextField>(
                    find.byKey(const Key('ai_report_focus_coin_hexagram')))
                .focusNode!
                .hasFocus,
            isTrue);
        await tester.enterText(
            find.byKey(const Key('ai_report_focus_coin_hexagram')),
            'Changed question');
        await tester.ensureVisible(button);
      }
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(wallet.ids, hasLength(2));
      if (editQuestion) {
        expect(wallet.prompts[1], isNot(wallet.prompts[0]));
        expect(wallet.ids[1], isNot(wallet.ids[0]),
            reason: 'SQL rejects a reused request ID with a different prompt.');
      } else if (refusal) {
        expect(wallet.ids[1], isNot(wallet.ids[0]));
      } else {
        expect(wallet.ids[1], wallet.ids[0]);
      }
    });
  }
}

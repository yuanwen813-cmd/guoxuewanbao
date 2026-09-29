import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/features/ai_reports/my_reports_page.dart';
import 'package:guoxueapp/features/auth/auth_store.dart';
import 'package:guoxueapp/features/wallet/server_wallet_api.dart';

class ReportsApi extends ServerWalletApi {
  final pages = <int>[];
  final opened = <String>[];
  Completer<List<ServerAiReport>>? nextPage;
  bool failNextPage = false;

  List<ServerAiReport> rows(int start, int count) => List.generate(
      count,
      (i) => ServerAiReport(
          id: 'report-${start + i}',
          productId: 'question_full_3_9',
          status: 'completed',
          priceCents: 200,
          createdAt: DateTime(2026, 9, 29)));

  @override
  Future<List<ServerAiReport>> fetchAiReports(
      {int page = 1, int pageSize = 50}) async {
    pages.add(page);
    if (page == 1) return rows(0, 50);
    if (failNextPage) throw const ServerWalletException('offline');
    if (nextPage != null) return await nextPage!.future;
    return rows(50, 3);
  }

  @override
  Future<ServerAiReport> fetchAiReportDetail(String orderId) async {
    opened.add(orderId);
    return ServerAiReport(
        id: orderId,
        productId: 'question_full_3_9',
        status: 'completed',
        priceCents: 200,
        resultText: 'Previously paid report content');
  }
}

Widget page(ReportsApi api) => ProviderScope(overrides: [
      authStoreProvider.overrideWith((ref) => AuthStore(
          initialState: const AuthState(
              initialized: true, token: 'test', user: AppUser(id: 'owner')))),
    ], child: MaterialApp(home: MyReportsPage(api: api)));

void main() {
  testWidgets('older than 50 reports can load and reopen without generation',
      (tester) async {
    final api = ReportsApi()..nextPage = Completer<List<ServerAiReport>>();
    await tester.pumpWidget(page(api));
    await tester.pumpAndSettle();
    final more = find.byKey(const Key('ai_reports_load_more'));
    await tester.scrollUntilVisible(more, 500, maxScrolls: 30);
    await tester.tap(more);
    await tester.pump();
    expect(tester.widget<TextButton>(more).onPressed, isNull);
    expect(api.pages, [1, 2]);
    api.nextPage!.complete(api.rows(50, 3));
    await tester.pumpAndSettle();
    expect(more, findsNothing);
    final older = find.byKey(const ValueKey('my_report_report-52'));
    await tester.scrollUntilVisible(older, 350);
    await tester.tap(older);
    await tester.pumpAndSettle();
    expect(api.opened, ['report-52']);
    expect(find.text('Previously paid report content'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('failed next page can retry without skipping a page',
      (tester) async {
    final api = ReportsApi()..failNextPage = true;
    await tester.pumpWidget(page(api));
    await tester.pumpAndSettle();
    final more = find.byKey(const Key('ai_reports_load_more'));
    await tester.scrollUntilVisible(more, 500, maxScrolls: 30);
    await tester.tap(more);
    await tester.pumpAndSettle();
    api.failNextPage = false;
    await tester.scrollUntilVisible(more, 300, maxScrolls: 30);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(api.pages, [1, 2, 2]);
    expect(more, findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}

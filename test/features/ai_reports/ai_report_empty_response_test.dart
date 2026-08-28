import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/common/common_result_models.dart';
import 'package:guoxueapp/features/ai_reports/ai_report_product_config.dart';
import 'package:guoxueapp/features/ai_reports/ai_report_product_panel.dart';
import 'package:guoxueapp/features/wallet/wallet_store.dart';

void main() {
  testWidgets('empty historical AI response exposes refund notice and retry',
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
                initialReports: [
                  AiReportSnapshot(
                    productId: 'coin_hexagram_question_full',
                    featureKey: AiReportFeatureKeys.coinHexagram,
                    title: '¥3.9 标准解读',
                    reportType: 'question_full',
                    priceLabel: '¥3.9',
                    text: 'AI 服务未返回内容。',
                    reportId: '00000000-0000-0000-0000-000000000003',
                    createdAt: DateTime(2026, 8, 27, 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('AI 服务未返回内容。'), findsNothing);
    expect(find.textContaining('费用已自动退回'), findsOneWidget);
    expect(find.text('重新解析'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('ai_report_coin_hexagram_question_full')),
    );
    expect(button.onPressed, isNotNull);
  });
}

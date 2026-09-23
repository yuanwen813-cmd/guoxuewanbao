import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/features/divination/takashima/takashima_page.dart';
import 'package:guoxueapp/features/result_common/common_divination_result_page.dart';
import 'package:guoxueapp/features/wallet/wallet_store.dart';

void main() {
  testWidgets('takashima keeps original cast time when the page rebuilds',
      (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          walletStoreProvider
              .overrideWith((ref) => WalletStore(useServer: false)),
        ],
        child: const MaterialApp(home: TakashimaPage()),
      ));
      await rootBundle.loadString('assets/data/iching/hexagrams_64.json');
      await rootBundle.loadString('assets/data/iching/yao_384.json');
    });
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '测试事项');
    for (final label in ['第一次摇卦（得上卦）', '第二次摇卦（得下卦）', '第三次摇卦（得动爻）', '成卦·查看结果']) {
      final action = find.text(label);
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
    }
    final before = tester
        .widget<CommonDivinationResultPage>(
          find.byType(CommonDivinationResultPage),
        )
        .result;
    await tester.pump(const Duration(minutes: 1));
    tester.element(find.byType(TakashimaPage)).markNeedsBuild();
    await tester.pumpAndSettle();
    final after = tester
        .widget<CommonDivinationResultPage>(
          find.byType(CommonDivinationResultPage),
        )
        .result;
    expect(after.createdAt, before.createdAt);
    expect(after.castTimeUtc, before.castTimeUtc);
    expect(after.toJson()['castTimeUtc'], before.toJson()['castTimeUtc']);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/features/divination/coin_hexagram/coin_hexagram_page.dart';
import 'package:guoxueapp/features/divination/meihua/meihua_page.dart';
import 'package:guoxueapp/features/divination/takashima/takashima_page.dart';
import 'package:guoxueapp/features/money_hexagram/money_hexagram_page.dart';

void main() {
  const guidance = '闭气凝神，冥想所问之事，待脑中无杂念之时，点击摇卦。';
  const pages = <String, Widget>{
    'coin hexagram': CoinHexagramPage(),
    'legacy money hexagram': MoneyHexagramPage(),
    'meihua': MeihuaYiPage(),
    'takashima': TakashimaPage(),
  };

  for (final viewport in [const Size(390, 844), const Size(1024, 900)]) {
    for (final entry in pages.entries) {
      testWidgets('${entry.key} shows casting guidance at $viewport',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewport;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp(home: entry.value)),
        );
        await tester.pumpAndSettle();

        expect(find.text(guidance), findsOneWidget);
        expect(find.textContaining('憋不住'), findsNothing);
        expect(find.textContaining('拜神'), findsNothing);
        expect(find.textContaining('请静心默念所问之事，自下而上摇出六爻'), findsNothing);
        await tester.ensureVisible(find.text(guidance));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}

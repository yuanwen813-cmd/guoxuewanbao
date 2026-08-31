import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guoxueapp/shared/widgets/app_back_button.dart';

void main() {
  testWidgets('back button uses its fallback for a directly opened page',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/detail',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('首页')),
        ),
        GoRoute(
          path: '/detail',
          builder: (_, __) => Scaffold(
            appBar: AppBar(
              leading: AppBackButton(fallbackLocation: '/'),
              title: Text('详情'),
            ),
            body: Text('详情内容'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('详情内容'), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsOneWidget);
  });
}

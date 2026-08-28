import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/features/ask_guidance/ask_question_template_panel.dart';
import 'package:guoxueapp/features/ask_guidance/ask_question_templates.dart';

void main() {
  test('template library has eight complete and unique scenarios', () {
    final scenarios = AskQuestionTemplateLibrary.enabledScenarios();

    expect(AskQuestionTemplateLibrary.validate(), isEmpty);
    expect(
      scenarios.map((scenario) => scenario.name),
      ['感情', '工作', '财运', '合作', '人际', '学业', '出行', '选择'],
    );
    expect(scenarios, hasLength(8));
    expect(
      scenarios.every((scenario) => scenario.templates.length >= 8),
      isTrue,
    );
    expect(
      scenarios
          .expand((scenario) => scenario.templates)
          .map((item) => item.id)
          .toSet(),
      hasLength(64),
    );
  });

  testWidgets('template fills the free input but does not submit it',
      (tester) async {
    final controller = TextEditingController();
    var appliedCount = 0;
    await tester.pumpWidget(
      _host(
        controller: controller,
        onTemplateApplied: (_) => appliedCount += 1,
      ),
    );

    expect(find.byKey(const Key('ask_scenario_work')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ask_scenario_work')));
    await tester.pump();
    expect(
        find.byKey(const Key('ask_template_work_change_001')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ask_template_work_change_001')));
    await tester.pump();

    expect(controller.text, '我现在适合换工作吗？');
    expect(appliedCount, 1);
    expect(find.text('已填入问题，你还可以继续修改。'), findsOneWidget);

    controller.text = '${controller.text} 我目前在这家公司工作三年了。';
    expect(controller.text, contains('工作三年'));
    controller.dispose();
  });

  testWidgets('existing input is never replaced without confirmation',
      (tester) async {
    final controller = TextEditingController(text: '我已经写好的问题');
    await tester.pumpWidget(_host(controller: controller));

    await tester.tap(find.byKey(const Key('ask_scenario_work')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ask_template_work_change_001')));
    await tester.pumpAndSettle();

    expect(find.text('使用问题模板'), findsOneWidget);
    expect(controller.text, '我已经写好的问题');
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(controller.text, '我已经写好的问题');

    await tester.tap(find.byKey(const Key('ask_template_work_change_001')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('替换原问题'));
    await tester.pumpAndSettle();
    expect(controller.text, '我现在适合换工作吗？');
    controller.dispose();
  });

  testWidgets('empty or invalid configuration hides guidance but keeps input',
      (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(_host(controller: controller, scenarios: const []));

    expect(find.byKey(const Key('ask_question_template_panel')), findsNothing);
    await tester.enterText(
        find.byKey(const Key('free_question_input')), '自由输入仍可使用');
    expect(controller.text, '自由输入仍可使用');
    controller.dispose();
  });

  test('four existing ask pages embed the shared question guidance panel', () {
    for (final path in [
      'lib/features/divination/coin_hexagram/coin_hexagram_page.dart',
      'lib/features/divination/small_liuren/small_liuren_page.dart',
      'lib/features/divination/meihua/meihua_page.dart',
      'lib/features/divination/takashima/takashima_page.dart',
    ]) {
      expect(
          File(path).readAsStringSync(), contains('AskQuestionTemplatePanel'));
    }
  });
}

Widget _host({
  required TextEditingController controller,
  List<AskScenario>? scenarios,
  ValueChanged<AskQuestionTemplate>? onTemplateApplied,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
                key: const Key('free_question_input'), controller: controller),
            AskQuestionTemplatePanel(
              controller: controller,
              scenarios: scenarios,
              onTemplateApplied: onTemplateApplied,
            ),
          ],
        ),
      ),
    ),
  );
}

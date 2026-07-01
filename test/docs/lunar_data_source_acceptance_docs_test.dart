import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// 验收文档存在性和关键内容测试
void main() {
  final docsDir = Directory('../docs');
  final specFile = File('${docsDir.path}/LUNAR_DATA_SOURCE_ACCEPTANCE_V0_1.md');
  final checklistFile = File('${docsDir.path}/LUNAR_DATA_SOURCE_ACCEPTANCE_CHECKLIST_V0_1.md');

  group('Acceptance docs exist', () {
    test('LUNAR_DATA_SOURCE_ACCEPTANCE_V0_1.md exists', () {
      expect(specFile.existsSync(), isTrue);
    });

    test('LUNAR_DATA_SOURCE_ACCEPTANCE_CHECKLIST_V0_1.md exists', () {
      expect(checklistFile.existsSync(), isTrue);
    });
  });

  group('Acceptance spec content checks', () {
    late String content;
    setUp(() {
      content = specFile.readAsStringSync();
    });

    test('contains 2024-02-10 benchmark', () {
      expect(content.contains('2024-02-10'), isTrue);
    });
    test('contains 2025-01-29 benchmark', () {
      expect(content.contains('2025-01-29'), isTrue);
    });
    test('contains 2026-02-17 benchmark', () {
      expect(content.contains('2026-02-17'), isTrue);
    });
    test('contains leap month requirement', () {
      expect(content.contains('闰月'), isTrue);
    });
    test('contains productionReady', () {
      expect(content.contains('productionReady'), isTrue);
    });
    test('contains supportsLunarDate', () {
      expect(content.contains('supportsLunarDate'), isTrue);
    });
    test('forbids AI generation', () {
      final hasAiBan = content.contains('不得由 AI 生成') || content.contains('AI 生成禁止');
      expect(hasAiBan, isTrue);
    });
    test('requires cross verification', () {
      expect(content.contains('交叉验证'), isTrue);
    });
    test('defines unavailable/partial/full tiers', () {
      expect(content.contains('unavailable'), isTrue);
      expect(content.contains('partial'), isTrue);
      expect(content.contains('full'), isTrue);
    });
    test('protects resultSnapshot', () {
      final hasResultProtection = content.contains('resultSnapshot') ||
          content.contains('不受影响') || content.contains('不得破坏') || content.contains('不影响');
      expect(hasResultProtection, isTrue);
    });
  });

  group('Checklist content checks', () {
    late String content;
    setUp(() {
      content = checklistFile.readAsStringSync();
    });

    test('has basic info section', () {
      expect(content.contains('基础信息'), isTrue);
    });
    test('has coverage section', () {
      expect(content.contains('覆盖范围'), isTrue);
    });
    test('has benchmark section', () {
      expect(content.contains('基准测试'), isTrue);
    });
    test('has leap month section', () {
      expect(content.contains('闰月测试'), isTrue);
    });
    test('has cross verification section', () {
      expect(content.contains('交叉验证'), isTrue);
    });
    test('has validator section', () {
      expect(content.contains('Validator'), isTrue);
    });
    test('has capability conclusion section', () {
      expect(content.contains('能力结论'), isTrue);
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/features/zhouyi/zhouyi_models.dart';

void main() {
  test('zhouyi_64.json contains 64 hexagrams and complete line content', () {
    final file = File('assets/data/zhouyi_64.json');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final list = json['hexagrams'] as List<dynamic>;
    final all = list
        .map((item) => ZhouyiHexagram.fromJson(item as Map<String, dynamic>))
        .toList();

    expect(all, hasLength(64));
    expect(all.map((h) => h.id).toSet(), hasLength(64));
    expect(all.every((h) => h.number >= 1 && h.number <= 64), isTrue);

    for (final hexagram in all) {
      expect(hexagram.name.isNotEmpty, isTrue);
      expect(hexagram.symbol.isNotEmpty, isTrue);
      expect(hexagram.judgment.isNotEmpty, isTrue);
      expect(hexagram.image.isNotEmpty, isTrue);
      expect(hexagram.plainText.isNotEmpty, isTrue);
      expect(hexagram.upperTrigram.isNotEmpty, isTrue);
      expect(hexagram.lowerTrigram.isNotEmpty, isTrue);
      expect(hexagram.lines, hasLength(6));

      for (final line in hexagram.lines) {
        expect(line.lineName.isNotEmpty, isTrue);
        expect(line.text.isNotEmpty, isTrue);
        expect(line.meaning.isNotEmpty, isTrue);
      }
    }

    final qian = all.singleWhere((hexagram) => hexagram.number == 1);
    expect(qian.name, '乾为天');
    expect(qian.symbol, '䷀');
    expect(qian.judgment, '元亨利贞。');

    final weiji = all.singleWhere((hexagram) => hexagram.number == 64);
    expect(weiji.name, '火水未济');
  });
}

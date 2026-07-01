import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

import '../../domain/unified/unified_models.dart';

/// 签文条目
class LotEntry {
  final int index;
  final String name;
  final String level; // 上上/上吉/中平/下下
  final String poem;
  final String interpretation;

  const LotEntry({
    required this.index,
    required this.name,
    required this.level,
    required this.poem,
    required this.interpretation,
  });

  factory LotEntry.fromJson(Map<String, dynamic> json) => LotEntry(
    index: json['index'] as int,
    name: json['name'] as String,
    level: json['level'] as String? ?? '中平',
    poem: json['poem'] as String? ?? '',
    interpretation: json['interpretation'] as String? ?? '',
  );
}

/// 签类配置
class LotConfig {
  final String lotType;
  final String title;
  final String subtitle;
  final String ritual;
  final int totalCount;
  final List<LotEntry> lots;

  const LotConfig({
    required this.lotType,
    required this.title,
    required this.subtitle,
    required this.ritual,
    required this.totalCount,
    required this.lots,
  });

  factory LotConfig.fromJson(Map<String, dynamic> json) => LotConfig(
    lotType: json['lotType'] as String,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String? ?? '',
    ritual: json['ritual'] as String? ?? '',
    totalCount: json['totalCount'] as int? ?? json['lots']?.length ?? 100,
    lots: (json['lots'] as List?)
        ?.map((e) => LotEntry.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );

  /// 从 assets/data/lots/ 加载
  static Future<LotConfig> load(String filename) async {
    final jsonStr = await rootBundle.loadString('assets/data/lots/$filename');
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return LotConfig.fromJson(json);
  }
}

/// 统一签文抽取引擎
///
/// 使用方式：
///   final config = await LotConfig.load('guanyin_100.json');
///   final engine = LotDrawingEngine(config);
///   final result = engine.draw();
class LotDrawingEngine {
  final LotConfig config;
  final Random _random;

  LotDrawingEngine(this.config) : _random = Random();

  /// 随机抽取一签
  GuoxueResult draw({String? userQuestion}) {
    final lot = config.lots[_random.nextInt(config.lots.length)];

    final isGood = lot.level.contains('上') || lot.level.contains('吉');
    final isBad = lot.level.contains('下');

    return GuoxueResult(
      featureId: config.lotType,
      featureTitle: config.title,
      categoryId: 'divination',
      createdAt: DateTime.now(),
      sections: [
        ResultSection(
          title: '签文',
          icon: 'star',
          type: ResultSectionType.text,
          text: lot.poem,
        ),
        ResultSection(
          title: lot.name,
          type: ResultSectionType.kvTable,
          kvPairs: [
            MapEntry('签等', lot.level),
            MapEntry('签名', lot.name),
          ],
        ),
        ResultSection(
          title: '传统释签',
          type: ResultSectionType.text,
          text: lot.interpretation,
        ),
        ResultSection(
          title: '签等判断',
          type: ResultSectionType.tags,
          tags: [
            lot.level,
            if (isGood) '吉签' else if (isBad) '凶签' else '平签',
            '第${lot.index}签',
          ],
        ),
      ],
      rawData: {
        'method': 'lot_drawing',
        'lotType': config.lotType,
        'lotIndex': lot.index,
        'lotName': lot.name,
        'lotLevel': lot.level,
        'lotPoem': lot.poem,
        'lotInterpretation': lot.interpretation,
      },
    );
  }
}

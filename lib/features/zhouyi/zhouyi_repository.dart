import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'zhouyi_models.dart';

/// 周易本经数据仓库 — 从 assets/data/zhouyi_64.json 加载
class ZhouyiRepository {
  List<ZhouyiHexagram>? _hexagrams;
  Map<int, ZhouyiHexagram>? _byNumber;

  Future<void> init() async {
    if (_hexagrams != null) return;
    final jsonStr =
        await rootBundle.loadString('assets/data/zhouyi_64.json');
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final list = json['hexagrams'] as List;
    _hexagrams = list
        .map((e) => ZhouyiHexagram.fromJson(e as Map<String, dynamic>))
        .toList();
    _byNumber = {for (final h in _hexagrams!) h.number: h};
  }

  List<ZhouyiHexagram> get allHexagrams {
    if (_hexagrams == null) return [];
    return List.unmodifiable(_hexagrams!);
  }

  ZhouyiHexagram? findByNumber(int number) => _byNumber?[number];
  ZhouyiHexagram? findById(int id) {
    if (_hexagrams == null) return null;
    try {
      return _hexagrams!.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  bool get isReady =>
      _hexagrams != null && _hexagrams!.length == 64;
  int get count => _hexagrams?.length ?? 0;
}

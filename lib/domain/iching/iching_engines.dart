import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

import 'hexagram_models.dart';

/// 六十四卦数据仓库
class HexagramRepository {
  Map<int, Hexagram>? _cache;
  Map<String, Map<String, int>>? _relations;

  Future<Map<int, Hexagram>> loadAll() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/data/iching/hexagrams_64.json');
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final list = json['hexagrams'] as List;
    _cache = {};
    for (final h in list) {
      final hex = Hexagram.fromJson(h as Map<String, dynamic>);
      _cache![hex.index] = hex;
    }
    // 补齐未定义的卦
    for (int i = 1; i <= 64; i++) {
      _cache?.putIfAbsent(i, () => _generateStub(i));
    }
    return _cache!;
  }

  Hexagram? get(int index) => _cache?[index];

  Hexagram _generateStub(int index) {
    final names = ['','乾为天','坤为地','水雷屯','山水蒙','水天需','天水讼','地水师','水地比','风天小畜','天泽履',
      '地天泰','天地否','天火同人','火天大有','地山谦','雷地豫','泽雷随','山风蛊','地泽临','风地观',
      '火雷噬嗑','山火贲','山地剥','地雷复','天雷无妄','山天大畜','山雷颐','泽风大过','坎为水','离为火',
      '泽山咸','雷风恒','天山遁','雷天大壮','火地晋','地火明夷','风火家人','火泽睽','水山蹇','雷水解',
      '山泽损','风雷益','泽天夬','天风姤','泽地萃','地风升','泽水困','水风井','泽火革','火风鼎',
      '震为雷','艮为山','风山渐','雷泽归妹','雷火丰','火山旅','巽为风','兑为泽','风水涣','水泽节',
      '风泽中孚','雷山小过','水火既济','火水未济'];
    return Hexagram(index: index, name: names[index], binary: '111111',
      upper: '乾', lower: '乾', judgment: '卦辞未收录，请查阅《周易》原文。');
  }

  Future<Map<String, Map<String, int>>> loadRelations() async {
    if (_relations != null) return _relations!;
    final jsonStr = await rootBundle.loadString('assets/data/iching/hexagram_relations.json');
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    _relations = {};
    for (final entry in (json['relations'] as Map<String, dynamic>).entries) {
      _relations![entry.key] = Map<String, int>.from(entry.value as Map);
    }
    return _relations!;
  }
}

/// 蓍草起卦引擎（大衍之数五十，其用四十有九）
class YarrowStalkEngine {
  final Random _random;

  YarrowStalkEngine() : _random = Random();

  /// 演算一爻：三变成一爻
  /// 返回 0=老阴, 1=少阳, 2=少阴, 3=老阳（0和3为动爻）
  int castOneLine() {
    int stalks = 49;
    // 一变
    final left1 = _random.nextInt(stalks - 2) + 1;
    int left = left1;
    int right = stalks - left;
    right -= 1; // 取出1根
    int remainder = (left % 4 == 0 ? 4 : left % 4) + (right % 4 == 0 ? 4 : right % 4) + 1;
    stalks -= remainder;

    // 二变
    final left2 = _random.nextInt(stalks - 2) + 1;
    left = left2; right = stalks - left;
    right -= 1;
    remainder = (left % 4 == 0 ? 4 : left % 4) + (right % 4 == 0 ? 4 : right % 4) + 1;
    stalks -= remainder;

    // 三变
    final left3 = _random.nextInt(stalks - 2) + 1;
    left = left3; right = stalks - left;
    right -= 1;
    remainder = (left % 4 == 0 ? 4 : left % 4) + (right % 4 == 0 ? 4 : right % 4) + 1;
    stalks -= remainder;

    final result = stalks ~/ 4; // 6,7,8,9 -> 老阴,少阳,少阴,老阳
    return result - 6; // 0=6(老阴), 1=7(少阳), 2=8(少阴), 3=9(老阳)
  }

  /// 演算六爻，返回 [0-3, 0-3, 0-3, 0-3, 0-3, 0-3]（从初爻到上爻）
  List<int> castHexagram() {
    return List.generate(6, (_) => castOneLine());
  }
}

/// 数字起卦引擎
class NumberCastingEngine {
  /// 用三个数字起卦（天地人三数）
  /// 返回六爻值 [0-3, ...]（从初爻到上爻）
  List<int> fromThreeNumbers(int a, int b, int c) {
    final upperYao = a % 8;  // 上卦
    final lowerYao = b % 8;  // 下卦
    final changingLine = c % 6; // 动爻位置 (0-5)

    // 八卦映射：乾1兑2离3震4巽5坎6艮7坤8
    const trigramBits = {1:7, 2:6, 3:5, 4:4, 5:3, 6:2, 7:1, 8:0}; // 转为3爻阴阳值

    int upper = trigramBits[upperYao] ?? 7;
    int lower = trigramBits[lowerYao] ?? 0;
    if (upperYao == 0) upper = 7; // 8%8=0 → 坤
    if (lowerYao == 0) lower = 0;

    final lines = <int>[];
    for (int i = 0; i < 3; i++) {
      final y = (lower & (1 << i)) != 0 ? 1 : 0; // 阳=少阳(1), 阴=少阴(2)
      lines.add(y == 1 ? 1 : 2);
    }
    for (int i = 0; i < 3; i++) {
      final y = (upper & (1 << i)) != 0 ? 1 : 0;
      lines.add(y == 1 ? 1 : 2);
    }
    if (changingLine >= 0 && changingLine < 6) {
      final old = lines[changingLine];
      lines[changingLine] = old == 1 ? 3 : 0; // 动爻
    }
    return lines;
  }
}

/// 卦象推演引擎
class HexagramEngine {
  /// 从六爻值构建本卦和变卦
  /// lines: [0-3, ...] 初爻到上爻
  ({Hexagram original, Hexagram changed, List<YaoLine> yaoLines}) derive(
    List<int> lines, Map<int, Hexagram> repo,
  ) {
    final originalYang = lines.map((v) => v == 1 || v == 3).toList();
    final changedYang = lines.map((v) => v == 1 || v == 0 ? (v == 1) : (v == 0)).toList();
    final changing = lines.map((v) => v == 0 || v == 3).toList();

    final origBin = originalYang.reversed.map((y) => y ? '1' : '0').join();
    final changedBin = changedYang.reversed.map((y) => y ? '1' : '0').join();

    final origIndex = _findByBinary(origBin, repo);
    final changedIndex = _findByBinary(changedBin, repo);

    final orig = repo[origIndex] ?? Hexagram(index: origIndex, name: Hexagram.identify(originalYang), binary: origBin, upper: '', lower: '');
    final changed = repo[changedIndex] ?? Hexagram(index: changedIndex, name: Hexagram.identify(changedYang), binary: changedBin, upper: '', lower: '');

    final yaoLines = orig.buildLines(changing);

    return (original: orig, changed: changed, yaoLines: yaoLines);
  }

  int _findByBinary(String bin, Map<int, Hexagram> repo) {
    for (final h in repo.values) {
      if (h.binary == bin) return h.index;
    }
    return 1;
  }
}

/// 高岛易断解释器（本地部分）
class TakashimaInterpreter {
  /// 生成本地解释（AI失败时作为兜底）
  String buildLocalInterpretation({
    required Hexagram original,
    required Hexagram changed,
    required List<YaoLine> yaoLines,
    required String userQuestion,
  }) {
    final changingLines = yaoLines.where((y) => y.isChanging).toList();
    final changingNames = changingLines.map((y) => y.stageName).join('、');

    final buf = StringBuffer();
    buf.writeln('【高岛式断语（本地基础版）】');
    buf.writeln();
    buf.writeln('问事：$userQuestion');
    buf.writeln('本卦：${original.name}');
    if (changingLines.isNotEmpty) {
      buf.writeln('动爻：$changingNames');
      buf.writeln('变卦：${changed.name}');
    }
    buf.writeln();
    buf.writeln('卦辞：${original.judgment}');
    if (original.image != null && original.image!.isNotEmpty) {
      buf.writeln('象意：${original.image}');
    }
    buf.writeln();
    for (final y in changingLines) {
      if (y.text != null) {
        buf.writeln('${y.stageName}爻辞：${y.text}');
      }
    }
    buf.writeln();
    buf.writeln('断曰：');
    buf.writeln('此卦所示，须结合本卦${original.name}与动爻之象审慎判断。');
    buf.writeln('建议静心思考所问之事与卦象的关联，以中正平和之心待之。');

    return buf.toString();
  }

  /// 构建AI提示词用的结构化数据
  Map<String, dynamic> buildPromptData({
    required Hexagram original,
    required Hexagram changed,
    required List<YaoLine> yaoLines,
    required String userQuestion,
    required String castingMethod,
  }) {
    return {
      'method': 'takashima',
      'castingMethod': castingMethod,
      'userQuestion': userQuestion,
      'originalHexagram': original.name,
      'originalIndex': original.index,
      'originalJudgment': original.judgment,
      'originalImage': original.image ?? '',
      'originalTuan': original.tuan ?? '',
      'changedHexagram': changed.name,
      'changingLines': yaoLines.where((y) => y.isChanging).map((y) => {
        'stage': y.stageName, 'text': y.text ?? '', 'symbol': y.symbol,
      }).toList(),
      'allLines': yaoLines.map((y) => {
        'stage': y.stageName, 'yang': y.isYang, 'changing': y.isChanging,
        'symbol': y.symbol, 'text': y.text ?? '',
      }).toList(),
    };
  }
}

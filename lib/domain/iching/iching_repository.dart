import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'takashima_models.dart';

/// 统一六十四卦数据仓库
class HexagramRepository {
  Map<int, FullHexagramInfo>? _byId;
  Map<String, FullHexagramInfo>? _byLines;

  Future<void> init() async {
    if (_byId != null) return;
    _byId = {};
    _byLines = {};
    final jsonStr = await rootBundle.loadString('assets/data/iching/hexagrams_64.json');
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final list = json['hexagrams'] as List;
    for (final item in list) {
      final h = _parseItem(item as Map<String, dynamic>);
      _byId![h.index] = h;
      _byLines![h.lines.join()] = h;
    }
  }

  FullHexagramInfo _parseItem(Map<String, dynamic> j) {
    final lines = (j['lines'] as List).map((e) => (e as num).toInt()).toList();
    return FullHexagramInfo(
      index: (j['id'] as num).toInt(),
      name: j['name'] as String,
      symbol: hexagramSymbol((j['id'] as num).toInt()),
      upper: trigramsByName[j['upperTrigram'] as String] ?? trigrams[8]!,
      lower: trigramsByName[j['lowerTrigram'] as String] ?? trigrams[8]!,
      lines: lines,
      judgment: j['judgement'] as String? ?? '',
      image: j['image'] as String? ?? '',
      meaning: j['meaning'] as String? ?? '',
    );
  }

  FullHexagramInfo? findById(int id) => _byId?[id];
  FullHexagramInfo? findByLines(List<int> lines) => _byLines?[lines.join()];
  bool get isReady => _byId != null && _byId!.length == 64;
}

/// 统一三百八十四爻数据仓库
class YaoRepository {
  Map<String, YaoData>? _byKey;

  Future<void> init() async {
    if (_byKey != null) return;
    _byKey = {};
    final jsonStr = await rootBundle.loadString('assets/data/iching/yao_384.json');
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final list = json['yaoLines'] as List;
    for (final item in list) {
      final y = item as Map<String, dynamic>;
      final key = '${y['hexagramId']}-${y['line']}';
      _byKey![key] = YaoData(
        hexagramId: (y['hexagramId'] as num).toInt(),
        line: (y['line'] as num).toInt(),
        lineName: y['lineName'] as String,
        text: y['text'] as String,
        meaning: y['meaning'] as String? ?? '',
        advice: y['advice'] as String? ?? '',
      );
    }
  }

  YaoData? findByHexagramAndLine(int hexagramId, int line) {
    return _byKey?['$hexagramId-$line'];
  }

  bool get isReady => _byKey != null && _byKey!.length == 384;
  int get count => _byKey?.length ?? 0;
}

/// 爻数据
class YaoData {
  final int hexagramId;
  final int line;
  final String lineName;
  final String text;
  final String meaning;
  final String advice;
  const YaoData({required this.hexagramId, required this.line, required this.lineName,
    required this.text, required this.meaning, required this.advice});
}

/// 卦的 Unicode 符号
String hexagramSymbol(int index) {
  if (index < 1 || index > 64) return '';
  return String.fromCharCode(0x4DBF + index);
}

/// 八卦名称查找
const trigramsByName = {
  '乾': TrigramInfo(number: 1, name: '乾', element: '天', lines: [1,1,1]),
  '兑': TrigramInfo(number: 2, name: '兑', element: '泽', lines: [1,1,0]),
  '离': TrigramInfo(number: 3, name: '离', element: '火', lines: [1,0,1]),
  '震': TrigramInfo(number: 4, name: '震', element: '雷', lines: [1,0,0]),
  '巽': TrigramInfo(number: 5, name: '巽', element: '风', lines: [0,1,1]),
  '坎': TrigramInfo(number: 6, name: '坎', element: '水', lines: [0,1,0]),
  '艮': TrigramInfo(number: 7, name: '艮', element: '山', lines: [0,0,1]),
  '坤': TrigramInfo(number: 8, name: '坤', element: '地', lines: [0,0,0]),
};

/// 从 takashima_cast_engine 引用 trigrams
const trigrams = <int, TrigramInfo>{
  1: TrigramInfo(number: 1, name: '乾', element: '天', lines: [1, 1, 1]),
  2: TrigramInfo(number: 2, name: '兑', element: '泽', lines: [1, 1, 0]),
  3: TrigramInfo(number: 3, name: '离', element: '火', lines: [1, 0, 1]),
  4: TrigramInfo(number: 4, name: '震', element: '雷', lines: [1, 0, 0]),
  5: TrigramInfo(number: 5, name: '巽', element: '风', lines: [0, 1, 1]),
  6: TrigramInfo(number: 6, name: '坎', element: '水', lines: [0, 1, 0]),
  7: TrigramInfo(number: 7, name: '艮', element: '山', lines: [0, 0, 1]),
  8: TrigramInfo(number: 8, name: '坤', element: '地', lines: [0, 0, 0]),
};

/// 六十四卦映射表
const hexagramTable = {
  '天天': [1, '乾为天'], '天地': [12, '天地否'], '天雷': [25, '天雷无妄'], '天风': [44, '天风姤'],
  '天水': [6, '天水讼'], '天火': [13, '天火同人'], '天山': [33, '天山遁'], '天泽': [10, '天泽履'],
  '地天': [11, '地天泰'], '地地': [2, '坤为地'], '地雷': [24, '地雷复'], '地风': [46, '地风升'],
  '地水': [7, '地水师'], '地火': [36, '地火明夷'], '地山': [15, '地山谦'], '地泽': [19, '地泽临'],
  '雷天': [34, '雷天大壮'], '雷地': [16, '雷地豫'], '雷雷': [51, '震为雷'], '雷风': [32, '雷风恒'],
  '雷水': [40, '雷水解'], '雷火': [55, '雷火丰'], '雷山': [62, '雷山小过'], '雷泽': [54, '雷泽归妹'],
  '风天': [9, '风天小畜'], '风地': [20, '风地观'], '风雷': [42, '风雷益'], '风风': [57, '巽为风'],
  '风水': [59, '风水涣'], '风火': [37, '风火家人'], '风山': [53, '风山渐'], '风泽': [61, '风泽中孚'],
  '水天': [5, '水天需'], '水地': [8, '水地比'], '水雷': [3, '水雷屯'], '水风': [48, '水风井'],
  '水水': [29, '坎为水'], '水火': [63, '水火既济'], '水山': [39, '水山蹇'], '水泽': [60, '水泽节'],
  '火天': [14, '火天大有'], '火地': [35, '火地晋'], '火雷': [21, '火雷噬嗑'], '火风': [50, '火风鼎'],
  '火水': [64, '火水未济'], '火火': [30, '离为火'], '火山': [56, '火山旅'], '火泽': [38, '火泽睽'],
  '山天': [26, '山天大畜'], '山地': [23, '山地剥'], '山雷': [27, '山雷颐'], '山风': [18, '山风蛊'],
  '山水': [4, '山水蒙'], '山火': [22, '山火贲'], '山山': [52, '艮为山'], '山泽': [41, '山泽损'],
  '泽天': [43, '泽天夬'], '泽地': [45, '泽地萃'], '泽雷': [17, '泽雷随'], '泽风': [28, '泽风大过'],
  '泽水': [47, '泽水困'], '泽火': [49, '泽火革'], '泽山': [31, '泽山咸'], '泽泽': [58, '兑为泽'],
};

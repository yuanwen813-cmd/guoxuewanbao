import 'dart:math';
import '../iching/iching_repository.dart';
import '../iching/takashima_models.dart';

/// 金钱卦单次掷币结果
class CoinThrow {
  final int lineNumber;  // 1-6, 1=初爻
  final List<String> coins; // ["zi","bei","bei"]
  final int sum;         // 6,7,8,9
  final String lineType; // old_yin, young_yang, young_yin, old_yang
  final String yinYang;  // "yin" or "yang"
  final int lineValue;   // 0 or 1
  final bool changing;

  const CoinThrow({
    required this.lineNumber, required this.coins, required this.sum,
    required this.lineType, required this.yinYang, required this.lineValue,
    required this.changing,
  });

  String get display {
    const map = {'old_yin':'老阴 ⚋×','young_yang':'少阳 ⚊','young_yin':'少阴 ⚋','old_yang':'老阳 ⚊○'};
    return map[lineType] ?? lineType;
  }

  Map<String, dynamic> toJson() => {
    'lineNumber': lineNumber, 'coins': coins, 'sum': sum,
    'lineType': lineType, 'yinYang': yinYang, 'lineValue': lineValue, 'changing': changing,
  };
}

/// 金钱卦起卦结果
class CoinHexagramResult {
  final String question;
  final String castMode; // app_shake, manual_input
  final List<CoinThrow> throws;
  final List<int> primaryLines;
  final List<int> changedLines;
  final FullHexagramInfo primaryHexagram;
  final List<YaoLineInfo> movingYaos;
  final FullHexagramInfo? changedHexagram;
  final bool noChangingLines;

  const CoinHexagramResult({
    required this.question, required this.castMode, required this.throws,
    required this.primaryLines, required this.changedLines,
    required this.primaryHexagram, required this.movingYaos,
    this.changedHexagram, required this.noChangingLines,
  });

  Map<String, dynamic> toJson() => {
    'question': question, 'castMode': castMode,
    'coinRule': {'zi': 2, 'bei': 3},
    'throws': throws.map((t) => t.toJson()).toList(),
    'primaryLines': primaryLines, 'changedLines': changedLines,
    'primaryHexagram': {'id': primaryHexagram.index, 'name': primaryHexagram.name, 'symbol': primaryHexagram.symbol, 'judgment': primaryHexagram.judgment, 'image': primaryHexagram.image},
    'movingYaos': movingYaos.map((m) => {'line': m.position, 'lineName': m.lineName, 'text': m.text, 'meaning': m.meaning, 'changing': m.isChanging}).toList(),
    if (changedHexagram != null) 'changedHexagram': {'id': changedHexagram!.index, 'name': changedHexagram!.name, 'symbol': changedHexagram!.symbol, 'judgment': changedHexagram!.judgment, 'image': changedHexagram!.image},
    'noChangingLines': noChangingLines,
  };
}

/// 金钱卦引擎
class CoinHexagramEngine {
  final HexagramRepository _hexRepo;
  final YaoRepository _yaoRepo;
  final Random _random = Random();

  CoinHexagramEngine({required HexagramRepository hexRepo, required YaoRepository yaoRepo})
      : _hexRepo = hexRepo, _yaoRepo = yaoRepo;

  /// 生成单次掷币（App摇卦）
  CoinThrow generateThrow(int lineNumber) {
    final coins = List.generate(3, (_) => _random.nextBool() ? 'bei' : 'zi');
    return _computeThrow(lineNumber, coins);
  }

  /// 从手动录入硬币计算一次掷币
  CoinThrow manualThrow(int lineNumber, List<String> coins) {
    return _computeThrow(lineNumber, coins);
  }

  CoinThrow _computeThrow(int lineNumber, List<String> coins) {
    final sum = coins.fold<int>(0, (s, c) => s + (c == 'bei' ? 3 : 2));
    final (lineType, yinYang, lineValue, changing) = switch (sum) {
      6 => ('old_yin', 'yin', 0, true),
      7 => ('young_yang', 'yang', 1, false),
      8 => ('young_yin', 'yin', 0, false),
      9 => ('old_yang', 'yang', 1, true),
      _ => throw ArgumentError('Invalid sum: $sum'),
    };
    return CoinThrow(lineNumber: lineNumber, coins: coins, sum: sum, lineType: lineType, yinYang: yinYang, lineValue: lineValue, changing: changing);
  }

  /// 从六次掷币生成本卦/变卦
  CoinHexagramResult buildResult({
    required String question,
    required String castMode,
    required List<CoinThrow> throws,
  }) {
    if (throws.length != 6) throw ArgumentError('Need exactly 6 throws');
    final primaryLines = throws.map((t) => t.lineValue).toList();
    final changingIndices = <int>[];
    for (int i = 0; i < 6; i++) { if (throws[i].changing) changingIndices.add(i); }
    final changedLines = List<int>.from(primaryLines);
    for (final i in changingIndices) { changedLines[i] = changedLines[i] == 1 ? 0 : 1; }
    final noChanging = changingIndices.isEmpty;

    final primaryHex = _hexRepo.findByLines(primaryLines) ??
        FullHexagramInfo(index: 1, name: '卦', symbol: '', upper: trigrams[1]!, lower: trigrams[1]!, lines: primaryLines, judgment: '');

    FullHexagramInfo? changedHex;
    if (!noChanging) {
      changedHex = _hexRepo.findByLines(changedLines) ??
          FullHexagramInfo(index: 1, name: '变卦', symbol: '', upper: trigrams[1]!, lower: trigrams[1]!, lines: changedLines, judgment: '');
    }

    final movingYaos = <YaoLineInfo>[];
    for (final i in changingIndices) {
      final t = throws[i];
      final yaoData = _yaoRepo.findByHexagramAndLine(primaryHex.index, i + 1);
      movingYaos.add(YaoLineInfo(
        position: i + 1, stageName: ['初','二','三','四','五','上'][i],
        lineName: YaoLineInfo.buildLineName(position: i + 1, isYang: t.lineValue == 1),
        isYang: t.lineValue == 1, isChanging: true,
        text: yaoData?.text, meaning: yaoData?.meaning,
      ));
    }

    return CoinHexagramResult(
      question: question, castMode: castMode, throws: throws,
      primaryLines: primaryLines, changedLines: changedLines,
      primaryHexagram: primaryHex, movingYaos: movingYaos,
      changedHexagram: changedHex, noChangingLines: noChanging,
    );
  }
}

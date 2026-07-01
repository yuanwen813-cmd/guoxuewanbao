import 'dart:math';
import '../iching/iching_repository.dart';
import '../iching/takashima_models.dart';

/// 梅花易数起卦结果
class MeihuaCastResult {
  final String question;
  final String castMethod;
  final Map<String, int> numbers;
  final Map<String, int> calculation;
  final int upperTrigramNumber;
  final int lowerTrigramNumber;
  final int movingLine;
  final TrigramInfo upperTrigram;
  final TrigramInfo lowerTrigram;
  final FullHexagramInfo primaryHexagram;
  final YaoLineInfo movingYao;
  final FullHexagramInfo changedHexagram;
  final FullHexagramInfo? mutualHexagram;

  const MeihuaCastResult({
    required this.question, required this.castMethod, required this.numbers,
    required this.calculation,
    required this.upperTrigramNumber, required this.lowerTrigramNumber,
    required this.movingLine, required this.upperTrigram, required this.lowerTrigram,
    required this.primaryHexagram, required this.movingYao,
    required this.changedHexagram, this.mutualHexagram,
  });

  Map<String, dynamic> toJson() => {
    'featureId': 'meihua_yi', 'question': question, 'castMethod': castMethod,
    'numbers': numbers, 'calculation': calculation,
    'derivedCast': {
      'upperTrigramNumber': upperTrigramNumber, 'lowerTrigramNumber': lowerTrigramNumber,
      'movingLine': movingLine,
      'upperTrigram': {'name': upperTrigram.name, 'element': upperTrigram.element, 'lines': upperTrigram.lines},
      'lowerTrigram': {'name': lowerTrigram.name, 'element': lowerTrigram.element, 'lines': lowerTrigram.lines},
      'primaryHexagram': {'id': primaryHexagram.index, 'name': primaryHexagram.name, 'symbol': primaryHexagram.symbol, 'judgment': primaryHexagram.judgment, 'image': primaryHexagram.image, 'meaning': primaryHexagram.meaning},
      'movingYao': {'line': movingYao.position, 'lineName': movingYao.lineName, 'text': movingYao.text, 'meaning': movingYao.meaning},
      'changedHexagram': {'id': changedHexagram.index, 'name': changedHexagram.name, 'symbol': changedHexagram.symbol, 'judgment': changedHexagram.judgment, 'image': changedHexagram.image, 'meaning': changedHexagram.meaning},
      if (mutualHexagram != null) 'mutualHexagram': {'id': mutualHexagram!.index, 'name': mutualHexagram!.name, 'symbol': mutualHexagram!.symbol, 'judgment': mutualHexagram!.judgment, 'image': mutualHexagram!.image, 'meaning': mutualHexagram!.meaning},
    },
  };
}

/// 梅花易数起卦引擎
class MeihuaEngine {
  final HexagramRepository _hexRepo;
  final YaoRepository _yaoRepo;
  final Random _random = Random();

  MeihuaEngine({required HexagramRepository hexRepo, required YaoRepository yaoRepo})
      : _hexRepo = hexRepo, _yaoRepo = yaoRepo;

  /// 三数起卦
  MeihuaCastResult castByThreeNumbers({
    required String question,
    required int firstNumber,
    required int secondNumber,
    required int thirdNumber,
  }) {
    // 上卦
    final upperRem = firstNumber % 8;
    final upperNum = upperRem == 0 ? 8 : upperRem;
    final upper = trigrams[upperNum]!;

    // 下卦
    final lowerRem = secondNumber % 8;
    final lowerNum = lowerRem == 0 ? 8 : lowerRem;
    final lower = trigrams[lowerNum]!;

    // 动爻
    final moveRem = thirdNumber % 6;
    final movingLine = moveRem == 0 ? 6 : moveRem;
    final moveIdx = movingLine - 1;

    // 本卦六爻（下卦在前，从下往上）
    final primaryLines = [...lower.lines, ...upper.lines];

    // 查本卦
    final primaryHex = _hexRepo.findByLines(primaryLines) ??
        FullHexagramInfo(index: 1, name: '${upper.element}${lower.element}卦', symbol: '',
            upper: upper, lower: lower, lines: primaryLines, judgment: '');

    // 变卦
    final changedLines = List<int>.from(primaryLines);
    changedLines[moveIdx] = changedLines[moveIdx] == 1 ? 0 : 1;
    final changedUpperTri = _findTrigram(changedLines.sublist(3, 6));
    final changedLowerTri = _findTrigram(changedLines.sublist(0, 3));
    final changedHex = _hexRepo.findByLines(changedLines) ??
        FullHexagramInfo(index: 1, name: '${changedUpperTri.element}${changedLowerTri.element}卦', symbol: '',
            upper: changedUpperTri, lower: changedLowerTri, lines: changedLines, judgment: '');

    // 互卦（2-3-4爻为下卦，3-4-5爻为上卦）
    FullHexagramInfo? mutualHex;
    if (primaryLines.length == 6) {
      final mutualLower = [primaryLines[1], primaryLines[2], primaryLines[3]]; // lines 2,3,4
      final mutualUpper = [primaryLines[2], primaryLines[3], primaryLines[4]]; // lines 3,4,5
      final mutualLines = [...mutualLower, ...mutualUpper];
      final mutualUpperTri = _findTrigram(mutualUpper);
      final mutualLowerTri = _findTrigram(mutualLower);
      mutualHex = _hexRepo.findByLines(mutualLines) ??
          FullHexagramInfo(index: 1, name: '${mutualUpperTri.element}${mutualLowerTri.element}卦', symbol: '',
              upper: mutualUpperTri, lower: mutualLowerTri, lines: mutualLines, judgment: '');
    }

    // 爻辞
    final yaoData = _yaoRepo.findByHexagramAndLine(primaryHex.index, movingLine);
    final movingYao = YaoLineInfo(
      position: movingLine, stageName: ['初','二','三','四','五','上'][moveIdx],
      lineName: YaoLineInfo.buildLineName(position: movingLine, isYang: primaryLines[moveIdx] == 1),
      isYang: primaryLines[moveIdx] == 1, isChanging: true,
      text: yaoData?.text, meaning: yaoData?.meaning,
    );

    return MeihuaCastResult(
      question: question, castMethod: 'three_numbers',
      numbers: {'firstNumber': firstNumber, 'secondNumber': secondNumber, 'thirdNumber': thirdNumber},
      calculation: {'upperRemainder': upperRem, 'lowerRemainder': lowerRem, 'movingRemainder': moveRem},
      upperTrigramNumber: upperNum, lowerTrigramNumber: lowerNum, movingLine: movingLine,
      upperTrigram: upper, lowerTrigram: lower,
      primaryHexagram: primaryHex, movingYao: movingYao,
      changedHexagram: changedHex, mutualHexagram: mutualHex,
    );
  }

  TrigramInfo _findTrigram(List<int> lines) {
    for (final t in trigrams.values) {
      if (t.lines[0] == lines[0] && t.lines[1] == lines[1] && t.lines[2] == lines[2]) return t;
    }
    return trigrams[8]!;
  }

  /// 生成随机数字
  int randomNumber() => _random.nextInt(999) + 1;
}

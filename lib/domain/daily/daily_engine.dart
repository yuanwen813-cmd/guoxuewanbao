import 'dart:math';
import '../iching/iching_repository.dart';
import '../iching/takashima_models.dart';

/// 每日一卦起卦结果
class DailyHexagramResult {
  final String dateKey;
  final String dailySeed;
  final int upperTrigramNumber;
  final int lowerTrigramNumber;
  final int movingLine;
  final TrigramInfo upperTrigram;
  final TrigramInfo lowerTrigram;
  final FullHexagramInfo primaryHexagram;
  final YaoLineInfo movingYao;
  final FullHexagramInfo changedHexagram;

  const DailyHexagramResult({
    required this.dateKey, required this.dailySeed,
    required this.upperTrigramNumber, required this.lowerTrigramNumber,
    required this.movingLine,
    required this.upperTrigram, required this.lowerTrigram,
    required this.primaryHexagram, required this.movingYao,
    required this.changedHexagram,
  });

  Map<String, dynamic> toJson() => {
    'dateKey': dateKey, 'dailySeed': dailySeed,
    'upperTrigramNumber': upperTrigramNumber, 'lowerTrigramNumber': lowerTrigramNumber, 'movingLine': movingLine,
    'upperTrigram': {'name': upperTrigram.name, 'element': upperTrigram.element, 'lines': upperTrigram.lines},
    'lowerTrigram': {'name': lowerTrigram.name, 'element': lowerTrigram.element, 'lines': lowerTrigram.lines},
    'primaryHexagram': {'id': primaryHexagram.index, 'name': primaryHexagram.name, 'symbol': primaryHexagram.symbol, 'judgment': primaryHexagram.judgment, 'image': primaryHexagram.image},
    'movingYao': {'line': movingYao.position, 'lineName': movingYao.lineName, 'text': movingYao.text, 'meaning': movingYao.meaning},
    'changedHexagram': {'id': changedHexagram.index, 'name': changedHexagram.name, 'symbol': changedHexagram.symbol, 'judgment': changedHexagram.judgment, 'image': changedHexagram.image},
  };
}

/// 每日一卦引擎 — 基于 localUserId + dateKey 确定性起卦
class DailyHexagramEngine {
  final HexagramRepository _hexRepo;
  final YaoRepository _yaoRepo;

  DailyHexagramEngine({required HexagramRepository hexRepo, required YaoRepository yaoRepo})
      : _hexRepo = hexRepo, _yaoRepo = yaoRepo;

  /// 从 seed 生成确定性随机序列
  int _seedHash(String seed) {
    int hash = 0;
    for (int i = 0; i < seed.length; i++) {
      hash = ((hash << 5) - hash + seed.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash.abs();
  }

  /// 确定性取数：从 seed + index 生成 [1, max] 范围的数
  int _seededNumber(String seed, int index, int max) {
    final rng = Random(_seedHash('$seed#$index'));
    return rng.nextInt(max) + 1;
  }

  /// 每日起卦
  DailyHexagramResult cast({
    required String dailySeed,
    required String dateKey,
  }) {
    // 确定性取数
    final upperCount = _seededNumber(dailySeed, 1, 999);
    final lowerCount = _seededNumber(dailySeed, 2, 999);
    final moveCount = _seededNumber(dailySeed, 3, 999);

    final upperRem = upperCount % 8;
    final upperNum = upperRem == 0 ? 8 : upperRem;
    final upper = trigrams[upperNum]!;

    final lowerRem = lowerCount % 8;
    final lowerNum = lowerRem == 0 ? 8 : lowerRem;
    final lower = trigrams[lowerNum]!;

    final moveRem = moveCount % 6;
    final movingLine = moveRem == 0 ? 6 : moveRem;
    final moveIdx = movingLine - 1;

    final primaryLines = [...lower.lines, ...upper.lines];
    final primaryHex = _hexRepo.findByLines(primaryLines) ??
        FullHexagramInfo(index: 1, name: '${upper.element}${lower.element}卦', symbol: '', upper: upper, lower: lower, lines: primaryLines, judgment: '');

    final changedLines = List<int>.from(primaryLines);
    changedLines[moveIdx] = changedLines[moveIdx] == 1 ? 0 : 1;
    final changedHex = _hexRepo.findByLines(changedLines) ??
        FullHexagramInfo(index: 1, name: '变卦', symbol: '', upper: upper, lower: lower, lines: changedLines, judgment: '');

    final yaoData = _yaoRepo.findByHexagramAndLine(primaryHex.index, movingLine);
    final movingYao = YaoLineInfo(
      position: movingLine, stageName: ['初','二','三','四','五','上'][moveIdx],
      lineName: YaoLineInfo.buildLineName(position: movingLine, isYang: primaryLines[moveIdx] == 1),
      isYang: primaryLines[moveIdx] == 1, isChanging: true,
      text: yaoData?.text, meaning: yaoData?.meaning,
    );

    return DailyHexagramResult(
      dateKey: dateKey, dailySeed: dailySeed,
      upperTrigramNumber: upperNum, lowerTrigramNumber: lowerNum, movingLine: movingLine,
      upperTrigram: upper, lowerTrigram: lower,
      primaryHexagram: primaryHex, movingYao: movingYao, changedHexagram: changedHex,
    );
  }
}

/// 单次摇动结果
class TakashimaSegmentShakeResult {
  final int shakeIndex;   // 1,2,3
  final int leftCount;    // 左边线段数 (1~48)
  final int rightCount;   // 右边线段数 (49-leftCount)
  final String selectedSide; // '左' or '右'
  final int selectedCount;   // 选中组的数量
  final int divisor;      // 8 or 6
  final int remainder;    // 选中数量 % 除数
  final int mappedValue;  // 映射后的值 (remainder==0 ? divisor : remainder)
  final String purpose;   // 'upper_trigram' | 'lower_trigram' | 'moving_line'

  const TakashimaSegmentShakeResult({
    required this.shakeIndex,
    required this.leftCount,
    required this.rightCount,
    required this.selectedSide,
    required this.selectedCount,
    required this.divisor,
    required this.remainder,
    required this.mappedValue,
    required this.purpose,
  });

  Map<String, dynamic> toJson() => {
    'shakeIndex': shakeIndex, 'leftCount': leftCount, 'rightCount': rightCount,
    'selectedSide': selectedSide, 'selectedCount': selectedCount,
    'divisor': divisor, 'remainder': remainder, 'mappedValue': mappedValue,
    'purpose': purpose,
  };
}

/// 八卦信息
class TrigramInfo {
  final int number;    // 1-8
  final String name;   // 乾兑离震巽坎艮坤
  final String element;// 天地火雷风水山泽
  final List<int> lines; // 从下往上 [0/1, 0/1, 0/1]，0=阴 1=阳

  const TrigramInfo({
    required this.number, required this.name, required this.element,
    required this.lines,
  });

  /// 用于显示的三爻符号（下→上）
  String get symbol => lines.map((l) => l == 1 ? '⚊' : '⚋').join();
}

/// 六十四卦信息
class FullHexagramInfo {
  final int index;       // 1-64
  final String name;     // 卦名
  final String symbol;   // Unicode ䷀-䷿
  final TrigramInfo upper;
  final TrigramInfo lower;
  final List<int> lines; // 六爻 [初..上], 0=阴 1=阳
  final String judgment; // 卦辞
  final String? image;   // 象曰
  final String? meaning; // 卦义

  const FullHexagramInfo({
    required this.index, required this.name, required this.symbol,
    required this.upper, required this.lower, required this.lines,
    this.judgment = '', this.image, this.meaning,
  });
}

/// 起卦输入
class TakashimaCastInput {
  final String question;
  final int gender; // 0=男, 1=女
  final String castMethod;

  const TakashimaCastInput({
    this.question = '', this.gender = 0,
    this.castMethod = '49线段分策法',
  });
}

/// 完整起卦结果
class TakashimaCastResult {
  final String question;
  final int gender;
  final String castMethod;
  final List<TakashimaSegmentShakeResult> shakes;
  final int upperTrigramNumber;
  final int lowerTrigramNumber;
  final TrigramInfo upperTrigram;
  final TrigramInfo lowerTrigram;
  final int movingLine; // 1-6
  final FullHexagramInfo primaryHexagram;
  final FullHexagramInfo changedHexagram;
  final YaoLineInfo movingYao;
  final Map<String, double> interpretationWeights;
  final Map<String, dynamic>? validation;

  const TakashimaCastResult({
    required this.question, required this.gender, required this.castMethod,
    required this.shakes,
    required this.upperTrigramNumber, required this.lowerTrigramNumber,
    required this.upperTrigram, required this.lowerTrigram,
    required this.movingLine,
    required this.primaryHexagram, required this.changedHexagram,
    required this.movingYao,
    this.interpretationWeights = const {
      'movingYao': 0.51, 'primaryHexagram': 0.30, 'changedHexagram': 0.19,
    },
    this.validation,
  });

  Map<String, dynamic> toJson() => {
    'question': question, 'gender': gender == 0 ? '男' : '女',
    'castMethod': castMethod, 'shakes': shakes.map((s) => s.toJson()).toList(),
    'upperTrigram': upperTrigram.name, 'lowerTrigram': lowerTrigram.name,
    'primaryHexagram': primaryHexagram.name,
    'movingLine': movingLine, 'movingYao': movingYao.toJson(),
    'changedHexagram': changedHexagram.name,
    'interpretationWeights': interpretationWeights,
  };
}

/// 单爻信息
class YaoLineInfo {
  final int position;     // 1-6
  final String stageName; // 初/二/三/四/五/上
  final String lineName;  // 初九/九二/六三/上六 等完整爻名
  final bool isYang;
  final bool isChanging;
  final String? text;     // 爻辞
  final String? meaning;  // 爻义

  const YaoLineInfo({
    required this.position, required this.stageName,
    required this.lineName,
    required this.isYang, this.isChanging = false,
    this.text, this.meaning,
  });

  /// 生成完整爻名
  static String buildLineName({required int position, required bool isYang}) {
    final yinYang = isYang ? '九' : '六';
    if (position == 1) return '初$yinYang';
    if (position == 6) return '上$yinYang';
    return '$yinYang${['二','三','四','五'][position - 2]}';
  }

  String get symbol {
    if (isYang && isChanging) return '⚊○';
    if (isYang) return '⚊';
    if (isChanging) return '⚋×';
    return '⚋';
  }

  Map<String, dynamic> toJson() => {
    'position': position, 'stage': stageName, 'lineName': lineName,
    'isYang': isYang, 'isChanging': isChanging,
    'text': text, 'meaning': meaning,
  };
}

/// 六爻单爻
class YaoLine {
  final int position; // 1-6, 初爻=1, 上爻=6
  final bool isYang; // true=阳(⚊), false=阴(⚋)
  final bool isChanging; // true=动爻, false=静爻
  final String? text; // 爻辞
  final String? meaning; // 爻辞释义

  const YaoLine({
    required this.position,
    required this.isYang,
    this.isChanging = false,
    this.text,
    this.meaning,
  });

  /// 老阳/老阴 → 动爻
  int get value => isYang ? (isChanging ? 3 : 1) : (isChanging ? 0 : 2);

  String get symbol {
    if (isYang && isChanging) return '⚊○ 老阳';
    if (isYang && !isChanging) return '⚊ 少阳';
    if (!isYang && isChanging) return '⚋× 老阴';
    return '⚋ 少阴';
  }

  String get stageName => ['', '初', '二', '三', '四', '五', '上'][position];

  Map<String, dynamic> toJson() => {
        'position': position,
        'isYang': isYang,
        'isChanging': isChanging,
        'text': text,
        'meaning': meaning,
        'symbol': symbol,
      };

  factory YaoLine.fromJson(Map<String, dynamic> json) => YaoLine(
        position: json['position'] as int,
        isYang: json['isYang'] as bool? ?? true,
        isChanging: json['isChanging'] as bool? ?? false,
        text: json['text'] as String?,
        meaning: json['meaning'] as String?,
      );
}

/// 六十四卦
class Hexagram {
  final int index; // 1-64
  final String name; // 卦名
  final String binary; // 6位二进制 1=阳0=阴, 从下往上
  final String upper; // 上卦
  final String lower; // 下卦
  final String judgment; // 卦辞
  final String? tuan; // 彖传
  final String? image; // 象传
  final List<HexagramLine> lines; // 六爻

  const Hexagram({
    required this.index,
    required this.name,
    required this.binary,
    required this.upper,
    required this.lower,
    this.judgment = '',
    this.tuan,
    this.image,
    this.lines = const [],
  });

  /// 上卦三爻的阴阳值
  String get upperBinary => binary.substring(0, 3);

  /// 下卦三爻的阴阳值
  String get lowerBinary => binary.substring(3);

  /// 组成六爻YaoLine（从下往上：初爻→上爻）
  List<YaoLine> buildLines(List<bool> changingPositions) {
    return List.generate(6, (i) {
      final isYang = binary[5 - i] == '1'; // binary[0]=上爻爻位, binary[5]=初爻爻位
      return YaoLine(
        position: i + 1,
        isYang: isYang,
        isChanging: changingPositions.length > i && changingPositions[i],
        text: lines.length > i ? lines[i].text : null,
        meaning: lines.length > i ? lines[i].meaning : null,
      );
    });
  }

  /// 由六爻阴阳值查找卦名（下卦在前，如111000=地天泰）
  static String identify(List<bool> yaoYang) {
    final bin = yaoYang.reversed.map((y) => y ? '1' : '0').join();
    return _hexagramMap[bin] ?? '未知卦';
  }

  factory Hexagram.fromJson(Map<String, dynamic> json) => Hexagram(
        index: json['index'] as int,
        name: json['name'] as String,
        binary: json['binary'] as String? ?? '111111',
        upper: json['upper'] as String? ?? '',
        lower: json['lower'] as String? ?? '',
        judgment: json['judgment'] as String? ?? '',
        tuan: json['tuan'] as String?,
        image: json['image'] as String?,
        lines: (json['lines'] as List?)
                ?.map((e) => HexagramLine.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'index': index,
        'name': name,
        'binary': binary,
        'upper': upper,
        'lower': lower,
        'judgment': judgment,
        'image': image,
        'lines': lines.map((l) => l.toJson()).toList(),
      };
}

class HexagramLine {
  final int pos;
  final String text;
  final String? meaning;

  const HexagramLine({required this.pos, required this.text, this.meaning});

  factory HexagramLine.fromJson(Map<String, dynamic> json) => HexagramLine(
        pos: json['pos'] as int,
        text: json['text'] as String? ?? '',
        meaning: json['meaning'] as String?,
      );

  Map<String, dynamic> toJson() =>
      {'pos': pos, 'text': text, 'meaning': meaning};
}

/// 六十四卦快速索引表。
///
/// 键由六爻从上到下组成，上卦在前、下卦在后；例如 `010001` 为水雷屯。
/// `Hexagram.identify` 接收的爻序是初爻到上爻，因此会在查表前反转。
/// 此表必须保持 64 个唯一键，避免同一卦码被后续条目静默覆盖。
const _hexagramMap = <String, String>{
  '111111': '乾为天',
  '000000': '坤为地',
  '010001': '水雷屯',
  '100010': '山水蒙',
  '010111': '水天需',
  '111010': '天水讼',
  '000010': '地水师',
  '010000': '水地比',
  '110111': '风天小畜',
  '111011': '天泽履',
  '000111': '地天泰',
  '111000': '天地否',
  '111101': '天火同人',
  '101111': '火天大有',
  '000100': '地山谦',
  '001000': '雷地豫',
  '011001': '泽雷随',
  '100110': '山风蛊',
  '000011': '地泽临',
  '110000': '风地观',
  '101001': '火雷噬嗑',
  '100101': '山火贲',
  '100000': '山地剥',
  '000001': '地雷复',
  '111001': '天雷无妄',
  '100111': '山天大畜',
  '100001': '山雷颐',
  '011110': '泽风大过',
  '010010': '坎为水',
  '101101': '离为火',
  '011100': '泽山咸',
  '001110': '雷风恒',
  '111100': '天山遁',
  '001111': '雷天大壮',
  '101000': '火地晋',
  '000101': '地火明夷',
  '110101': '风火家人',
  '101011': '火泽睽',
  '010100': '水山蹇',
  '001010': '雷水解',
  '100011': '山泽损',
  '110001': '风雷益',
  '011111': '泽天夬',
  '111110': '天风姤',
  '011000': '泽地萃',
  '000110': '地风升',
  '011010': '泽水困',
  '010110': '水风井',
  '011101': '泽火革',
  '101110': '火风鼎',
  '001001': '震为雷',
  '100100': '艮为山',
  '110100': '风山渐',
  '001011': '雷泽归妹',
  '001101': '雷火丰',
  '101100': '火山旅',
  '110110': '巽为风',
  '011011': '兑为泽',
  '110010': '风水涣',
  '010011': '水泽节',
  '110011': '风泽中孚',
  '001100': '雷山小过',
  '010101': '水火既济',
  '101010': '火水未济',
};

/// 周易本经 — 数据模型
class ZhouyiHexagram {
  final int id;
  final int number;
  final String name;
  final String symbol;
  final String upperTrigram;
  final String lowerTrigram;
  final String judgment;
  final String image;
  final String plainText;
  final List<ZhouyiYaoLine> lines;

  const ZhouyiHexagram({
    required this.id,
    required this.number,
    required this.name,
    required this.symbol,
    required this.upperTrigram,
    required this.lowerTrigram,
    required this.judgment,
    required this.image,
    required this.plainText,
    required this.lines,
  });

  factory ZhouyiHexagram.fromJson(Map<String, dynamic> json) {
    return ZhouyiHexagram(
      id: (json['id'] as num).toInt(),
      number: (json['number'] as num).toInt(),
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      upperTrigram: json['upperTrigram'] as String? ?? '',
      lowerTrigram: json['lowerTrigram'] as String? ?? '',
      judgment: _readString(json, ['judgment', 'guaCi', 'hexagramText']),
      image: _readString(json, ['image', 'xiangCi', 'imageText']),
      plainText: _readString(json, ['plainText', 'vernacular', 'explanation']),
      lines: (json['lines'] as List?)
              ?.map((e) => ZhouyiYaoLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}

class ZhouyiYaoLine {
  final int line;
  final String lineName;
  final String text;
  final String meaning;

  const ZhouyiYaoLine({
    required this.line,
    required this.lineName,
    required this.text,
    required this.meaning,
  });

  factory ZhouyiYaoLine.fromJson(Map<String, dynamic> json) {
    return ZhouyiYaoLine(
      line: (json['line'] as num).toInt(),
      lineName: _readString(json, ['lineName', 'name']),
      text: _readString(json, ['text', 'yaoCi', 'lineText']),
      meaning: _readString(json, ['meaning', 'plainText', 'vernacular']),
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  /// 避免页面出现 null
  String get displayText => text.isNotEmpty ? text : '（未收录）';
  String get displayMeaning => meaning.isNotEmpty ? meaning : '（缺解释）';
}

/// 小六壬六宫数据
class SmallLiurenPalace {
  final int order; // 0-5
  final String name;
  final String nature;
  final List<String> keywords;
  final String generalMeaning;
  final String advice;
  final String caution;

  const SmallLiurenPalace({
    required this.order, required this.name, required this.nature,
    required this.keywords, required this.generalMeaning,
    required this.advice, required this.caution,
  });

  Map<String, dynamic> toJson() => {
    'order': order, 'name': name, 'nature': nature, 'keywords': keywords,
    'generalMeaning': generalMeaning, 'advice': advice, 'caution': caution,
  };
}

/// 六宫数据
const sixPalaces = [
  SmallLiurenPalace(order:0, name:'大安', nature:'偏吉，安稳，平顺，宜守成', keywords:['安稳','平和','守正','稳定','等待'], generalMeaning:'事情整体较稳，不宜急躁，适合按原计划推进。', advice:'守正不妄动，稳中求进。', caution:'忌急进，忌贪快。'),
  SmallLiurenPalace(order:1, name:'留连', nature:'偏滞，拖延，反复，牵连', keywords:['迟滞','反复','等待','纠缠','未决'], generalMeaning:'事情容易拖延，短期难有明确结果。', advice:'耐心等待，理清关系，避免反复消耗。', caution:'忌催逼，忌纠缠不清。'),
  SmallLiurenPalace(order:2, name:'速喜', nature:'偏吉，迅速，有消息，有喜讯', keywords:['消息','喜事','快速','顺利','回应'], generalMeaning:'事情有较快回应，适合主动沟通和推动。', advice:'把握机会，及时行动。', caution:'忌得意过早，仍需确认细节。'),
  SmallLiurenPalace(order:3, name:'赤口', nature:'偏凶，口舌，争执，冲突', keywords:['争执','误会','口舌','冲突','损伤'], generalMeaning:'事情中容易出现言语冲突或误解。', advice:'少说多听，避免硬碰硬。', caution:'忌争辩，忌冲动表达。'),
  SmallLiurenPalace(order:4, name:'小吉', nature:'小吉，渐顺，小成，有帮助', keywords:['小顺','贵人','缓和','进展','可成'], generalMeaning:'事情有小的顺利和助力，但不是大成。', advice:'顺势推进，积小胜为大胜。', caution:'忌贪大，忌过度乐观。'),
  SmallLiurenPalace(order:5, name:'空亡', nature:'落空，虚耗，不实，未定', keywords:['落空','虚耗','空转','无果','不实'], generalMeaning:'事情暂时虚而不实，结果不明，容易白费力。', advice:'先核实信息，再决定是否投入。', caution:'忌冒进，忌重投入，忌轻信承诺。'),
];

/// 时辰映射
const hourBranches = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];

enum SmallLiurenMode { standard_time, thought_number }

/// 小六壬起课结果
class SmallLiurenResult {
  final SmallLiurenMode mode;
  final String question;
  final int lunarMonth;
  final int lunarDay;
  final String hourBranch;
  final int hourIndex;
  final int thoughtNumber;
  final int palaceIndex;
  final SmallLiurenPalace finalPalace;

  const SmallLiurenResult({
    required this.mode, required this.question,
    required this.lunarMonth, required this.lunarDay,
    required this.hourBranch, required this.hourIndex,
    this.thoughtNumber = 0,
    required this.palaceIndex, required this.finalPalace,
  });

  String get modeLabel => mode == SmallLiurenMode.thought_number ? '一念取数' : '月日时起课';
  String get formulaUsed => mode == SmallLiurenMode.thought_number
      ? '($lunarMonth-1 + $lunarDay-1 + $hourIndex-1 + $thoughtNumber-1) % 6 = $palaceIndex'
      : '($lunarMonth-1 + $lunarDay-1 + $hourIndex-1) % 6 = $palaceIndex';

  Map<String, dynamic> toJson() => {
    'featureId': 'small_liuren', 'question': question,
    'mode': mode.name, 'thoughtNumber': thoughtNumber,
    'lunarMonth': lunarMonth, 'lunarDay': lunarDay,
    'hourBranch': hourBranch, 'hourIndex': hourIndex,
    'palaceIndex': palaceIndex, 'finalPalace': finalPalace.toJson(),
    'formula': formulaUsed,
  };
}

/// 小六壬起课引擎
class SmallLiurenEngine {
  const SmallLiurenEngine();
  /// 计算落宫
  SmallLiurenResult calculate({
    required String question,
    required int lunarMonth,
    required int lunarDay,
    required int hourIndex,
    required String hourBranch,
    SmallLiurenMode mode = SmallLiurenMode.thought_number,
    int thoughtNumber = 0,
  }) {
    final offset = mode == SmallLiurenMode.thought_number ? (thoughtNumber - 1) : 0;
    final palaceIndex = (lunarMonth - 1 + lunarDay - 1 + hourIndex - 1 + offset) % 6;
    return SmallLiurenResult(
      mode: mode, question: question,
      lunarMonth: lunarMonth, lunarDay: lunarDay,
      hourBranch: hourBranch, hourIndex: hourIndex,
      thoughtNumber: thoughtNumber,
      palaceIndex: palaceIndex, finalPalace: sixPalaces[palaceIndex],
    );
  }

  /// 从当前时间获取时辰
  static int hourToIndex(int hour) {
    if (hour == 23 || hour == 0) return 1;
    return (hour + 1) ~/ 2; // 1-2→1(丑), 3-4→2(寅), ... 21-22→11(亥)
  }

  static String indexToBranch(int idx) => hourBranches[idx - 1];

  static String? validate(int month, int day, int hourIdx) {
    if (month < 1 || month > 12) return '农历月必须在 1-12 之间';
    if (day < 1 || day > 30) return '农历日必须在 1-30 之间';
    if (hourIdx < 1 || hourIdx > 12) return '时辰不合法';
    return null;
  }
}

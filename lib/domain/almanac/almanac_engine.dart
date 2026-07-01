import 'dart:math';

/// 黄历每日数据
class AlmanacDay {
  final String dateKey;        // yyyyMMdd
  final String gregorianDate;  // "2026年6月22日"
  final String weekday;        // "星期一"
  final String lunarDate;      // 农历 displayText
  final Map<String, dynamic>? lunarData; // v0.17: 结构化农历数据快照
  final String yearGanzhi;
  final String monthGanzhi;
  final String dayGanzhi;
  final String zodiac;
  final Map<String, dynamic>? zodiacData; // v0.19: 结构化生肖数据快照
  final String solarTerm;
  final List<String> suitable;
  final List<String> avoid;
  final String clashZodiac;
  final String shaDirection;
  final String dailySummary;
  final Map<String, String> lifeAdvice;
  final String source;        // "local_rule_beta"
  final String dataQuality;   // "beta"

  const AlmanacDay({
    required this.dateKey, required this.gregorianDate, required this.weekday,
    this.lunarDate = '农历信息暂未启用', this.lunarData,
    this.yearGanzhi = '暂未启用', this.monthGanzhi = '暂未启用',
    this.dayGanzhi = '暂未启用', this.zodiac = '', this.zodiacData,
    this.solarTerm = '',
    required this.suitable, required this.avoid,
    this.clashZodiac = '', this.shaDirection = '',
    this.dailySummary = '', required this.lifeAdvice,
    this.source = 'local_rule_beta', this.dataQuality = 'beta',
  });

  Map<String, dynamic> toJson() => {
    'dateKey': dateKey, 'gregorianDate': gregorianDate, 'weekday': weekday,
    'lunarDate': lunarDate,
    if (lunarData != null) 'lunarData': lunarData,
    'yearGanzhi': yearGanzhi, 'monthGanzhi': monthGanzhi,
    'dayGanzhi': dayGanzhi, 'zodiac': zodiac, 'solarTerm': solarTerm,
    if (zodiacData != null) 'zodiacData': zodiacData,
    'suitable': suitable, 'avoid': avoid,
    'clashZodiac': clashZodiac, 'shaDirection': shaDirection,
    'dailySummary': dailySummary, 'lifeAdvice': lifeAdvice,
    'source': source, 'dataQuality': dataQuality,
  };
}

/// 黄历引擎 v0.1 — 本地规则 Beta
class AlmanacEngine {
  const AlmanacEngine();
  static const suitablePool = ['整理','学习','会友','出行','洽谈','清扫','纳财','祈福','修整','计划','签约','沟通'];
  static const avoidPool = ['争执','冒进','冲动投资','重大决策','远行','动土','熬夜','过度消费','急躁表达','轻信承诺'];
  static const _weekdays = ['星期一','星期二','星期三','星期四','星期五','星期六','星期日'];
  static const _zodiacs = ['鼠','牛','虎','兔','龙','蛇','马','羊','猴','鸡','狗','猪'];
  static const _summaries = [
    '宜稳中推进，适合整理、学习、沟通；重要决策宜多核实。',
    '宜循序渐进，适合维护现有事务，不宜贸然开启新项。',
    '宜灵活应变，适合短期安排和聚会交流，避免固执己见。',
    '宜自我沉淀，适合独处、思考和内省，减少外部干扰。',
    '宜积极沟通，适合联络人脉和推进合作，多听少说更为妥帖。',
    '宜查漏补缺，适合复盘、修缮和确认细节，不宜急躁冒进。',
    '宜顺势而为，适合把握已有机会，保持平常心对待变数。',
  ];

  /// 从 dateKey 确定性选 N 项（从池中取，同一天结果固定）
  List<String> _pickFromPool(String dateKey, int index, List<String> pool, int count) {
    final seed = _hash('$dateKey#$index');
    final rng = Random(seed);
    final shuffled = List<String>.from(pool)..shuffle(rng);
    return shuffled.take(count).toList();
  }

  int _hash(String s) {
    int h = 0;
    for (int i = 0; i < s.length; i++) { h = ((h << 5) - h + s.codeUnitAt(i)) & 0x7FFFFFFF; }
    return h.abs();
  }

  /// 获取指定日期的黄历
  /// [lunarDateDisplay] 可选：来自 CalendarProvider 的农历 displayText（v0.17+）
  /// [lunarDataSnapshot] 可选：来自 CalendarProvider 的结构化农历数据快照（v0.17+）
  /// [zodiacDisplay] 可选：来自 CalendarProvider 的生肖名（v0.19+）
  /// [zodiacDataSnapshot] 可选：来自 CalendarProvider 的结构化生肖数据快照（v0.19+）
  AlmanacDay getDay(DateTime date, {
    String? lunarDateDisplay,
    Map<String, dynamic>? lunarDataSnapshot,
    String? zodiacDisplay,
    Map<String, dynamic>? zodiacDataSnapshot,
  }) {
    final dk = '${date.year}${date.month.toString().padLeft(2,'0')}${date.day.toString().padLeft(2,'0')}';
    final greg = '${date.year}年${date.month}月${date.day}日';
    final wd = _weekdays[date.weekday - 1];
    final suitable = _pickFromPool(dk, 1, suitablePool, 5);
    final avoid = _pickFromPool(dk, 2, avoidPool, 4);
    final summary = _summaries[_hash('$dk#summary') % _summaries.length];

    return AlmanacDay(
      dateKey: dk, gregorianDate: greg, weekday: wd,
      lunarDate: lunarDateDisplay ?? '农历信息暂未启用',
      lunarData: lunarDataSnapshot,
      zodiac: zodiacDisplay ?? '',
      zodiacData: zodiacDataSnapshot,
      suitable: suitable, avoid: avoid, dailySummary: summary,
      lifeAdvice: {
        'work': '适合整理计划，推进已确定事项。',
        'relationship': '沟通宜留余地，少争对错。',
        'wealth': '不宜冲动消费或冒险投资。',
        'health': '注意作息，避免过度劳累。',
      },
    );
  }

  /// 获取今天的黄历
  AlmanacDay getToday() => getDay(DateTime.now());
}

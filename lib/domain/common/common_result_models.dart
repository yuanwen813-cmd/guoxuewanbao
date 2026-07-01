/// 通用占卜结果模型 —— 所有国学功能归一化到此结构

class CommonDivinationResult {
  final String featureId;
  final String featureName;
  final String categoryId;
  final String? userQuestion;
  final DateTime createdAt;
  final String summary;
  final DivinationType type;

  // 卦象类
  final HexagramCard? primaryHexagram;
  final MovingYaoCard? movingYao;
  final HexagramCard? mutualHexagram;
  final HexagramCard? changedHexagram;

  // 命盘类（预留）
  final List<ChartSection>? chartSections;

  // 文本解读类
  final String? xiangDuan;
  final String? movingYaoAnalysis;
  final String? primaryHexagramAnalysis;
  final String? mutualHexagramAnalysis;
  final String? changedHexagramAnalysis;
  final String? classical;
  final String? vernacular;
  final String? timing;
  final String? advice;
  final String? riskNote;
  final String? finalVerdict;
  final List<String>? tags;

  // 风险标记
  final bool isFinancial;
  final bool isMedical;
  final bool isLegal;

  // 原始快照（用于历史记录和分享）
  final Map<String, dynamic>? rawSnapshot;

  const CommonDivinationResult({
    required this.featureId,
    required this.featureName,
    required this.categoryId,
    this.userQuestion,
    required this.createdAt,
    required this.summary,
    this.type = DivinationType.generic,
    this.primaryHexagram,
    this.movingYao,
    this.mutualHexagram,
    this.changedHexagram,
    this.chartSections,
    this.xiangDuan,
    this.movingYaoAnalysis,
    this.primaryHexagramAnalysis,
    this.mutualHexagramAnalysis,
    this.changedHexagramAnalysis,
    this.classical,
    this.vernacular,
    this.timing,
    this.advice,
    this.riskNote,
    this.finalVerdict,
    this.tags,
    this.isFinancial = false,
    this.isMedical = false,
    this.isLegal = false,
    this.rawSnapshot,
  });

  Map<String, dynamic> toJson() => {
    'featureId': featureId, 'featureName': featureName, 'categoryId': categoryId,
    'userQuestion': userQuestion, 'createdAt': createdAt.toIso8601String(), 'summary': summary,
    'type': type.name,
    if (primaryHexagram != null) 'primaryHexagram': primaryHexagram!.toJson(),
    if (movingYao != null) 'movingYao': movingYao!.toJson(),
      if (mutualHexagram != null) 'mutualHexagram': mutualHexagram!.toJson(),
    if (changedHexagram != null) 'changedHexagram': changedHexagram!.toJson(),
    'interpretation': {
      if (xiangDuan != null) 'xiangDuan': xiangDuan,
      if (movingYaoAnalysis != null) 'movingYaoAnalysis': movingYaoAnalysis,
      if (primaryHexagramAnalysis != null) 'primaryHexagramAnalysis': primaryHexagramAnalysis,
      if (mutualHexagramAnalysis != null) 'mutualHexagramAnalysis': mutualHexagramAnalysis,
      if (changedHexagramAnalysis != null) 'changedHexagramAnalysis': changedHexagramAnalysis,
      if (classical != null) 'classical': classical,
      if (vernacular != null) 'vernacular': vernacular,
      if (timing != null) 'timing': timing,
      if (advice != null) 'advice': advice,
      if (riskNote != null) 'riskNote': riskNote,
      if (finalVerdict != null) 'finalVerdict': finalVerdict,
      if (tags != null) 'tags': tags,
    },
    'flags': {'isFinancial': isFinancial, 'isMedical': isMedical, 'isLegal': isLegal},
  };

  factory CommonDivinationResult.fromJson(Map<String, dynamic> j) {
    final interp = j['interpretation'] as Map<String, dynamic>? ?? {};
    final flags = j['flags'] as Map<String, dynamic>? ?? {};
    return CommonDivinationResult(
      featureId: j['featureId'] as String, featureName: j['featureName'] as String,
      categoryId: j['categoryId'] as String, userQuestion: j['userQuestion'] as String?,
      createdAt: DateTime.parse(j['createdAt'] as String), summary: j['summary'] as String? ?? '',
      type: DivinationType.values.firstWhere((t)=>t.name==(j['type']as String?),orElse:()=>DivinationType.generic),
      primaryHexagram: j['primaryHexagram']!=null?HexagramCard.fromJson(j['primaryHexagram'] as Map<String,dynamic>):null,
      movingYao: j['movingYao']!=null?MovingYaoCard.fromJson(j['movingYao'] as Map<String,dynamic>):null,
      mutualHexagram: j['mutualHexagram']!=null?HexagramCard.fromJson(j['mutualHexagram'] as Map<String,dynamic>):null,
      changedHexagram: j['changedHexagram']!=null?HexagramCard.fromJson(j['changedHexagram'] as Map<String,dynamic>):null,
      xiangDuan: interp['xiangDuan'] as String?, movingYaoAnalysis: interp['movingYaoAnalysis'] as String?,
      primaryHexagramAnalysis: interp['primaryHexagramAnalysis'] as String?,
      mutualHexagramAnalysis: interp['mutualHexagramAnalysis'] as String?,
      changedHexagramAnalysis: interp['changedHexagramAnalysis'] as String?,
      classical: interp['classical'] as String?, vernacular: interp['vernacular'] as String?,
      timing: interp['timing'] as String?, advice: interp['advice'] as String?,
      riskNote: interp['riskNote'] as String?, finalVerdict: interp['finalVerdict'] as String?,
      tags: (interp['tags'] as List?)?.cast<String>(),
      isFinancial: flags['isFinancial'] as bool? ?? false,
      isMedical: flags['isMedical'] as bool? ?? false,
      isLegal: flags['isLegal'] as bool? ?? false,
    );
  }
}

enum DivinationType { generic, hexagram, bazi_chart, almanac, lot_drawing, dream, reference }

class HexagramCard {
  final int index;
  final String name;
  final String symbol;
  final String? upperTrigram;
  final String? lowerTrigram;
  final String? judgment;
  final String? image;
  const HexagramCard({required this.index, required this.name, required this.symbol, this.upperTrigram, this.lowerTrigram, this.judgment, this.image});
  Map<String, dynamic> toJson() => {'index':index,'name':name,'symbol':symbol,'upperTrigram':upperTrigram,'lowerTrigram':lowerTrigram,'judgment':judgment,'image':image};
  factory HexagramCard.fromJson(Map<String, dynamic> j) => HexagramCard(index:j['index']as int,name:j['name']as String,symbol:j['symbol']as String? ?? '',upperTrigram:j['upperTrigram']as String?,lowerTrigram:j['lowerTrigram']as String?,judgment:j['judgment']as String?,image:j['image']as String?);
}

class MovingYaoCard {
  final int line;
  final String lineName;
  final String? text;
  final String? meaning;
  final bool isChanging;
  const MovingYaoCard({required this.line, required this.lineName, this.text, this.meaning, this.isChanging=true});
  Map<String, dynamic> toJson() => {'line':line,'lineName':lineName,'text':text,'meaning':meaning,'isChanging':isChanging};
  factory MovingYaoCard.fromJson(Map<String, dynamic> j) => MovingYaoCard(line:j['line']as int,lineName:j['lineName']as String,text:j['text']as String?,meaning:j['meaning']as String?,isChanging:j['isChanging']as bool? ?? true);
}

class ChartSection {
  final String title;
  final List<MapEntry<String, String>> rows;
  const ChartSection({required this.title, required this.rows});
}

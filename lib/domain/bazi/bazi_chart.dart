import 'pillar.dart';
import 'ten_gods.dart';

/// 八字排盘结果
class BaziChart {
  final Pillar yearPillar;
  final Pillar monthPillar;
  final Pillar dayPillar;
  final Pillar hourPillar;

  /// 日主十神关系 (天干 × 天干 → 十神)
  final List<TenGod> dayMasterRelations;

  const BaziChart({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.hourPillar,
    this.dayMasterRelations = const [],
  });

  /// 日主天干
  String get dayMaster => dayPillar.tianGan.chinese;

  List<Pillar> get pillars => [yearPillar, monthPillar, dayPillar, hourPillar];

  Map<String, dynamic> toJson() => {
    'method': 'bazi',
    'yearPillar': yearPillar.ganzhi.chineseName,
    'monthPillar': monthPillar.ganzhi.chineseName,
    'dayPillar': dayPillar.ganzhi.chineseName,
    'hourPillar': hourPillar.ganzhi.chineseName,
    'dayMaster': dayMaster,
    'pillars': pillars.map((p) => {
      'name': p.name,
      'ganzhi': p.ganzhi.chineseName,
      'tianGan': p.tianGan.chinese,
      'diZhi': p.diZhi.chinese,
      'wuxing': p.wuxing.chinese,
    }).toList(),
  };
}

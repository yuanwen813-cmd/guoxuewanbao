import '../calendar/ganzhi.dart';
import '../calendar/lunar_date.dart';

/// 宜忌项
class YiJi {
  final List<String> yi; // 宜
  final List<String> ji; // 忌

  const YiJi({this.yi = const [], this.ji = const []});
}

/// 神煞
class ShenSha {
  final List<String> auspicious; // 吉神
  final List<String> inauspicious; // 凶煞

  const ShenSha({this.auspicious = const [], this.inauspicious = const []});
}

/// 黄历每日数据
class AlmanacDay {
  final LunarDate lunarDate;
  final GanZhi ganzhi;
  final String solarTerm; // 当日节气，无则为空
  final YiJi yiJi;
  final ShenSha shenSha;
  final String starGod; // 二十八宿
  final String fiveElementDay; // 五行日
  final String pengZu; // 彭祖百忌
  final String chongSha; // 冲煞

  const AlmanacDay({
    required this.lunarDate,
    required this.ganzhi,
    this.solarTerm = '',
    this.yiJi = const YiJi(),
    this.shenSha = const ShenSha(),
    this.starGod = '',
    this.fiveElementDay = '',
    this.pengZu = '',
    this.chongSha = '',
  });

  Map<String, dynamic> toJson() => {
    'lunar': {
      'year': lunarDate.year,
      'month': lunarDate.month,
      'day': lunarDate.day,
      'isLeapMonth': lunarDate.isLeapMonth,
    },
    'ganzhi': ganzhi.chineseName,
    'solarTerm': solarTerm,
    'yi': yiJi.yi,
    'ji': yiJi.ji,
    'starGod': starGod,
    'fiveElementDay': fiveElementDay,
    'pengZu': pengZu,
    'chongSha': chongSha,
  };
}

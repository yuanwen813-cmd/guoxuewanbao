/// 天干
enum TianGan {
  jia(0, '甲', '木', '阳'),
  yi(1, '乙', '木', '阴'),
  bing(2, '丙', '火', '阳'),
  ding(3, '丁', '火', '阴'),
  wu(4, '戊', '土', '阳'),
  ji(5, '己', '土', '阴'),
  geng(6, '庚', '金', '阳'),
  xin(7, '辛', '金', '阴'),
  ren(8, '壬', '水', '阳'),
  gui(9, '癸', '水', '阴');

  final int order;
  final String chinese;
  final String wuxing;
  final String yinYang;

  const TianGan(this.order, this.chinese, this.wuxing, this.yinYang);

  static TianGan fromOrder(int i) => TianGan.values[i % 10];
}

/// 地支
enum DiZhi {
  zi(0, '子', '水', '阳'),
  chou(1, '丑', '土', '阴'),
  yin(2, '寅', '木', '阳'),
  mao(3, '卯', '木', '阴'),
  chen(4, '辰', '土', '阳'),
  si(5, '巳', '火', '阴'),
  wu(6, '午', '火', '阳'),
  wei(7, '未', '土', '阴'),
  shen(8, '申', '金', '阳'),
  you(9, '酉', '金', '阴'),
  xu(10, '戌', '土', '阳'),
  hai(11, '亥', '水', '阴');

  final int order;
  final String chinese;
  final String wuxing;
  final String yinYang;

  const DiZhi(this.order, this.chinese, this.wuxing, this.yinYang);

  static DiZhi fromOrder(int i) => DiZhi.values[i % 12];

  /// 时辰对应表：子时 23-1、丑时 1-3...亥时 21-23
  static DiZhi fromHour(int hour) {
    const mapping = [
      0,
      1,
      1,
      2,
      2,
      3,
      3,
      4,
      4,
      5,
      5,
      6,
      6,
      7,
      7,
      8,
      8,
      9,
      9,
      10,
      10,
      11,
      11,
      0,
    ];
    return DiZhi.values[mapping[hour % 24]];
  }
}

/// 干支组合
class GanZhi {
  final TianGan tianGan;
  final DiZhi diZhi;

  const GanZhi(this.tianGan, this.diZhi);

  String get chineseName => '${tianGan.chinese}${diZhi.chinese}';

  /// 六十甲子序号 (0-59): 甲子=0, 乙丑=1, ..., 癸亥=59
  int get cycleIndex => ((tianGan.order * 6 - diZhi.order * 5) % 60 + 60) % 60;

  @override
  String toString() => chineseName;
}

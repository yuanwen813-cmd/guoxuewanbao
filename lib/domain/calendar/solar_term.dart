/// 二十四节气
enum SolarTerm {
  liChun(0, '立春'),
  yuShui(1, '雨水'),
  jingZhe(2, '惊蛰'),
  chunFen(3, '春分'),
  qingMing(4, '清明'),
  guYu(5, '谷雨'),
  liXia(6, '立夏'),
  xiaoMan(7, '小满'),
  mangZhong(8, '芒种'),
  xiaZhi(9, '夏至'),
  xiaoShu(10, '小暑'),
  daShu(11, '大暑'),
  liQiu(12, '立秋'),
  chuShu(13, '处暑'),
  baiLu(14, '白露'),
  qiuFen(15, '秋分'),
  hanLu(16, '寒露'),
  shuangJiang(17, '霜降'),
  liDong(18, '立冬'),
  xiaoXue(19, '小雪'),
  daXue(20, '大雪'),
  dongZhi(21, '冬至'),
  xiaoHan(22, '小寒'),
  daHan(23, '大寒');

  final int order;
  final String chinese;

  const SolarTerm(this.order, this.chinese);

  /// 根据公历日期粗略推算当前节气（简化版）
  /// 实际项目中应使用查表法
  static SolarTerm approximate(int month, int day) {
    // 简化：每月两个节气，约在 4-8 日和 19-23 日
    const termDays = [
      5, 19, //  1月: 小寒, 大寒
      4, 19, //  2月: 立春, 雨水
      6, 21, //  3月: 惊蛰, 春分
      5, 20, //  4月: 清明, 谷雨
      6, 21, //  5月: 立夏, 小满
      6, 22, //  6月: 芒种, 夏至
      7, 23, //  7月: 小暑, 大暑
      8, 23, //  8月: 立秋, 处暑
      8, 23, //  9月: 白露, 秋分
      8, 24, // 10月: 寒露, 霜降
      8, 22, // 11月: 立冬, 小雪
      7, 22, // 12月: 大雪, 冬至
    ];

    final earlyDay = termDays[(month - 1) * 2];
    final lateDay = termDays[(month - 1) * 2 + 1];

    if (day < earlyDay) return SolarTerm.values[(month - 1) * 2 % 24];
    if (day < lateDay) return SolarTerm.values[(month - 1) * 2];
    return SolarTerm.values[((month - 1) * 2 + 1) % 24];
  }
}

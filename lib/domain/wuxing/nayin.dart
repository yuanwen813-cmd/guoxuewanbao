import '../calendar/ganzhi.dart';
import 'wuxing.dart';

/// 六十甲子纳音五行表
class NaYin {
  NaYin._();

  static const Map<int, WuXing> _nayinTable = {
    0: WuXing.metal, 1: WuXing.metal,   // 甲子 乙丑 → 海中金
    2: WuXing.fire,  3: WuXing.fire,    // 丙寅 丁卯 → 炉中火
    4: WuXing.wood,  5: WuXing.wood,    // 戊辰 己巳 → 大林木
    6: WuXing.earth, 7: WuXing.earth,   // 庚午 辛未 → 路旁土
    8: WuXing.metal, 9: WuXing.metal,   // 壬申 癸酉 → 剑锋金
    10: WuXing.fire, 11: WuXing.fire,   // 甲戌 乙亥 → 山头火
    12: WuXing.water, 13: WuXing.water, // 丙子 丁丑 → 涧下水
    14: WuXing.earth, 15: WuXing.earth, // 戊寅 己卯 → 城头土
    16: WuXing.wood, 17: WuXing.wood,   // 庚辰 辛巳 → 白蜡金
    18: WuXing.wood, 19: WuXing.wood,   // 壬午 癸未 → 杨柳木
    20: WuXing.water, 21: WuXing.water, // 甲申 乙酉 → 泉中水
    22: WuXing.earth, 23: WuXing.earth, // 丙戌 丁亥 → 屋上土
    24: WuXing.fire, 25: WuXing.fire,   // 戊子 己丑 → 霹雳火
    26: WuXing.wood, 27: WuXing.wood,   // 庚寅 辛卯 → 松柏木
    28: WuXing.water, 29: WuXing.water, // 壬辰 癸巳 → 长流水
    30: WuXing.metal, 31: WuXing.metal, // 甲午 乙未 → 沙中金
    32: WuXing.fire, 33: WuXing.fire,   // 丙申 丁酉 → 山下火
    34: WuXing.wood, 35: WuXing.wood,   // 戊戌 己亥 → 平地木
    36: WuXing.earth, 37: WuXing.earth, // 庚子 辛丑 → 壁上土
    38: WuXing.metal, 39: WuXing.metal, // 壬寅 癸卯 → 金箔金
    40: WuXing.fire, 41: WuXing.fire,   // 甲辰 乙巳 → 覆灯火
    42: WuXing.water, 43: WuXing.water, // 丙午 丁未 → 天河水
    44: WuXing.earth, 45: WuXing.earth, // 戊申 己酉 → 大驿土
    46: WuXing.wood, 47: WuXing.wood,   // 庚戌 辛亥 → 钗钏金
    48: WuXing.wood, 49: WuXing.wood,   // 壬子 癸丑 → 桑柘木
    50: WuXing.water, 51: WuXing.water, // 甲寅 乙卯 → 大溪水
    52: WuXing.earth, 53: WuXing.earth, // 丙辰 丁巳 → 沙中土
    54: WuXing.fire, 55: WuXing.fire,   // 戊午 己未 → 天上火
    56: WuXing.wood, 57: WuXing.wood,   // 庚申 辛酉 → 石榴木
    58: WuXing.water, 59: WuXing.water, // 壬戌 癸亥 → 大海水
  };

  static WuXing? of(GanZhi ganzhi) => _nayinTable[ganzhi.cycleIndex % 60];
}

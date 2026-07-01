/// 十神
enum TenGod {
  zhengGuan('正官'),
  pianGuan('偏官/七杀'),
  zhengYin('正印'),
  pianYin('偏印/枭神'),
  zhengCai('正财'),
  pianCai('偏财'),
  shiShen('食神'),
  shangGuan('伤官'),
  biJian('比肩'),
  jieCai('劫财');

  final String chinese;
  const TenGod(this.chinese);
}

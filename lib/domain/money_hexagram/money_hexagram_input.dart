/// 金钱卦输入
class MoneyHexagramInput {
  /// 用户问题
  final String question;

  /// 六次摇卦结果（null 表示使用随机生成）
  final List<int>? coinTossHeads;

  const MoneyHexagramInput({
    this.question = '',
    this.coinTossHeads,
  });

  bool get useRandom => coinTossHeads == null;
}

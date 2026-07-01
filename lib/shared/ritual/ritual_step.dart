/// 仪式步骤枚举
enum RitualStep {
  enter('入场'),
  prepareScene('设境'),
  inputQuestion('问卦'),
  performAction('仪式动作'),
  pause('戏剧停顿'),
  revealResult('结果显现'),
  aiInterpretation('AI 解读'),
  archive('归档');

  final String label;
  const RitualStep(this.label);
}

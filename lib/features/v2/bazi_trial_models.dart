enum BaziTrialStatus {
  trialOnly('trial_only', '试运行'),
  unavailable('unavailable', '暂不可用'),
  insufficientBirthTime('insufficient_birth_time', '出生时间不足'),
  dependencyUnavailable('dependency_unavailable', '依赖能力未开放');

  final String code;
  final String label;

  const BaziTrialStatus(this.code, this.label);
}

class HeavenlyStemBranch {
  final String heavenlyStem;
  final String earthlyBranch;
  final String element;
  final String yinYang;

  const HeavenlyStemBranch({
    required this.heavenlyStem,
    required this.earthlyBranch,
    required this.element,
    required this.yinYang,
  });

  String get displayText => '$heavenlyStem$earthlyBranch';
}

class BaziChart {
  final HeavenlyStemBranch? yearPillar;
  final HeavenlyStemBranch? monthPillar;
  final HeavenlyStemBranch? dayPillar;
  final HeavenlyStemBranch? hourPillar;
  final String? zodiac;
  final String fiveElementSummary;
  final String dayMaster;
  final BaziTrialStatus status;
  final List<String> warnings;
  final DateTime createdAt;

  const BaziChart({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.hourPillar,
    required this.zodiac,
    required this.fiveElementSummary,
    required this.dayMaster,
    required this.status,
    required this.warnings,
    required this.createdAt,
  });

  bool get hasAnyPillar =>
      yearPillar != null ||
      monthPillar != null ||
      dayPillar != null ||
      hourPillar != null;

  bool get isTrialOnly => status == BaziTrialStatus.trialOnly;

  List<String> get displayWarnings =>
      warnings.isEmpty ? ['当前仅为试运行结构展示。'] : warnings;
}

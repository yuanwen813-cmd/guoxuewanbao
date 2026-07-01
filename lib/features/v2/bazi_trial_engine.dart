import 'bazi_trial_models.dart';
import 'ganzhi_day_candidate_evaluator.dart';
import 'natal_profile_models.dart';

class BaziTrialEngine {
  const BaziTrialEngine();

  static const lichunBoundaryWarning = '当前年柱尚未正式处理立春年前后边界。';
  static const solarTermWarning = '月柱依赖节气换月能力。当前节气能力未作为正式公开能力使用，因此月柱仅作试运行展示。';
  static const dayPillarWarning = '当前日柱为试运行结果，仍存在样本与口径校验不足，不作为正式命理推算依据。';
  static const dayPillarMismatchHistoryWarning =
      '干支日候选评估曾出现样本不一致记录；本地试运行不阻塞，但上线前必须重新校验。';
  static const unknownBirthTimeWarning = '出生时间准确度不足，时柱暂不生成正式结果。';
  static const hourStemDependencyWarning = '时柱天干依赖日柱。当前版本仅展示时辰地支试运行结构。';

  static const fiveElementPlaceholder = '待正式五行规则接入后生成';
  static const dayMasterPlaceholder = '待正式日柱能力验收后生成';
  static const placeholderValue = '待正式校验';

  static const _heavenlyStems = [
    '甲',
    '乙',
    '丙',
    '丁',
    '戊',
    '己',
    '庚',
    '辛',
    '壬',
    '癸',
  ];

  static const _earthlyBranches = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥',
  ];

  static const _zodiacByBranch = {
    '子': '鼠',
    '丑': '牛',
    '寅': '虎',
    '卯': '兔',
    '辰': '龙',
    '巳': '蛇',
    '午': '马',
    '未': '羊',
    '申': '猴',
    '酉': '鸡',
    '戌': '狗',
    '亥': '猪',
  };

  BaziChart generate(BirthProfile profile) {
    final warnings = <String>[
      lichunBoundaryWarning,
      solarTermWarning,
      dayPillarWarning,
      dayPillarMismatchHistoryWarning,
    ];

    final yearPillar = _yearPillar(profile.gregorianBirthDateTime.year);
    final dayPillar = _dayPillar(profile.gregorianBirthDateTime);
    final hourPillar = _hourPillar(profile, warnings);

    return BaziChart(
      yearPillar: yearPillar,
      monthPillar: null,
      dayPillar: dayPillar,
      hourPillar: hourPillar,
      zodiac: _zodiacByBranch[yearPillar.earthlyBranch],
      fiveElementSummary: fiveElementPlaceholder,
      dayMaster: dayMasterPlaceholder,
      status: _resolveStatus(),
      warnings: List.unmodifiable(warnings),
      createdAt: DateTime.now(),
    );
  }

  HeavenlyStemBranch _yearPillar(int gregorianYear) {
    final index = _cycleIndex(gregorianYear);
    return HeavenlyStemBranch(
      heavenlyStem: _heavenlyStems[index % _heavenlyStems.length],
      earthlyBranch: _earthlyBranches[index % _earthlyBranches.length],
      element: placeholderValue,
      yinYang: placeholderValue,
    );
  }

  HeavenlyStemBranch _dayPillar(DateTime gregorianBirthDateTime) {
    final stemBranch = const JulianCycleGanzhiDayAlgorithm()
        .resolveDayStemBranch(gregorianBirthDateTime);
    return HeavenlyStemBranch(
      heavenlyStem: stemBranch.substring(0, 1),
      earthlyBranch: stemBranch.substring(1),
      element: placeholderValue,
      yinYang: placeholderValue,
    );
  }

  HeavenlyStemBranch? _hourPillar(
    BirthProfile profile,
    List<String> warnings,
  ) {
    if (profile.birthTimeAccuracy == BirthTimeAccuracy.unknown) {
      warnings.add(unknownBirthTimeWarning);
      return null;
    }

    warnings.add(hourStemDependencyWarning);
    return HeavenlyStemBranch(
      heavenlyStem: '待定',
      earthlyBranch: _hourBranch(profile.gregorianBirthDateTime.hour),
      element: placeholderValue,
      yinYang: placeholderValue,
    );
  }

  BaziTrialStatus _resolveStatus() {
    return BaziTrialStatus.trialOnly;
  }

  int _cycleIndex(int gregorianYear) {
    final raw = (gregorianYear - 4) % 60;
    return raw < 0 ? raw + 60 : raw;
  }

  String _hourBranch(int hour) {
    if (hour == 23 || hour == 0) return '子';
    if (hour <= 2) return '丑';
    if (hour <= 4) return '寅';
    if (hour <= 6) return '卯';
    if (hour <= 8) return '辰';
    if (hour <= 10) return '巳';
    if (hour <= 12) return '午';
    if (hour <= 14) return '未';
    if (hour <= 16) return '申';
    if (hour <= 18) return '酉';
    if (hour <= 20) return '戌';
    return '亥';
  }
}

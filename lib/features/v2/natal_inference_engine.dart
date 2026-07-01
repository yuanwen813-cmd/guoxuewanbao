import '../../domain/calendar/ganzhi.dart';
import 'ganzhi_day_candidate_evaluator.dart';
import 'natal_profile_models.dart';
import 'solar_term_boundary.dart';

class NatalInferenceEngine {
  const NatalInferenceEngine();

  static const dayPillarEvidenceNote = '当前日柱算法样本通过，但仍需要权威日干支表做全量交叉校验。';
  static const unknownBirthTimeNote = '未填写可靠出生时间，时柱无法精确生成；建议补充出生时辰后复核。';
  static const localTrialNotice = '本结果依据当前本地排盘口径生成，AI 详解仅供传统文化参考，不构成专业建议。';

  NatalInferenceReport generate(
    BirthProfile profile, {
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final boundary = const SolarTermBoundaryResolver()
        .resolve(profile.gregorianBirthDateTime);
    final yearPillar = _yearPillar(boundary.ganzhiYear, boundary);
    final monthPillar = _monthPillar(
      boundary.monthBranch,
      yearPillar.stem,
      boundary,
    );
    final dayPillar = _dayPillar(profile.gregorianBirthDateTime);
    final hourPillar = _hourPillar(profile, dayPillar.stem);
    final pillars = [
      yearPillar,
      monthPillar,
      dayPillar,
      if (hourPillar != null) hourPillar,
    ];
    final elementCounts = _elementCounts(pillars);
    final fiveElementSummary = _fiveElementSummary(elementCounts, hourPillar);
    final dayMaster = '${dayPillar.stem.chinese}日主，'
        '${dayPillar.stem.yinYang}${dayPillar.stem.wuxing}。';
    final notes = [
      ...boundary.notes,
      dayPillarEvidenceNote,
      localTrialNotice,
      if (hourPillar == null) unknownBirthTimeNote,
    ];

    final report = NatalInferenceReport(
      profile: profile,
      generatedAt: now,
      yearPillar: yearPillar,
      monthPillar: monthPillar,
      dayPillar: dayPillar,
      hourPillar: hourPillar,
      zodiac: _zodiacByBranch(yearPillar.branch),
      elementCounts: elementCounts,
      fiveElementSummary: fiveElementSummary,
      dayMaster: dayMaster,
      notes: notes,
      lifeOverview: _lifeOverview(
        profile: profile,
        dayPillar: dayPillar,
        monthPillar: monthPillar,
        elementCounts: elementCounts,
        hourPillar: hourPillar,
      ),
      annualFortunes: _annualFortunes(
        dayPillar: dayPillar,
        startYear: now.year,
      ),
      monthlyFortunes: _monthlyFortunes(
        dayPillar: dayPillar,
        year: now.year,
      ),
      tiebanReference: _tiebanReference(
        profile: profile,
        yearPillar: yearPillar,
        monthPillar: monthPillar,
        dayPillar: dayPillar,
        hourPillar: hourPillar,
      ),
    );
    return report;
  }

  NatalPillar _yearPillar(
    int ganzhiYear,
    SolarTermBoundaryResult boundary,
  ) {
    final index = _positiveModulo(ganzhiYear - 4, 60);
    final stem = TianGan.fromOrder(index);
    final branch = DiZhi.fromOrder(index);
    final basis = boundary.yearBoundary == null
        ? '本地节气表未覆盖该年立春时刻，按试运行近似边界生成'
        : '按${boundary.yearBoundary!.term.label} ${boundary.yearBoundary!.displayText} 切年生成';
    return NatalPillar(
      name: '年柱',
      stem: stem,
      branch: branch,
      basis: basis,
    );
  }

  NatalPillar _monthPillar(
    DiZhi branch,
    TianGan yearStem,
    SolarTermBoundaryResult boundary,
  ) {
    final startStemOrder = ((yearStem.order % 5) * 2 + 2) % 10;
    final solarMonthIndex = _positiveModulo(branch.order - DiZhi.yin.order, 12);
    final stemOrder = _positiveModulo(startStemOrder + solarMonthIndex, 10);
    final basis = boundary.monthBoundary == null
        ? '本地节气表未覆盖该节令时刻，按试运行近似边界和五虎遁生成'
        : '按${boundary.monthBoundary!.term.label} ${boundary.monthBoundary!.displayText} 切月，并按五虎遁生成月干';
    return NatalPillar(
      name: '月柱',
      stem: TianGan.fromOrder(stemOrder),
      branch: branch,
      basis: basis,
    );
  }

  NatalPillar _dayPillar(DateTime date) {
    final stemBranch =
        const JulianCycleGanzhiDayAlgorithm().resolveDayStemBranch(date);
    return NatalPillar(
      name: '日柱',
      stem: _stemOf(stemBranch.substring(0, 1)),
      branch: _branchOf(stemBranch.substring(1)),
      basis: '按本地干支日循环候选算法生成',
    );
  }

  NatalPillar? _hourPillar(BirthProfile profile, TianGan dayStem) {
    if (profile.birthTimeAccuracy == BirthTimeAccuracy.unknown) {
      return null;
    }
    final branch = DiZhi.fromHour(profile.gregorianBirthDateTime.hour);
    final startStemOrder = (dayStem.order % 5) * 2;
    final stemOrder = _positiveModulo(startStemOrder + branch.order, 10);
    return NatalPillar(
      name: '时柱',
      stem: TianGan.fromOrder(stemOrder),
      branch: branch,
      basis: '按北京时间时辰划分和五鼠遁起时干规则生成',
    );
  }

  Map<String, int> _elementCounts(List<NatalPillar> pillars) {
    final counts = {'木': 0, '火': 0, '土': 0, '金': 0, '水': 0};
    for (final pillar in pillars) {
      counts[pillar.stem.wuxing] = counts[pillar.stem.wuxing]! + 1;
      counts[pillar.branch.wuxing] = counts[pillar.branch.wuxing]! + 1;
    }
    return counts;
  }

  String _fiveElementSummary(
    Map<String, int> counts,
    NatalPillar? hourPillar,
  ) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final strongest = sorted.first;
    final weakest = sorted.last;
    final suffix = hourPillar == null ? '；因缺少可靠出生时间，时柱未纳入统计' : '';
    return '五行分布：${_formatElementCounts(counts)}。'
        '当前以${strongest.key}较显，${weakest.key}相对偏少$suffix。';
  }

  List<NatalReadingItem> _lifeOverview({
    required BirthProfile profile,
    required NatalPillar dayPillar,
    required NatalPillar monthPillar,
    required Map<String, int> elementCounts,
    required NatalPillar? hourPillar,
  }) {
    final dayElement = dayPillar.stem.wuxing;
    final monthElement = monthPillar.branch.wuxing;
    return [
      NatalReadingItem(
        title: '基础命盘',
        body: '以${profile.birthDateText}为基准，已生成'
            '${dayPillar.displayText}日、${monthPillar.displayText}月的命盘结构。'
            '${hourPillar == null ? '出生时间未确认，时柱需要补充后复核。' : '时柱为${hourPillar.displayText}。'}',
      ),
      NatalReadingItem(
        title: '日主结构参考',
        body: '$dayElement日主落在${dayPillar.branch.chinese}支，'
            '本地测试阶段仅作为结构字段展示，不生成性格、事业、财运、婚恋等断语。',
      ),
      NatalReadingItem(
        title: '月令结构参考',
        body: '月令属$monthElement，代表外部节气环境对命盘结构的影响。'
            '当前只展示命盘结构关系，不开放正式命理推算。',
      ),
      NatalReadingItem(
        title: '五行结构',
        body: _formatElementCounts(elementCounts),
      ),
    ];
  }

  List<NatalFortuneItem> _annualFortunes({
    required NatalPillar dayPillar,
    required int startYear,
  }) {
    return [
      for (var offset = 0; offset < 5; offset += 1)
        _annualFortuneForYear(dayPillar, startYear + offset),
    ];
  }

  NatalFortuneItem _annualFortuneForYear(
    NatalPillar dayPillar,
    int year,
  ) {
    final boundary =
        const SolarTermBoundaryResolver().resolve(DateTime(year, 6));
    final pillar = _yearPillar(boundary.ganzhiYear, boundary);
    final relation = _elementRelation(
      subjectElement: dayPillar.stem.wuxing,
      guestElement: pillar.stem.wuxing,
    );
    return NatalFortuneItem(
      title: '$year 年',
      subtitle: '${pillar.displayText}流年 · $relation',
      body: _annualBody(relation, pillar),
      tags: [pillar.stem.wuxing, pillar.branch.wuxing, relation],
    );
  }

  String _annualBody(String relation, NatalPillar pillar) {
    return switch (relation) {
      '同气' => '这一年与日主五行同气，适合稳住主线、整合资源，也要避免惯性过强。',
      '得生' => '这一年外部助力较明显，适合学习、筹备、修复关系和补足基础。',
      '输出' => '这一年表达、创作、传播和执行感更强，适合把想法落到具体行动。',
      '受克' => '这一年规则、压力和责任感更强，适合用制度、计划和边界管理事务。',
      '可制' => '这一年更适合处理资源、协作与现实目标，重在节制欲望和控制节奏。',
      _ => '这一年以${pillar.displayText}为观察点，需结合具体问题细看。',
    };
  }

  List<NatalFortuneItem> _monthlyFortunes({
    required NatalPillar dayPillar,
    required int year,
  }) {
    return [
      for (var month = 1; month <= 12; month += 1)
        _monthlyFortuneForMonth(dayPillar, year, month),
    ];
  }

  NatalFortuneItem _monthlyFortuneForMonth(
    NatalPillar dayPillar,
    int year,
    int month,
  ) {
    final boundary =
        const SolarTermBoundaryResolver().resolve(DateTime(year, month, 15));
    final yearPillar = _yearPillar(boundary.ganzhiYear, boundary);
    final pillar = _monthPillar(
      boundary.monthBranch,
      yearPillar.stem,
      boundary,
    );
    final relation = _elementRelation(
      subjectElement: dayPillar.stem.wuxing,
      guestElement: pillar.branch.wuxing,
    );
    return NatalFortuneItem(
      title: '$month 月',
      subtitle: '${pillar.displayText}月令 · $relation',
      body: _monthlyBody(relation),
      tags: [pillar.stem.wuxing, pillar.branch.wuxing, relation],
    );
  }

  String _monthlyBody(String relation) {
    return switch (relation) {
      '同气' => '本月适合延续既定计划，保持节奏，避免在熟悉领域反复消耗。',
      '得生' => '本月适合吸收信息、修整状态、做准备工作，先蓄力再推进。',
      '输出' => '本月适合表达、交付、展示成果，也要注意不要过度承诺。',
      '受克' => '本月压力和约束感较强，适合处理规则、流程和必须完成的责任。',
      '可制' => '本月适合谈资源、处理钱物和合作边界，重点是稳住判断。',
      _ => '本月以阶段观察为主，宜结合具体事项再细分。',
    };
  }

  TiebanLocalReference _tiebanReference({
    required BirthProfile profile,
    required NatalPillar yearPillar,
    required NatalPillar monthPillar,
    required NatalPillar dayPillar,
    required NatalPillar? hourPillar,
  }) {
    final date = profile.gregorianBirthDateTime;
    final hourCode = hourPillar?.branch.order ?? 0;
    final baseNumber = date.year * 10000 +
        date.month * 100 +
        date.day +
        hourCode * 13 +
        dayPillar.stem.order * 7 +
        monthPillar.branch.order * 5;
    final normalized = 1000 + _positiveModulo(baseNumber, 9000);
    final candidates = [
      normalized,
      1000 + _positiveModulo(normalized + yearPillar.branch.order * 37, 9000),
      1000 + _positiveModulo(normalized + dayPillar.branch.order * 53, 9000),
    ];
    return TiebanLocalReference(
      birthCode: normalized.toString(),
      timeCode: hourPillar == null
          ? '未填写可靠出生时间'
          : '${hourPillar.branch.chinese}时 · ${hourPillar.displayText}',
      sequenceCandidates: candidates.map((value) => value.toString()).toList(),
      summary: '根据出生年月日时与四柱结构生成本地数序参考，'
          '用于后续结合六亲、核时与条文库进行人工校核。',
      calibrationPrompt: '建议后续补充父母、兄弟、婚育、迁居等关键节点，用于核时和数序筛选。',
    );
  }

  String _formatElementCounts(Map<String, int> counts) {
    const order = ['木', '火', '土', '金', '水'];
    return order.map((element) => '$element${counts[element] ?? 0}').join('、');
  }

  String _elementRelation({
    required String subjectElement,
    required String guestElement,
  }) {
    if (subjectElement == guestElement) return '同气';
    if (_generates(guestElement) == subjectElement) return '得生';
    if (_generates(subjectElement) == guestElement) return '输出';
    if (_controls(guestElement) == subjectElement) return '受克';
    if (_controls(subjectElement) == guestElement) return '可制';
    return '平衡';
  }

  String _generates(String element) => switch (element) {
        '木' => '火',
        '火' => '土',
        '土' => '金',
        '金' => '水',
        '水' => '木',
        _ => '',
      };

  String _controls(String element) => switch (element) {
        '木' => '土',
        '土' => '水',
        '水' => '火',
        '火' => '金',
        '金' => '木',
        _ => '',
      };

  String _zodiacByBranch(DiZhi branch) {
    return switch (branch) {
      DiZhi.zi => '鼠',
      DiZhi.chou => '牛',
      DiZhi.yin => '虎',
      DiZhi.mao => '兔',
      DiZhi.chen => '龙',
      DiZhi.si => '蛇',
      DiZhi.wu => '马',
      DiZhi.wei => '羊',
      DiZhi.shen => '猴',
      DiZhi.you => '鸡',
      DiZhi.xu => '狗',
      DiZhi.hai => '猪',
    };
  }

  TianGan _stemOf(String value) =>
      TianGan.values.firstWhere((stem) => stem.chinese == value);

  DiZhi _branchOf(String value) =>
      DiZhi.values.firstWhere((branch) => branch.chinese == value);

  int _positiveModulo(int value, int modulo) {
    final result = value % modulo;
    return result < 0 ? result + modulo : result;
  }
}

class NatalInferenceReport {
  final BirthProfile profile;
  final DateTime generatedAt;
  final NatalPillar yearPillar;
  final NatalPillar monthPillar;
  final NatalPillar dayPillar;
  final NatalPillar? hourPillar;
  final String zodiac;
  final Map<String, int> elementCounts;
  final String fiveElementSummary;
  final String dayMaster;
  final List<String> notes;
  final List<NatalReadingItem> lifeOverview;
  final List<NatalFortuneItem> annualFortunes;
  final List<NatalFortuneItem> monthlyFortunes;
  final TiebanLocalReference tiebanReference;

  const NatalInferenceReport({
    required this.profile,
    required this.generatedAt,
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.hourPillar,
    required this.zodiac,
    required this.elementCounts,
    required this.fiveElementSummary,
    required this.dayMaster,
    required this.notes,
    required this.lifeOverview,
    required this.annualFortunes,
    required this.monthlyFortunes,
    required this.tiebanReference,
  });

  List<NatalPillar> get availablePillars => [
        yearPillar,
        monthPillar,
        dayPillar,
        if (hourPillar != null) hourPillar!,
      ];

  String get pillarSummary {
    final hourText = hourPillar?.displayText ?? '时柱需补充出生时间';
    return '年柱${yearPillar.displayText}，月柱${monthPillar.displayText}，'
        '日柱${dayPillar.displayText}，$hourText。';
  }

  String buildAiContext({required String questionFocus}) {
    return [
      '用户关注：$questionFocus',
      '出生资料：${profile.displayName}，${profile.relationship.label}，'
          '${profile.gender.label}，${profile.birthDateText}，'
          '出生地：${profile.birthPlaceName ?? '未填写'}，'
          '农历：${profile.lunarBirthDateText ?? '未填写'}，'
          '时间准确度：${profile.birthTimeAccuracy.label}',
      '四柱：$pillarSummary',
      '生肖：$zodiac',
      '五行摘要：$fiveElementSummary',
      '日主：$dayMaster',
      '流年：${annualFortunes.map((item) => '${item.title} ${item.subtitle} ${item.body}').join('；')}',
      '月度：${monthlyFortunes.map((item) => '${item.title} ${item.subtitle}').join('；')}',
      '铁板神数参考：${tiebanReference.summary} 数序候选：${tiebanReference.sequenceCandidates.join('、')}',
      '边界说明：${notes.join('；')}',
    ].join('\n');
  }
}

class NatalPillar {
  final String name;
  final TianGan stem;
  final DiZhi branch;
  final String basis;

  const NatalPillar({
    required this.name,
    required this.stem,
    required this.branch,
    required this.basis,
  });

  String get displayText => '${stem.chinese}${branch.chinese}';

  String get detailText => '天干${stem.chinese}（${stem.yinYang}${stem.wuxing}），'
      '地支${branch.chinese}（${branch.yinYang}${branch.wuxing}）';
}

class NatalReadingItem {
  final String title;
  final String body;

  const NatalReadingItem({
    required this.title,
    required this.body,
  });
}

class NatalFortuneItem {
  final String title;
  final String subtitle;
  final String body;
  final List<String> tags;

  const NatalFortuneItem({
    required this.title,
    required this.subtitle,
    required this.body,
    this.tags = const [],
  });
}

class TiebanLocalReference {
  final String birthCode;
  final String timeCode;
  final List<String> sequenceCandidates;
  final String summary;
  final String calibrationPrompt;

  const TiebanLocalReference({
    required this.birthCode,
    required this.timeCode,
    required this.sequenceCandidates,
    required this.summary,
    required this.calibrationPrompt,
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/features/v2/bazi_trial_engine.dart';
import 'package:guoxueapp/features/v2/bazi_trial_models.dart';
import 'package:guoxueapp/features/v2/bazi_trial_observer.dart';
import 'package:guoxueapp/features/v2/ganzhi_day_candidate_evaluator.dart';
import 'package:guoxueapp/features/v2/natal_profile_models.dart';

void main() {
  group('BaziTrialEngine', () {
    test('BirthProfile can generate BaziChart trial result', () {
      final profile = _profile(birthTimeAccuracy: BirthTimeAccuracy.accurate);

      final chart = BaziTrialEngine().generate(profile);

      expect(chart.yearPillar, isNotNull);
      expect(chart.yearPillar!.displayText, isNotEmpty);
      expect(chart.dayPillar, isNotNull);
      expect(chart.dayPillar!.displayText, isNotEmpty);
      expect(chart.zodiac, isNotEmpty);
      expect(chart.hasAnyPillar, isTrue);
      expect(chart.status, BaziTrialStatus.trialOnly);
      expect(chart.fiveElementSummary, BaziTrialEngine.fiveElementPlaceholder);
      expect(chart.dayMaster, BaziTrialEngine.dayMasterPlaceholder);
      expect(
        chart.warnings,
        contains(BaziTrialEngine.lichunBoundaryWarning),
      );
      expect(chart.warnings, contains(BaziTrialEngine.solarTermWarning));
      expect(chart.warnings, contains(BaziTrialEngine.dayPillarWarning));
      expect(
        chart.warnings,
        contains(BaziTrialEngine.dayPillarMismatchHistoryWarning),
      );
    });

    test('unknown birth time warns and does not generate hour pillar', () {
      final profile = _profile(birthTimeAccuracy: BirthTimeAccuracy.unknown);

      final chart = BaziTrialEngine().generate(profile);

      expect(chart.hourPillar, isNull);
      expect(
        chart.warnings,
        contains(BaziTrialEngine.unknownBirthTimeWarning),
      );
      expect(chart.dayPillar, isNotNull);
      expect(chart.status, BaziTrialStatus.trialOnly);
    });

    test('trial result does not output formal reading copy', () {
      final chart = BaziTrialEngine().generate(
        _profile(birthTimeAccuracy: BirthTimeAccuracy.accurate),
      );
      final combinedText = [
        chart.fiveElementSummary,
        chart.dayMaster,
        ...chart.warnings,
      ].join('\n');

      expect(combinedText, isNot(contains('你的命格')));
      expect(combinedText, isNot(contains('你的事业运')));
      expect(combinedText, isNot(contains('你的财运')));
      expect(combinedText, isNot(contains('你的婚姻')));
      expect(combinedText, isNot(contains('格局高低')));
      expect(combinedText, isNot(contains('喜用神')));
      expect(combinedText, isNot(contains('十神断语')));
      expect(combinedText, isNot(contains('AI 为你解析')));
      expect(combinedText, isNot(contains('付费解锁')));
      expect(combinedText, isNot(contains('会员扣点')));
    });
  });

  group('BaziTrialSampleObserver', () {
    final samples = _sampleProfiles();

    test('sample set covers v0.59 observation boundaries', () {
      expect(samples, hasLength(5));
      expect(
        samples.map((profile) => profile.relationship).toSet(),
        containsAll(BirthRelationship.values),
      );
      expect(
        samples.map((profile) => profile.gender).toSet(),
        containsAll([BirthGender.male, BirthGender.female]),
      );
      expect(
        samples.map((profile) => profile.birthTimeAccuracy).toSet(),
        containsAll([
          BirthTimeAccuracy.accurate,
          BirthTimeAccuracy.approximate,
          BirthTimeAccuracy.unknown,
        ]),
      );
      expect(samples.any((profile) => profile.birthPlaceName == null), isTrue);
      expect(samples.any((profile) => profile.birthPlaceName != null), isTrue);
      expect(
        samples.any((profile) => profile.lunarBirthDateText != null),
        isTrue,
      );
    });

    test('observes status and warning distributions', () {
      final observation = const BaziTrialSampleObserver().observe(samples);

      expect(observation.totalSamples, samples.length);
      expect(observation.sampleResults, hasLength(samples.length));
      expect(observation.samplesWithYearPillar, samples.length);
      expect(observation.unknownBirthTimeSamples, 2);
      expect(observation.samplesWithoutHourPillar, 2);
      expect(observation.dependencyUnavailableSamples, 0);
      expect(
        observation.statusCounts[BaziTrialStatus.trialOnly],
        samples.length,
      );
      expect(
        observation.warningCounts[BaziTrialEngine.lichunBoundaryWarning],
        samples.length,
      );
      expect(
        observation.warningCounts[BaziTrialEngine.solarTermWarning],
        samples.length,
      );
      expect(
        observation.warningCounts[BaziTrialEngine.dayPillarWarning],
        samples.length,
      );
      expect(
        observation
            .warningCounts[BaziTrialEngine.dayPillarMismatchHistoryWarning],
        samples.length,
      );
      expect(
        observation.warningCounts[BaziTrialEngine.unknownBirthTimeWarning],
        observation.unknownBirthTimeSamples,
      );
      expect(
        observation.warningCounts[BaziTrialEngine.hourStemDependencyWarning],
        samples.length - observation.unknownBirthTimeSamples,
      );
      expect(
        observation.dependencyWarnings,
        contains(BaziTrialEngine.solarTermWarning),
      );
      expect(observation.observationIssues, isEmpty);
    });

    test('all samples remain trial-only in wording and avoid formal readings',
        () {
      final observation = const BaziTrialSampleObserver().observe(samples);

      for (final result in observation.sampleResults) {
        final chart = result.chart;
        expect(chart.yearPillar, isNotNull);
        expect(chart.monthPillar, isNull);
        expect(chart.dayPillar, isNotNull);
        expect(
            chart.fiveElementSummary, BaziTrialEngine.fiveElementPlaceholder);
        expect(chart.dayMaster, BaziTrialEngine.dayMasterPlaceholder);
        expect(chart.warnings, contains(BaziTrialEngine.solarTermWarning));
        expect(chart.warnings, contains(BaziTrialEngine.dayPillarWarning));
        expect(
          chart.warnings,
          contains(BaziTrialEngine.dayPillarMismatchHistoryWarning),
        );

        final combinedText = [
          chart.fiveElementSummary,
          chart.dayMaster,
          ...chart.warnings,
        ].join('\n');
        expect(combinedText, isNot(contains('你的命格')));
        expect(combinedText, isNot(contains('你的事业运')));
        expect(combinedText, isNot(contains('你的财运')));
        expect(combinedText, isNot(contains('你的婚姻')));
        expect(combinedText, isNot(contains('格局高低')));
        expect(combinedText, isNot(contains('喜用神')));
        expect(combinedText, isNot(contains('十神断语')));
        expect(combinedText, isNot(contains('AI 为你解析')));
        expect(combinedText, isNot(contains('付费解锁')));
        expect(combinedText, isNot(contains('会员扣点')));
      }

      final unknownSamples = observation.sampleResults.where(
        (result) =>
            result.profile.birthTimeAccuracy == BirthTimeAccuracy.unknown,
      );
      for (final result in unknownSamples) {
        expect(result.chart.hourPillar, isNull);
        expect(
          result.chart.warnings,
          contains(BaziTrialEngine.unknownBirthTimeWarning),
        );
      }
    });
  });

  group('GanzhiDayCandidateEvaluator v0.60', () {
    final samples = GanzhiDayCandidateSamples.v060;
    const algorithm = JulianCycleGanzhiDayAlgorithm();

    test('candidate samples cover required date ranges', () {
      expect(samples, hasLength(greaterThanOrEqualTo(20)));
      expect(samples.any((sample) => sample.date.year == 1901), isTrue);
      expect(samples.any((sample) => sample.date.year == 1950), isTrue);
      expect(samples.any((sample) => sample.date.year == 1980), isTrue);
      expect(samples.any((sample) => sample.date.year == 2000), isTrue);
      expect(samples.any((sample) => sample.date.year == 2025), isTrue);
      expect(
        samples
            .any((sample) => sample.date.month == 2 && sample.date.day == 29),
        isTrue,
      );
      expect(
        samples.any((sample) => sample.note.contains('跨月')),
        isTrue,
      );
      expect(
        samples.any((sample) => sample.note.contains('跨年')),
        isTrue,
      );
      expect(
        samples.any((sample) => sample.referenceDayStemBranch == '甲辰'),
        isTrue,
      );
    });

    test('evaluates matched mismatch and insufficient evidence statuses', () {
      final evaluation = const GanzhiDayCandidateEvaluator().evaluate(
        samples: samples,
        algorithm: algorithm,
        dataSource: _v060DataSource(algorithm),
      );

      expect(evaluation.totalSamples, samples.length);
      expect(evaluation.results, hasLength(samples.length));
      expect(evaluation.matchedSamples, 11);
      expect(evaluation.mismatchedSamples, 1);
      expect(evaluation.insufficientSamples, 8);
      expect(
        evaluation.statusCounts[GanzhiDayCandidateStatus.matched],
        11,
      );
      expect(
        evaluation.statusCounts[GanzhiDayCandidateStatus.mismatch],
        1,
      );
      expect(
        evaluation.statusCounts[GanzhiDayCandidateStatus.insufficientEvidence],
        8,
      );
      expect(
        evaluation.results.every((result) => result.dayStemBranch != null),
        isTrue,
      );
      expect(evaluation.confidenceSummary, contains('matched=11'));
      expect(evaluation.confidenceSummary, contains('mismatch=1'));
      expect(evaluation.confidenceSummary, contains('insufficient=8'));
      expect(
        evaluation.recommendation,
        GanzhiDayCandidateRecommendation.reject,
      );
      expect(
        evaluation.recommendation,
        isNot(GanzhiDayCandidateRecommendation.readyForInternalEngine),
      );
    });

    test('insufficient samples require more evidence', () {
      final evaluation = const GanzhiDayCandidateEvaluator().evaluate(
        samples: samples.take(5).toList(),
        algorithm: algorithm,
        dataSource: const MapGanzhiDayDataSource(
          name: 'empty_reference_fixture',
          dayStemBranchesByDate: {},
        ),
      );

      expect(evaluation.totalSamples, 5);
      expect(evaluation.matchedSamples, 0);
      expect(evaluation.mismatchedSamples, 0);
      expect(evaluation.insufficientSamples, 5);
      expect(
        evaluation.recommendation,
        GanzhiDayCandidateRecommendation.needsMoreSamples,
      );
    });

    test('candidate evaluation does not change bazi trial behavior', () {
      final profile = _profile(birthTimeAccuracy: BirthTimeAccuracy.accurate);
      final chart = const BaziTrialEngine().generate(profile);

      expect(chart.dayPillar, isNotNull);
      expect(chart.status, BaziTrialStatus.trialOnly);
      expect(chart.warnings, contains(BaziTrialEngine.dayPillarWarning));
    });
  });

  group('GanzhiDayCandidateEvaluator v0.61', () {
    final samples = GanzhiDayCandidateSamples.v061;
    const algorithm = JulianCycleGanzhiDayAlgorithm();

    test('evidence samples expand to forty public dates', () {
      expect(samples, hasLength(40));
      expect(samples.any((sample) => sample.date.year == 1901), isTrue);
      expect(samples.any((sample) => sample.date.year == 1950), isTrue);
      expect(samples.any((sample) => sample.date.year == 1980), isTrue);
      expect(samples.any((sample) => sample.date.year == 2000), isTrue);
      expect(samples.any((sample) => sample.date.year == 2024), isTrue);
      expect(samples.any((sample) => sample.date.year == 2025), isTrue);
      expect(
        samples.any(
          (sample) => sample.date.month == 2 && sample.date.day == 29,
        ),
        isTrue,
      );
      expect(samples.any((sample) => sample.note.contains('立春')), isTrue);
      expect(samples.any((sample) => sample.note.contains('春节')), isTrue);
      expect(samples.any((sample) => sample.note.contains('跨月')), isTrue);
      expect(samples.any((sample) => sample.note.contains('跨年')), isTrue);
    });

    test('audits mismatch and insufficient evidence details', () {
      final evaluation = const GanzhiDayCandidateEvaluator().evaluate(
        samples: samples,
        algorithm: algorithm,
        dataSource: _v061PrimarySource(algorithm),
        secondaryReference: _v061SecondaryReferenceSource(algorithm),
      );

      expect(evaluation.totalSamples, 40);
      expect(evaluation.matchedSamples, 36);
      expect(evaluation.mismatchedSamples, 1);
      expect(evaluation.insufficientSamples, 3);
      expect(evaluation.primaryReferenceCount, 37);
      expect(evaluation.secondaryReferenceCount, 37);
      expect(evaluation.multiSourceMatchedSamples, 36);
      expect(evaluation.unresolvedMismatchSamples, 1);
      expect(evaluation.mismatchAudits, hasLength(1));
      expect(evaluation.insufficientEvidenceAudits, hasLength(3));
      expect(
        evaluation.recommendation,
        GanzhiDayCandidateRecommendation.reject,
      );
      expect(
        evaluation.recommendation,
        isNot(GanzhiDayCandidateRecommendation.readyForInternalEngine),
      );

      final audit = evaluation.mismatchAudits.single;
      expect(formatDateKey(audit.date), '2025-03-01');
      expect(audit.algorithmResult, '己巳');
      expect(audit.dataSourceResult, '错日');
      expect(audit.secondaryReferenceResult, audit.algorithmResult);
      expect(audit.mismatchReason, contains('错日'));
      expect(audit.suspectedCause, contains('fixture 人为录入错误'));
      expect(audit.actionRequired, contains('不得进入正式可用状态'));

      final insufficientDates = evaluation.insufficientEvidenceAudits
          .map((audit) => formatDateKey(audit.date))
          .toSet();
      expect(
        insufficientDates,
        containsAll(['2025-10-01', '2026-02-17', '2026-12-31']),
      );
      for (final audit in evaluation.insufficientEvidenceAudits) {
        expect(audit.algorithmResult, isNotNull);
        expect(audit.availableReferences, isEmpty);
        expect(audit.missingReferences, contains('primary_reference'));
        expect(audit.missingReferences, contains('secondary_reference'));
        expect(audit.missingReferences, contains('known_reference'));
        expect(
          audit.currentStatus,
          GanzhiDayCandidateStatus.insufficientEvidence,
        );
      }
    });

    test('secondary reference participates and raises confidence', () {
      final singleSample = [samples.first];
      final withoutSecondary = const GanzhiDayCandidateEvaluator().evaluate(
        samples: singleSample,
        algorithm: algorithm,
        dataSource: _v061PrimarySource(algorithm),
      );
      final withSecondary = const GanzhiDayCandidateEvaluator().evaluate(
        samples: singleSample,
        algorithm: algorithm,
        dataSource: _v061PrimarySource(algorithm),
        secondaryReference: _v061SecondaryReferenceSource(algorithm),
      );

      expect(withoutSecondary.results.single.confidence, 0.75);
      expect(withSecondary.results.single.confidence, 1.0);
      expect(withSecondary.results.single.secondaryReferenceResult, isNotNull);
      expect(
        withSecondary.results.single.matchedReferences,
        contains(
          'v0_61_primary_reference_fixture=v0_61_secondary_reference_fixture=${withSecondary.results.single.dayStemBranch}',
        ),
      );
    });

    test('unresolved mismatch blocks trial recommendation', () {
      final evaluation = const GanzhiDayCandidateEvaluator().evaluate(
        samples: samples,
        algorithm: algorithm,
        dataSource: _v061PrimarySource(algorithm),
        secondaryReference: _v061SecondaryReferenceSource(algorithm),
      );

      expect(evaluation.unresolvedMismatchSamples, 1);
      expect(
        evaluation.recommendation,
        GanzhiDayCandidateRecommendation.reject,
      );
    });

    test('candidate audit keeps bazi trial engine behavior unchanged', () {
      final profile = _profile(birthTimeAccuracy: BirthTimeAccuracy.accurate);
      final chart = const BaziTrialEngine().generate(profile);

      expect(chart.dayPillar, isNotNull);
      expect(chart.monthPillar, isNull);
      expect(chart.status, BaziTrialStatus.trialOnly);
      expect(chart.warnings, contains(BaziTrialEngine.dayPillarWarning));
      expect(chart.fiveElementSummary, BaziTrialEngine.fiveElementPlaceholder);
      expect(chart.dayMaster, BaziTrialEngine.dayMasterPlaceholder);
    });
  });
}

BirthProfile _profile({required BirthTimeAccuracy birthTimeAccuracy}) {
  return BirthProfile.create(
    displayName: '测试档案',
    relationship: BirthRelationship.self,
    gender: BirthGender.male,
    gregorianBirthDateTime: DateTime(1992, 6, 18, 8, 30),
    birthTimeAccuracy: birthTimeAccuracy,
    birthPlaceName: '杭州',
    lunarBirthDateText: '壬申年五月十八',
  );
}

List<BirthProfile> _sampleProfiles() {
  return [
    BirthProfile.create(
      displayName: '本人样本',
      relationship: BirthRelationship.self,
      gender: BirthGender.male,
      gregorianBirthDateTime: DateTime(1992, 6, 18, 8, 30),
      birthTimeAccuracy: BirthTimeAccuracy.accurate,
      birthPlaceName: '杭州',
      lunarBirthDateText: '壬申年五月十八',
    ),
    BirthProfile.create(
      displayName: '家人样本',
      relationship: BirthRelationship.family,
      gender: BirthGender.female,
      gregorianBirthDateTime: DateTime(1988, 3, 12, 14, 10),
      birthTimeAccuracy: BirthTimeAccuracy.accurate,
      birthPlaceName: '苏州',
    ),
    BirthProfile.create(
      displayName: '朋友样本',
      relationship: BirthRelationship.friend,
      gender: BirthGender.male,
      gregorianBirthDateTime: DateTime(2001, 11, 3, 21, 20),
      birthTimeAccuracy: BirthTimeAccuracy.approximate,
      lunarBirthDateText: '辛巳年九月十八',
    ),
    BirthProfile.create(
      displayName: '客户样本',
      relationship: BirthRelationship.client,
      gender: BirthGender.female,
      gregorianBirthDateTime: DateTime(1979, 1, 22),
      birthTimeAccuracy: BirthTimeAccuracy.unknown,
      birthPlaceName: '广州',
      lunarBirthDateText: '戊午年腊月廿四',
    ),
    BirthProfile.create(
      displayName: '其他样本',
      relationship: BirthRelationship.other,
      gender: BirthGender.undisclosed,
      gregorianBirthDateTime: DateTime(2010, 9, 9),
      birthTimeAccuracy: BirthTimeAccuracy.unknown,
    ),
  ];
}

MapGanzhiDayDataSource _v060DataSource(
  JulianCycleGanzhiDayAlgorithm algorithm,
) {
  final samples = GanzhiDayCandidateSamples.v060;
  final values = <String, String>{};
  final matchedIndexes = <int>{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 14};
  for (final index in matchedIndexes) {
    final sample = samples[index];
    values[sample.dateKey] = algorithm.resolveDayStemBranch(sample.date);
  }

  values[samples[15].dateKey] = '错日';
  return MapGanzhiDayDataSource(
    name: 'v0_60_fixture_candidate',
    dayStemBranchesByDate: values,
  );
}

MapGanzhiDayDataSource _v061PrimarySource(
  JulianCycleGanzhiDayAlgorithm algorithm,
) {
  final samples = GanzhiDayCandidateSamples.v061;
  final values = <String, String>{};
  for (var index = 0; index < 36; index += 1) {
    final sample = samples[index];
    values[sample.dateKey] = algorithm.resolveDayStemBranch(sample.date);
  }

  values[samples[36].dateKey] = '错日';
  return MapGanzhiDayDataSource(
    name: 'v0_61_primary_reference_fixture',
    dayStemBranchesByDate: values,
  );
}

VerifiedGanzhiDayFixtureSource _v061SecondaryReferenceSource(
  JulianCycleGanzhiDayAlgorithm algorithm,
) {
  final samples = GanzhiDayCandidateSamples.v061;
  return VerifiedGanzhiDayFixtureSource(
    name: 'v0_61_secondary_reference_fixture',
    references: [
      for (var index = 0; index < 37; index += 1)
        GanzhiDayReference(
          date: samples[index].date,
          expectedStemBranch: algorithm.resolveDayStemBranch(
            samples[index].date,
          ),
          sourceName: 'v0.61 secondary fixture',
          sourceType: 'offline_reference_fixture',
          confidence: 0.85,
          notes: '仅用于候选证据增强，不代表正式干支日数据源。',
        ),
    ],
  );
}

import 'bazi_trial_engine.dart';
import 'bazi_trial_models.dart';
import 'natal_profile_models.dart';

class BaziTrialSampleResult {
  final BirthProfile profile;
  final BaziChart chart;

  const BaziTrialSampleResult({
    required this.profile,
    required this.chart,
  });
}

class BaziTrialObservationResult {
  final int totalSamples;
  final List<BaziTrialSampleResult> sampleResults;
  final Map<BaziTrialStatus, int> statusCounts;
  final Map<String, int> warningCounts;
  final int samplesWithYearPillar;
  final int samplesWithoutHourPillar;
  final int unknownBirthTimeSamples;
  final int dependencyUnavailableSamples;
  final List<String> dependencyWarnings;
  final List<String> observationIssues;

  const BaziTrialObservationResult({
    required this.totalSamples,
    required this.sampleResults,
    required this.statusCounts,
    required this.warningCounts,
    required this.samplesWithYearPillar,
    required this.samplesWithoutHourPillar,
    required this.unknownBirthTimeSamples,
    required this.dependencyUnavailableSamples,
    required this.dependencyWarnings,
    required this.observationIssues,
  });
}

class BaziTrialSampleObserver {
  final BaziTrialEngine engine;

  const BaziTrialSampleObserver({this.engine = const BaziTrialEngine()});

  BaziTrialObservationResult observe(List<BirthProfile> profiles) {
    final sampleResults = [
      for (final profile in profiles)
        BaziTrialSampleResult(
            profile: profile, chart: engine.generate(profile)),
    ];

    final statusCounts = <BaziTrialStatus, int>{};
    final warningCounts = <String, int>{};
    for (final result in sampleResults) {
      statusCounts.update(result.chart.status, (count) => count + 1,
          ifAbsent: () => 1);
      for (final warning in result.chart.warnings) {
        warningCounts.update(warning, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    final dependencyWarnings = warningCounts.keys
        .where((warning) => warning.contains('依赖'))
        .toList(growable: false);

    final observationIssues = <String>[
      if (profiles.isEmpty) '没有可观测样本。',
      if (sampleResults.any((result) => result.chart.yearPillar == null))
        '存在未生成年柱的样本。',
      if (!warningCounts.containsKey(BaziTrialEngine.solarTermWarning))
        '缺少月柱节气依赖提示。',
      if (!warningCounts.containsKey(BaziTrialEngine.dayPillarWarning))
        '缺少日柱试运行提示。',
    ];

    return BaziTrialObservationResult(
      totalSamples: profiles.length,
      sampleResults: List.unmodifiable(sampleResults),
      statusCounts: Map.unmodifiable(statusCounts),
      warningCounts: Map.unmodifiable(warningCounts),
      samplesWithYearPillar: sampleResults
          .where((result) => result.chart.yearPillar != null)
          .length,
      samplesWithoutHourPillar: sampleResults
          .where((result) => result.chart.hourPillar == null)
          .length,
      unknownBirthTimeSamples: profiles
          .where((profile) =>
              profile.birthTimeAccuracy == BirthTimeAccuracy.unknown)
          .length,
      dependencyUnavailableSamples: sampleResults
          .where((result) =>
              result.chart.status == BaziTrialStatus.dependencyUnavailable)
          .length,
      dependencyWarnings: List.unmodifiable(dependencyWarnings),
      observationIssues: List.unmodifiable(observationIssues),
    );
  }
}

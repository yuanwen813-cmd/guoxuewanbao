import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/features/v2/natal_inference_engine.dart';
import 'package:guoxueapp/features/v2/natal_profile_models.dart';

void main() {
  group('NatalInferenceEngine', () {
    test('generates complete local natal report from accurate birth profile',
        () {
      final profile = _profile(
        birthTimeAccuracy: BirthTimeAccuracy.accurate,
        birthDateTime: DateTime(1990, 6, 18, 5, 30),
      );

      final report = const NatalInferenceEngine().generate(
        profile,
        asOf: DateTime(2026, 6, 29),
      );

      expect(report.yearPillar.displayText, isNotEmpty);
      expect(report.monthPillar.displayText, isNotEmpty);
      expect(report.dayPillar.displayText, isNotEmpty);
      expect(report.hourPillar, isNotNull);
      expect(report.hourPillar!.displayText, isNotEmpty);
      expect(report.zodiac, isNotEmpty);
      expect(report.fiveElementSummary, contains('五行分布'));
      expect(report.dayMaster, contains('日主'));
      expect(report.lifeOverview, hasLength(greaterThanOrEqualTo(4)));
      expect(report.annualFortunes, hasLength(5));
      expect(report.monthlyFortunes, hasLength(12));
      expect(report.tiebanReference.sequenceCandidates, hasLength(3));
    });

    test('uses lichun boundary for year pillar', () {
      final beforeLichun = const NatalInferenceEngine().generate(
        _profile(
          birthTimeAccuracy: BirthTimeAccuracy.accurate,
          birthDateTime: DateTime(2017, 2, 3, 23, 33),
        ),
        asOf: DateTime(2026, 1, 1),
      );
      final afterLichun = const NatalInferenceEngine().generate(
        _profile(
          birthTimeAccuracy: BirthTimeAccuracy.accurate,
          birthDateTime: DateTime(2017, 2, 3, 23, 34),
        ),
        asOf: DateTime(2026, 1, 1),
      );
      final nextDay = const NatalInferenceEngine().generate(
        _profile(
          birthTimeAccuracy: BirthTimeAccuracy.accurate,
          birthDateTime: DateTime(2017, 2, 4),
        ),
        asOf: DateTime(2026, 1, 1),
      );

      expect(beforeLichun.yearPillar.displayText, '丙申');
      expect(beforeLichun.monthPillar.displayText, '辛丑');
      expect(beforeLichun.monthPillar.branch.chinese, '丑');
      expect(afterLichun.yearPillar.displayText, '丁酉');
      expect(afterLichun.monthPillar.displayText, '壬寅');
      expect(afterLichun.monthPillar.branch.chinese, '寅');
      expect(nextDay.yearPillar.displayText, '丁酉');
      expect(nextDay.monthPillar.displayText, '壬寅');
      expect(nextDay.monthPillar.branch.chinese, '寅');
    });

    test('generates verified pillars for 1984 fixed sample', () {
      final report = const NatalInferenceEngine().generate(
        BirthProfile.create(
          displayName: '1984 样本',
          relationship: BirthRelationship.self,
          gender: BirthGender.male,
          gregorianBirthDateTime: DateTime(1984, 8, 13, 6),
          birthTimeAccuracy: BirthTimeAccuracy.accurate,
        ),
        asOf: DateTime(2026, 6, 29),
      );

      expect(report.yearPillar.displayText, '甲子');
      expect(report.monthPillar.displayText, '壬申');
      expect(report.dayPillar.displayText, '己卯');
      expect(report.hourPillar, isNotNull);
      expect(report.hourPillar!.displayText, '丁卯');
    });

    test('generates verified pillars for 2017 Jinan sample', () {
      final report = const NatalInferenceEngine().generate(
        BirthProfile.create(
          displayName: '济南样本',
          relationship: BirthRelationship.self,
          gender: BirthGender.female,
          gregorianBirthDateTime: DateTime(2017, 1, 29, 9, 22),
          birthTimeAccuracy: BirthTimeAccuracy.accurate,
          birthPlaceName: '山东济南',
        ),
        asOf: DateTime(2026, 6, 29),
      );

      expect(report.yearPillar.displayText, '丙申');
      expect(report.monthPillar.displayText, '辛丑');
      expect(report.dayPillar.displayText, '丙辰');
      expect(report.hourPillar, isNotNull);
      expect(report.hourPillar!.displayText, '癸巳');
      expect(report.zodiac, '猴');
      expect(report.dayMaster, contains('丙日主'));
      expect(report.dayMaster, contains('火'));
      expect(report.fiveElementSummary, contains('木0、火3、土2、金2、水1'));
      expect(report.fiveElementSummary, contains('五行分布'));
      expect(report.hourPillar!.basis, contains('北京时间'));
    });

    test('uses Beijing hour boundaries and does not enable midnight day switch',
        () {
      final samples = {
        DateTime(2017, 1, 29, 8, 59): '壬辰',
        DateTime(2017, 1, 29, 9): '癸巳',
        DateTime(2017, 1, 29, 10, 59): '癸巳',
        DateTime(2017, 1, 29, 11): '甲午',
        DateTime(2017, 1, 29, 22, 59): '己亥',
        DateTime(2017, 1, 29, 23): '戊子',
      };

      for (final entry in samples.entries) {
        final report = const NatalInferenceEngine().generate(
          _profile(
            birthTimeAccuracy: BirthTimeAccuracy.accurate,
            birthDateTime: entry.key,
          ),
          asOf: DateTime(2026, 6, 29),
        );
        expect(report.hourPillar!.displayText, entry.value);
      }

      final beforeZi = const NatalInferenceEngine().generate(
        _profile(
          birthTimeAccuracy: BirthTimeAccuracy.accurate,
          birthDateTime: DateTime(2017, 1, 29, 22, 59),
        ),
        asOf: DateTime(2026, 6, 29),
      );
      final afterZi = const NatalInferenceEngine().generate(
        _profile(
          birthTimeAccuracy: BirthTimeAccuracy.accurate,
          birthDateTime: DateTime(2017, 1, 29, 23),
        ),
        asOf: DateTime(2026, 6, 29),
      );

      expect(afterZi.dayPillar.displayText, beforeZi.dayPillar.displayText);
      expect(afterZi.hourPillar!.displayText,
          isNot(beforeZi.hourPillar!.displayText));
      expect(
        afterZi.notes.join('\n'),
        contains('当前不启用子初换日'),
      );
    });

    test('uncovered solar term year is explicit trial approximation', () {
      final report = const NatalInferenceEngine().generate(
        _profile(
          birthTimeAccuracy: BirthTimeAccuracy.accurate,
          birthDateTime: DateTime(2026, 2, 3, 23),
        ),
        asOf: DateTime(2026, 6, 29),
      );

      expect(report.notes.join('\n'), contains('尚未覆盖 2026 年立春时刻'));
      expect(report.notes.join('\n'), contains('试运行近似边界'));
      expect(report.notes.join('\n'), isNot(contains('正式准确排盘')));
    });

    test('unknown birth time keeps report usable and asks to supplement hour',
        () {
      final report = const NatalInferenceEngine().generate(
        _profile(
          birthTimeAccuracy: BirthTimeAccuracy.unknown,
          birthDateTime: DateTime(1990, 6, 18),
        ),
        asOf: DateTime(2026, 6, 29),
      );

      expect(report.hourPillar, isNull);
      expect(report.pillarSummary, contains('时柱需补充出生时间'));
      expect(report.notes, contains(NatalInferenceEngine.unknownBirthTimeNote));
      expect(report.fiveElementSummary, contains('时柱未纳入统计'));
    });

    test('builds AI context with bazi annual monthly and tieban information',
        () {
      final report = const NatalInferenceEngine().generate(
        _profile(
          birthTimeAccuracy: BirthTimeAccuracy.accurate,
          birthDateTime: DateTime(1990, 6, 18, 5, 30),
        ),
        asOf: DateTime(2026, 6, 29),
      );

      final context = report.buildAiContext(questionFocus: '事业选择');

      expect(context, contains('用户关注：事业选择'));
      expect(context, contains('四柱：'));
      expect(context, contains('流年：'));
      expect(context, contains('月度：'));
      expect(context, contains('铁板神数参考：'));
    });
  });
}

BirthProfile _profile({
  required BirthTimeAccuracy birthTimeAccuracy,
  required DateTime birthDateTime,
}) {
  return BirthProfile.create(
    displayName: '测试档案',
    relationship: BirthRelationship.self,
    gender: BirthGender.male,
    gregorianBirthDateTime: birthDateTime,
    birthTimeAccuracy: birthTimeAccuracy,
    birthPlaceName: '杭州',
    lunarBirthDateText: '庚午年五月廿六',
  );
}

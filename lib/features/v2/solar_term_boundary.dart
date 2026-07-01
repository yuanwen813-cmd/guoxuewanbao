import '../../domain/calendar/ganzhi.dart';
import 'solar_term_time_table.dart';

class SolarTermBoundaryResult {
  final DateTime beijingDateTime;
  final int ganzhiYear;
  final DiZhi monthBranch;
  final SolarTermMoment? yearBoundary;
  final SolarTermMoment? monthBoundary;
  final bool usedApproximation;
  final List<String> notes;

  const SolarTermBoundaryResult({
    required this.beijingDateTime,
    required this.ganzhiYear,
    required this.monthBranch,
    required this.yearBoundary,
    required this.monthBoundary,
    required this.usedApproximation,
    required this.notes,
  });

  bool get isFullyCovered => !usedApproximation;
}

class SolarTermBoundaryResolver {
  final SolarTermTimeTable table;

  const SolarTermBoundaryResolver({
    this.table = const SolarTermTimeTable(),
  });

  SolarTermBoundaryResult resolve(DateTime beijingDateTime) {
    final yearBoundary =
        table.moment(beijingDateTime.year, SolarTermMonthStart.liChun);
    final yearApproximationUsed = yearBoundary == null;
    final ganzhiYear = yearBoundary == null
        ? _approximateGanzhiYear(beijingDateTime)
        : beijingDateTime.isBefore(yearBoundary.beijingDateTime)
            ? beijingDateTime.year - 1
            : beijingDateTime.year;

    final monthResolution = _resolveMonthBranch(beijingDateTime);
    final notes = <String>[
      '默认按北京时间 UTC+8 排盘。',
      '暂不启用真太阳时，也不按出生地经度修正时间。',
      '当前不启用子初换日；23:00 只进入子时，不改变日柱日期。',
      if (yearBoundary != null)
        '年柱按 ${yearBoundary.term.label} ${yearBoundary.displayText} 切换。'
      else
        '本地节气时刻表尚未覆盖 ${beijingDateTime.year} 年立春时刻，年柱仅按本地试运行近似边界展示，不作为精确排盘依据。',
      if (monthResolution.boundary != null)
        '月柱按 ${monthResolution.boundary!.term.label} ${monthResolution.boundary!.displayText} 进入${monthResolution.monthBranch.chinese}月。'
      else
        '本地节气时刻表尚未覆盖当前日期所需节令边界，月柱仅按本地试运行近似边界展示，不作为精确排盘依据。',
    ];

    return SolarTermBoundaryResult(
      beijingDateTime: beijingDateTime,
      ganzhiYear: ganzhiYear,
      monthBranch: monthResolution.monthBranch,
      yearBoundary: yearBoundary,
      monthBoundary: monthResolution.boundary,
      usedApproximation:
          yearApproximationUsed || monthResolution.usedApproximation,
      notes: notes,
    );
  }

  _MonthBranchResolution _resolveMonthBranch(DateTime beijingDateTime) {
    final candidates = [
      ...table.momentsForYear(beijingDateTime.year - 1),
      ...table.momentsForYear(beijingDateTime.year),
    ]..sort((a, b) => a.beijingDateTime.compareTo(b.beijingDateTime));

    SolarTermMoment? latest;
    for (final candidate in candidates) {
      if (!candidate.beijingDateTime.isAfter(beijingDateTime)) {
        latest = candidate;
      }
    }

    if (latest != null) {
      return _MonthBranchResolution(
        monthBranch: latest.term.monthBranch,
        boundary: latest,
        usedApproximation: false,
      );
    }

    return _MonthBranchResolution(
      monthBranch: _approximateMonthBranch(beijingDateTime),
      boundary: null,
      usedApproximation: true,
    );
  }

  int _approximateGanzhiYear(DateTime date) {
    final fixedBoundary = DateTime(date.year, 2, 4);
    return date.isBefore(fixedBoundary) ? date.year - 1 : date.year;
  }

  DiZhi _approximateMonthBranch(DateTime date) {
    const startDays = {
      1: 6,
      2: 4,
      3: 6,
      4: 5,
      5: 6,
      6: 6,
      7: 7,
      8: 8,
      9: 8,
      10: 8,
      11: 7,
      12: 7,
    };
    const branchByMonthStart = {
      1: DiZhi.chou,
      2: DiZhi.yin,
      3: DiZhi.mao,
      4: DiZhi.chen,
      5: DiZhi.si,
      6: DiZhi.wu,
      7: DiZhi.wei,
      8: DiZhi.shen,
      9: DiZhi.you,
      10: DiZhi.xu,
      11: DiZhi.hai,
      12: DiZhi.zi,
    };

    final startDay = startDays[date.month]!;
    if (date.day >= startDay) {
      return branchByMonthStart[date.month]!;
    }
    final previousMonth = date.month == 1 ? 12 : date.month - 1;
    return branchByMonthStart[previousMonth]!;
  }
}

class _MonthBranchResolution {
  final DiZhi monthBranch;
  final SolarTermMoment? boundary;
  final bool usedApproximation;

  const _MonthBranchResolution({
    required this.monthBranch,
    required this.boundary,
    required this.usedApproximation,
  });
}

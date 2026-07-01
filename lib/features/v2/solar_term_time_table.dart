import '../../domain/calendar/ganzhi.dart';

enum SolarTermMonthStart {
  xiaoHan('小寒', DiZhi.chou),
  liChun('立春', DiZhi.yin),
  jingZhe('惊蛰', DiZhi.mao),
  qingMing('清明', DiZhi.chen),
  liXia('立夏', DiZhi.si),
  mangZhong('芒种', DiZhi.wu),
  xiaoShu('小暑', DiZhi.wei),
  liQiu('立秋', DiZhi.shen),
  baiLu('白露', DiZhi.you),
  hanLu('寒露', DiZhi.xu),
  liDong('立冬', DiZhi.hai),
  daXue('大雪', DiZhi.zi);

  final String label;
  final DiZhi monthBranch;

  const SolarTermMonthStart(this.label, this.monthBranch);
}

class SolarTermMoment {
  final int year;
  final SolarTermMonthStart term;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final String sourceNote;
  final bool manuallyVerified;

  const SolarTermMoment({
    required this.year,
    required this.term,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.sourceNote,
    required this.manuallyVerified,
  });

  DateTime get beijingDateTime => DateTime(year, month, day, hour, minute);

  String get displayText {
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '$year-$m-$d $h:$min（北京时间）';
  }
}

class SolarTermTimeTable {
  const SolarTermTimeTable();

  static const localVerificationSource =
      '本地验收样本表，仅覆盖当前命盘本地测试所需年份；上线前需以权威节气时刻表全量复核。';

  static const List<SolarTermMoment> moments = [
    SolarTermMoment(
      year: 1984,
      term: SolarTermMonthStart.xiaoHan,
      month: 1,
      day: 6,
      hour: 5,
      minute: 40,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 1984,
      term: SolarTermMonthStart.liChun,
      month: 2,
      day: 4,
      hour: 23,
      minute: 19,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 1984,
      term: SolarTermMonthStart.jingZhe,
      month: 3,
      day: 5,
      hour: 17,
      minute: 25,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 1984,
      term: SolarTermMonthStart.qingMing,
      month: 4,
      day: 4,
      hour: 22,
      minute: 22,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 1984,
      term: SolarTermMonthStart.liXia,
      month: 5,
      day: 5,
      hour: 15,
      minute: 51,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 1984,
      term: SolarTermMonthStart.mangZhong,
      month: 6,
      day: 5,
      hour: 20,
      minute: 9,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 1984,
      term: SolarTermMonthStart.xiaoShu,
      month: 7,
      day: 7,
      hour: 6,
      minute: 29,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 1984,
      term: SolarTermMonthStart.liQiu,
      month: 8,
      day: 7,
      hour: 16,
      minute: 18,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 1984,
      term: SolarTermMonthStart.baiLu,
      month: 9,
      day: 7,
      hour: 19,
      minute: 10,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 1984,
      term: SolarTermMonthStart.hanLu,
      month: 10,
      day: 8,
      hour: 10,
      minute: 43,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 1984,
      term: SolarTermMonthStart.liDong,
      month: 11,
      day: 7,
      hour: 13,
      minute: 46,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 1984,
      term: SolarTermMonthStart.daXue,
      month: 12,
      day: 7,
      hour: 6,
      minute: 28,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 2017,
      term: SolarTermMonthStart.xiaoHan,
      month: 1,
      day: 5,
      hour: 11,
      minute: 55,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 2017,
      term: SolarTermMonthStart.liChun,
      month: 2,
      day: 3,
      hour: 23,
      minute: 34,
      sourceNote: '用户验收指定：2017 年立春按北京时间 2017-02-03 23:34。',
      manuallyVerified: true,
    ),
    SolarTermMoment(
      year: 2017,
      term: SolarTermMonthStart.jingZhe,
      month: 3,
      day: 5,
      hour: 17,
      minute: 32,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 2017,
      term: SolarTermMonthStart.qingMing,
      month: 4,
      day: 4,
      hour: 22,
      minute: 17,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 2017,
      term: SolarTermMonthStart.liXia,
      month: 5,
      day: 5,
      hour: 15,
      minute: 31,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 2017,
      term: SolarTermMonthStart.mangZhong,
      month: 6,
      day: 5,
      hour: 19,
      minute: 36,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 2017,
      term: SolarTermMonthStart.xiaoShu,
      month: 7,
      day: 7,
      hour: 5,
      minute: 51,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 2017,
      term: SolarTermMonthStart.liQiu,
      month: 8,
      day: 7,
      hour: 15,
      minute: 40,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 2017,
      term: SolarTermMonthStart.baiLu,
      month: 9,
      day: 7,
      hour: 18,
      minute: 38,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 2017,
      term: SolarTermMonthStart.hanLu,
      month: 10,
      day: 8,
      hour: 10,
      minute: 22,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 2017,
      term: SolarTermMonthStart.liDong,
      month: 11,
      day: 7,
      hour: 13,
      minute: 38,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
    SolarTermMoment(
      year: 2017,
      term: SolarTermMonthStart.daXue,
      month: 12,
      day: 7,
      hour: 6,
      minute: 32,
      sourceNote: localVerificationSource,
      manuallyVerified: false,
    ),
  ];

  SolarTermMoment? moment(int year, SolarTermMonthStart term) {
    for (final item in moments) {
      if (item.year == year && item.term == term) {
        return item;
      }
    }
    return null;
  }

  List<SolarTermMoment> momentsForYear(int year) {
    final result = moments.where((item) => item.year == year).toList()
      ..sort((a, b) => a.beijingDateTime.compareTo(b.beijingDateTime));
    return result;
  }

  List<int> get coveredYears {
    final years = moments.map((item) => item.year).toSet().toList()..sort();
    return years;
  }
}

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// 农历月数据
class LunarMonthData {
  final int month;
  final int days;
  final bool isLeap;
  const LunarMonthData({required this.month, required this.days, this.isLeap = false});
  factory LunarMonthData.fromJson(Map<String, dynamic> j) => LunarMonthData(
    month: j['month'] as int, days: j['days'] as int, isLeap: j['isLeap'] as bool? ?? false,
  );
}

/// 单年农历数据
class LunarYearData {
  final int year;
  final DateTime lunarNewYearGregorian;
  final int? leapMonth;
  final List<LunarMonthData> months;
  final String source;
  const LunarYearData({required this.year, required this.lunarNewYearGregorian, this.leapMonth, this.months=const[], this.source=''});
  factory LunarYearData.fromJson(Map<String, dynamic> j) => LunarYearData(
    year: j['year'] as int,
    lunarNewYearGregorian: DateTime.parse(j['lunarNewYearGregorian'] as String),
    leapMonth: j['leapMonth'] as int?,
    months: (j['months'] as List?)?.map((m) => LunarMonthData.fromJson(m as Map<String, dynamic>)).toList() ?? [],
    source: j['source'] as String? ?? '',
  );
}

/// 数据表加载结果
class LunarDataTableLoadResult {
  final bool available;
  final bool productionReady;
  final String schemaVersion;
  final int? supportedStartYear;
  final int? supportedEndYear;
  final Map<int, LunarYearData> years;
  final List<String> warnings;
  final List<String> errors;

  const LunarDataTableLoadResult({
    this.available=false, this.productionReady=false, this.schemaVersion='',
    this.supportedStartYear, this.supportedEndYear, this.years=const {},
    this.warnings=const [], this.errors=const [],
  });

  static const unavailable = LunarDataTableLoadResult(errors: ['无可用农历数据表']);

  Map<String, dynamic> toJson() => {
    'available': available, 'productionReady': productionReady,
    'schemaVersion': schemaVersion, 'supportedStartYear': supportedStartYear,
    'supportedEndYear': supportedEndYear, 'yearCount': years.length,
    'warnings': warnings, 'errors': errors,
  };
}

/// 农历数据表加载器
class LunarDataTableLoader {
  static const _assetPath = 'assets/data/calendar/lunar_data.json';

  Future<LunarDataTableLoadResult> load() async {
    try {
      final raw = await rootBundle.loadString(_assetPath);
      if (raw.trim().isEmpty) return const LunarDataTableLoadResult(errors: ['lunar_data.json 为空']);
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final productionReady = json['productionReady'] as bool? ?? false;
      final schemaVersion = json['schemaVersion'] as String? ?? '';
      final startYear = json['supportedStartYear'] as int?;
      final endYear = json['supportedEndYear'] as int?;

      if (!productionReady) {
        return LunarDataTableLoadResult(
          schemaVersion: schemaVersion, productionReady: false,
          supportedStartYear: startYear, supportedEndYear: endYear,
          errors: ['productionReady=false，数据表未就绪'],
        );
      }

      final yearsList = json['years'] as List? ?? [];
      final years = <int, LunarYearData>{};
      for (final y in yearsList) {
        final yd = LunarYearData.fromJson(y as Map<String, dynamic>);
        years[yd.year] = yd;
      }

      return LunarDataTableLoadResult(
        available: true, productionReady: true, schemaVersion: schemaVersion,
        supportedStartYear: startYear, supportedEndYear: endYear, years: years,
      );
    } catch (e) {
      return LunarDataTableLoadResult(errors: ['加载失败：$e']);
    }
  }
}

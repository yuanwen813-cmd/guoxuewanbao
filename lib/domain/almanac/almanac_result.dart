import 'almanac_day.dart';

/// 黄历查询结果
class AlmanacResult {
  final AlmanacDay today;
  final AlmanacDay? tomorrow;
  final AlmanacDay? yesterday;

  const AlmanacResult({
    required this.today,
    this.tomorrow,
    this.yesterday,
  });

  Map<String, dynamic> toJson() => {
    'method': 'almanac',
    'today': today.toJson(),
    if (tomorrow != null) 'tomorrow': tomorrow!.toJson(),
    if (yesterday != null) 'yesterday': yesterday!.toJson(),
  };
}

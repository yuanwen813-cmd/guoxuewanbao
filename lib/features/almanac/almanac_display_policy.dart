import '../../domain/calendar/calendar_models.dart';

/// 单字段展示视图
class AlmanacFieldView {
  final String key;
  final String label;
  final bool available;
  final String displayText;
  final String? reason;
  final String source;

  const AlmanacFieldView({
    required this.key, required this.label, required this.available,
    required this.displayText, this.reason, this.source = '',
  });

  Map<String, dynamic> toJson() => {
    'key': key, 'label': label, 'available': available,
    'displayText': displayText, 'reason': reason, 'source': source,
  };
}

/// 黄历页面展示状态
class AlmanacDisplayState {
  final String dateText;
  final String weekdayText;
  final AlmanacFieldView lunar;
  final AlmanacFieldView ganzhi;
  final AlmanacFieldView zodiac;
  final AlmanacFieldView solarTerm;
  final AlmanacFieldView clash;
  final List<String> betaNotices;
  final List<String> warnings;
  final List<String> visibleFieldKeys;
  final Map<String, String> unavailableReasons;

  const AlmanacDisplayState({
    required this.dateText, required this.weekdayText,
    required this.lunar, required this.ganzhi, required this.zodiac,
    required this.solarTerm, required this.clash,
    required this.betaNotices, required this.warnings,
    required this.visibleFieldKeys, required this.unavailableReasons,
  });

  Map<String, dynamic> toJson() => {
    'visibleFields': visibleFieldKeys,
    'unavailableFields': unavailableReasons,
    'fields': {
      'lunar': lunar.toJson(), 'ganzhi': ganzhi.toJson(),
      'zodiac': zodiac.toJson(), 'solarTerm': solarTerm.toJson(), 'clash': clash.toJson(),
    },
  };
}

/// 黄历展示策略 — 基于 CalendarProvider capabilities 决定展示什么
///
/// v0.17 更新：
/// - 农历从 CalendarProvider 读取真实数据并展示
/// - 生肖、干支、节气、冲煞仍标记 unavailable
class AlmanacDisplayPolicy {
  const AlmanacDisplayPolicy();
  static const _betaNotice = '当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。';
  static const _unavailableGanzhi = '干支能力未启用（v0.17 仅开放农历展示）';
  static const _unavailableZodiac = '生肖能力未启用（v0.17 仅开放农历展示）';
  static const _unavailableSolarTerm = '节气能力未启用（v0.17 仅开放农历展示）';
  static const _unavailableClash = '冲煞能力未启用（v0.17 仅开放农历展示）';

  AlmanacDisplayState build(CalendarDayInfo day) {
    final visible = <String>['gregorianDate', 'weekday', 'yi', 'ji', 'dailyAdvice'];
    final unavailable = <String, String>{};

    // v0.17: lunar date from CalendarProvider
    final lunar = _field('lunar', '农历', day.lunar.available, day.lunar.displayText,
        day.lunar.available ? null : '农历信息暂未启用', day.source);
    if (day.lunar.available) {
      visible.add('lunarDate');
    } else {
      unavailable['lunarDate'] = '农历信息暂未启用';
    }

    final ganzhi = _field('ganzhi', '干支', day.ganzhi.available, day.ganzhi.displayText,
        day.ganzhi.available ? null : _unavailableGanzhi, day.source);
    if (!ganzhi.available) unavailable['ganzhi'] = _unavailableGanzhi;

    final zodiac = _field('zodiac', '生肖', day.zodiac.available, day.zodiac.displayText,
        day.zodiac.available ? null : _unavailableZodiac, day.source);
    if (!zodiac.available) unavailable['zodiac'] = _unavailableZodiac;

    final solarTerm = _field('solarTerm', '节气', day.solarTerm.available, day.solarTerm.displayText,
        day.solarTerm.available ? null : _unavailableSolarTerm, day.source);
    if (!solarTerm.available) unavailable['solarTerm'] = _unavailableSolarTerm;

    final clash = _field('clash', '冲煞', day.clash.available, day.clash.displayText,
        day.clash.available ? null : _unavailableClash, day.source);
    if (!clash.available) unavailable['clash'] = _unavailableClash;

    return AlmanacDisplayState(
      dateText: day.gregorianDate, weekdayText: day.weekday,
      lunar: lunar, ganzhi: ganzhi, zodiac: zodiac, solarTerm: solarTerm, clash: clash,
      betaNotices: const [_betaNotice],
      warnings: day.warnings,
      visibleFieldKeys: visible,
      unavailableReasons: unavailable,
    );
  }

  AlmanacFieldView _field(String key, String label, bool available, String display,
      String? reason, String source) {
    return AlmanacFieldView(key: key, label: label, available: available,
        displayText: display, reason: reason, source: source);
  }
}

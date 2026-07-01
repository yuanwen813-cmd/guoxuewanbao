/// 历法数据模型 — 统一历法底座
/// 原则：能准确计算的才标记 available=true，否则 honestly unavailable

class CalendarDayInfo {
  final String dateKey;        // yyyyMMdd
  final String gregorianDate;  // "2026年6月22日"
  final String timezone;       // "Asia/Shanghai"
  final String weekday;        // "星期一"
  final LunarDate lunar;
  final GanzhiInfo ganzhi;
  final ZodiacInfo zodiac;
  final SolarTermInfo solarTerm;
  final ClashInfo clash;
  final Map<String, String> dataQuality;
  final String source;
  final List<String> warnings;

  const CalendarDayInfo({
    required this.dateKey, required this.gregorianDate, required this.timezone,
    required this.weekday, required this.lunar, required this.ganzhi,
    required this.zodiac, required this.solarTerm, required this.clash,
    required this.dataQuality, required this.source, this.warnings = const [],
  });

  Map<String, dynamic> toJson() => {
    'dateKey': dateKey, 'gregorianDate': gregorianDate, 'timezone': timezone,
    'weekday': weekday,
    'lunar': lunar.toJson(), 'ganzhi': ganzhi.toJson(), 'zodiac': zodiac.toJson(),
    'solarTerm': solarTerm.toJson(), 'clash': clash.toJson(),
    'dataQuality': dataQuality, 'source': source, 'warnings': warnings,
  };
}

class LunarDate {
  final bool available;
  final int lunarYear;
  final int lunarMonth;
  final int lunarDay;
  final bool isLeapMonth;
  final String displayText;

  const LunarDate({this.available=false, this.lunarYear=0, this.lunarMonth=0, this.lunarDay=0,
    this.isLeapMonth=false, this.displayText='农历信息暂未启用'});

  static const unavailable = LunarDate();
  Map<String, dynamic> toJson() => {'available':available,'lunarYear':lunarYear,'lunarMonth':lunarMonth,'lunarDay':lunarDay,'isLeapMonth':isLeapMonth,'displayText':displayText};
}

class GanzhiInfo {
  final bool available;
  final String yearGanzhi;
  final String monthGanzhi;
  final String dayGanzhi;
  final bool hourGanzhiSupported;
  final Map<String, String> basis;
  final String displayText;

  const GanzhiInfo({this.available=false, this.yearGanzhi='',this.monthGanzhi='',this.dayGanzhi='',
    this.hourGanzhiSupported=false, this.basis=const {}, this.displayText='干支信息暂未启用'});

  static const unavailable = GanzhiInfo();
  Map<String, dynamic> toJson() => {'available':available,'yearGanzhi':yearGanzhi,'monthGanzhi':monthGanzhi,'dayGanzhi':dayGanzhi,'hourGanzhiSupported':hourGanzhiSupported,'basis':basis,'displayText':displayText};
}

class ZodiacInfo {
  final bool available;
  final String zodiac;
  final int? lunarYear;
  final String basis;
  final String displayText;
  final String source;
  final String status; // full | unavailable

  const ZodiacInfo({
    this.available=false,
    this.zodiac='',
    this.lunarYear,
    this.basis='unavailable',
    this.displayText='生肖信息暂未启用',
    this.source='',
    this.status='unavailable',
  });

  static const unavailable = ZodiacInfo();
  Map<String, dynamic> toJson() => {
    'available':available,
    'zodiacName':zodiac,
    if (lunarYear != null) 'lunarYear': lunarYear,
    'basis':basis,
    'displayText':displayText,
    'source':source,
    'status':status,
  };
}

class SolarTermInfo {
  final bool available;
  final String currentTerm;
  final String currentTermDate;
  final String nextTerm;
  final String nextTermDate;
  final bool isTermDay;
  final String termOfDay;
  final String basis;
  final String displayText;

  const SolarTermInfo({this.available=false, this.currentTerm='',this.currentTermDate='',this.nextTerm='',
    this.nextTermDate='',this.isTermDay=false,this.termOfDay='',this.basis='unavailable',this.displayText='节气信息暂未启用'});

  static const unavailable = SolarTermInfo();
  Map<String, dynamic> toJson() => {'available':available,'currentTerm':currentTerm,'currentTermDate':currentTermDate,'nextTerm':nextTerm,'nextTermDate':nextTermDate,'isTermDay':isTermDay,'termOfDay':termOfDay,'basis':basis,'displayText':displayText};
}

class ClashInfo {
  final bool available;
  final String dayBranch;
  final String clashZodiac;
  final String shaDirection;
  final String displayText;

  const ClashInfo({this.available=false, this.dayBranch='',this.clashZodiac='',this.shaDirection='', this.displayText='冲煞信息暂未启用'});

  static const unavailable = ClashInfo();
  Map<String, dynamic> toJson() => {'available':available,'dayBranch':dayBranch,'clashZodiac':clashZodiac,'shaDirection':shaDirection,'displayText':displayText};
}

/// Provider 能力声明
class CalendarProviderCapabilities {
  final String lunarDate;    // full | partial | unavailable
  final String yearGanzhi;
  final String monthGanzhi;
  final String dayGanzhi;
  final String zodiac;
  final String solarTerm;
  final String clash;
  final Map<String, String> supportedDateRange;
  final String source;
  final List<String> notes;

  const CalendarProviderCapabilities({
    this.lunarDate='unavailable', this.yearGanzhi='unavailable', this.monthGanzhi='unavailable',
    this.dayGanzhi='unavailable', this.zodiac='unavailable', this.solarTerm='unavailable',
    this.clash='unavailable', this.supportedDateRange=const {}, this.source='local_stub',
    this.notes=const [],
  });

  Map<String, dynamic> toJson() => {
    'lunarDate':lunarDate,'yearGanzhi':yearGanzhi,'monthGanzhi':monthGanzhi,'dayGanzhi':dayGanzhi,
    'zodiac':zodiac,'solarTerm':solarTerm,'clash':clash,
    'supportedDateRange':supportedDateRange,'source':source,'notes':notes,
  };
}

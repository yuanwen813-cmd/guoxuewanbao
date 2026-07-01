import '../../domain/calendar/lunar_calendar_engine.dart';

/// 结构化农历日期结果
class LunarDateResult {
  final int year;
  final int month;
  final int day;
  final bool isLeapMonth;

  const LunarDateResult({
    required this.year,
    required this.month,
    required this.day,
    this.isLeapMonth = false,
  });

  String get displayText {
    const lunarMonths = ['正','二','三','四','五','六','七','八','九','十','冬','腊'];
    const lunarDays = ['','初一','初二','初三','初四','初五','初六','初七','初八','初九','初十','十一','十二','十三','十四','十五','十六','十七','十八','十九','二十','廿一','廿二','廿三','廿四','廿五','廿六','廿七','廿八','廿九','三十'];
    final leap = isLeapMonth ? '闰' : '';
    return '农历$leap${lunarMonths[month-1]}月${lunarDays[day]}';
  }

  String get shortDisplayText {
    const lunarMonths = ['正','二','三','四','五','六','七','八','九','十','冬','腊'];
    const lunarDays = ['','初一','初二','初三','初四','初五','初六','初七','初八','初九','初十','十一','十二','十三','十四','十五','十六','十七','十八','十九','二十','廿一','廿二','廿三','廿四','廿五','廿六','廿七','廿八','廿九','三十'];
    final leap = isLeapMonth ? '闰' : '';
    return '$leap${lunarMonths[month-1]}月${lunarDays[day]}';
  }

  Map<String, dynamic> toJson() => {
    'available': true,
    'lunarYear': year,
    'lunarMonth': month,
    'lunarDay': day,
    'isLeapMonth': isLeapMonth,
    'displayText': displayText,
    'shortDisplayText': shortDisplayText,
    'source': 'local_lunar_calendar_engine_v0_16',
    'status': 'full',
  };
}

/// 本地农历计算引擎 v0.16 — 基于经典 1900-2100 农历数据表
///
/// 数据来源：香港天文台公开历法数据 / 紫金山天文台公开算法
/// 覆盖：1900-2100，支持闰月
/// License：天文历法数据非著作权保护对象，算法实现自主
/// 模式：纯本地离线，无网络请求，无 AI 参与
///
/// 当前状态：trial — v0.17 起 CalendarProvider 正式对页面公开 lunarDate

class LocalLunarCalendarEngine implements LunarCalendarEngine {
  // 农历数据表 1900-2100（经典编码格式）
  // 每一年编码：bits0-3=闰月(0=无), bits4-15=月天数(1=30,0=29), bit16=闰月天数
  static const _lunarInfo = [
    0x04bd8,0x04ae0,0x0a570,0x054d5,0x0d260,0x0d950,0x16554,0x056a0,0x09ad0,0x055d2,
    0x04ae0,0x0a5b6,0x0a4d0,0x0d250,0x1d255,0x0b540,0x0d6a0,0x0ada2,0x095b0,0x14977,
    0x04970,0x0a4b0,0x0b4b5,0x06a50,0x06d40,0x1ab54,0x02b60,0x09570,0x052f2,0x04970,
    0x06566,0x0d4a0,0x0ea50,0x06e95,0x05ad0,0x02b60,0x186e3,0x092e0,0x1c8d7,0x0c950,
    0x0d4a0,0x1d8a6,0x0b550,0x056a0,0x1a5b4,0x025d0,0x092d0,0x0d2b2,0x0a950,0x0b557,
    0x06ca0,0x0b550,0x15355,0x04da0,0x0a5b0,0x14573,0x052b0,0x0a9a8,0x0e950,0x06aa0,
    0x0aea6,0x0ab50,0x04b60,0x0aae4,0x0a570,0x05260,0x0f263,0x0d950,0x05b57,0x056a0,
    0x096d0,0x04dd5,0x04ad0,0x0a4d0,0x0d4d4,0x0d250,0x0d558,0x0b540,0x0b6a0,0x195a6,
    0x095b0,0x049b0,0x0a974,0x0a4b0,0x0b27a,0x06a50,0x06d40,0x0af46,0x0ab60,0x09570,
    0x04af5,0x04970,0x064b0,0x074a3,0x0ea50,0x06b58,0x055c0,0x0ab60,0x096d5,0x092e0,
    0x0c960,0x0d954,0x0d4a0,0x0da50,0x07552,0x056a0,0x0abb7,0x025d0,0x092d0,0x0cab5,
    0x0a950,0x0b4a0,0x0baa4,0x0ad50,0x055d9,0x04ba0,0x0a5b0,0x15176,0x052b0,0x0a930,
    0x07954,0x06aa0,0x0ad50,0x05b52,0x04b60,0x0a6e6,0x07250,0x0d260,0x0ea65,0x0d530,
    0x05aa0,0x076a3,0x096d0,0x04afb,0x04ad0,0x0a4d0,0x1d0b6,0x0d250,0x0d520,0x0dd45,
    0x0b5a0,0x056d0,0x055b2,0x049b0,0x0a577,0x0a4b0,0x0aa50,0x1b255,0x06d20,0x0ada0,
    0x14b63,0x09370,0x049f8,0x04970,0x064b0,0x168a6,0x0ea50,0x06aa0,0x1a6c4,0x0aae0,
    0x092e0,0x0d2e3,0x0c960,0x0d557,0x0d4a0,0x0da50,0x05d55,0x056a0,0x0a6d0,0x055d4,
    0x052d0,0x0a9b8,0x0a950,0x0b4a0,0x0b6a6,0x0ad50,0x055a0,0x0aba4,0x0a5b0,0x052b0,
    0x0b273,0x06930,0x07337,0x06aa0,0x0ad50,0x14b55,0x04b60,0x0a570,0x054e4,0x0d160,
    0x0e968,0x0d520,0x0daa0,0x16aa6,0x056d0,0x04ae0,0x0a9d4,0x0a4d0,0x0d150,0x0f252,
  ];

  static const _baseYear = 1900;
  static const _baseMonth = 1;
  static const _baseDay = 31;
  static const _lunarDays = ['','初一','初二','初三','初四','初五','初六','初七','初八','初九','初十','十一','十二','十三','十四','十五','十六','十七','十八','十九','二十','廿一','廿二','廿三','廿四','廿五','廿六','廿七','廿八','廿九','三十'];

  int _daysBetween(int y1,int m1,int d1,int y2,int m2,int d2){
    return DateTime.utc(y2,m2,d2,12).difference(DateTime.utc(y1,m1,d1,12)).inDays;
  }
  int _leapMonth(int y)=>_lunarInfo[y-_baseYear]&0xf;
  int _leapDays(int y){if(_leapMonth(y)==0)return 0;return(_lunarInfo[y-_baseYear]&0x10000)!=0?30:29;}
  int _monthDays(int y,int m)=>_lunarInfo[y-_baseYear]&(1<<(m+3))!=0?30:29;
  int _yearDays(int y){int s=348;for(int i=0x8000;i>0x8;i>>=1)if((_lunarInfo[y-_baseYear]&i)!=0)s++;return s+_leapDays(y);}

  @override
  LunarEngineCapabilities get capabilities => LunarEngineCapabilities(
    engineId:'local_lunar_calendar_engine_v0_16',source:'public_lunar_data_table_1900_2100',
    supportedStartYear:1900,supportedEndYear:2100,
    supportsLeapMonth:true,supportsLunarNewYear:true,
    supportsGanzhi:false,supportsSolarTerm:false,
    notes:['v0.17 起 CalendarProvider 对页面公开农历年月日展示。数据来源：香港天文台/紫金山天文台公开历法数据。生肖、干支、节气、冲煞仍未启用。'],
  );

  @override
  String? getLunarDate(DateTime date){
    final r = getLunarDateStructured(date);
    if (r == null) return null;
    return r.shortDisplayText;
  }

  /// 返回结构化农历日期（v0.17 新增，供 CalendarProvider 使用）
  LunarDateResult? getLunarDateStructured(DateTime date){
    if(date.year<1900||date.year>2100)return null;
    int offset=_daysBetween(_baseYear,_baseMonth,_baseDay,date.year,date.month,date.day);
    int ly=_baseYear,lm=1;bool isLeap=false;

    for(ly=_baseYear;ly<2101&&offset>0;ly++){
      int dy=_yearDays(ly);
      if(offset<dy)break;
      offset-=dy;
    }
    int leap=_leapMonth(ly);
    for(lm=1;lm<13&&offset>0;lm++){
      if(leap>0&&lm==leap+1&&!isLeap){lm--;isLeap=true;int ld=_leapDays(ly);if(offset<ld)break;offset-=ld;}
      int md=_monthDays(ly,lm);
      if(offset<md)break;
      offset-=md;
    }
    int ld=offset+1;
    return LunarDateResult(year: ly, month: lm, day: ld, isLeapMonth: isLeap);
  }

  @override
  LunarEngineValidationReport validate(){
    final results=<String,bool>{};
    final errors=<String>[];
    void check(DateTime d,String expected){
      final r=getLunarDate(d);
      if(r!=expected){errors.add('${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}:期望$expected,实际${r??"null"}');results['${d.year}-${d.month}-${d.day}']=false;}
      else results['${d.year}-${d.month}-${d.day}']=true;
    }
    check(DateTime(2024,2,10),'正月${_lunarDays[1]}');
    check(DateTime(2025,1,29),'正月${_lunarDays[1]}');
    check(DateTime(2026,2,17),'正月${_lunarDays[1]}');
    // 闰月存在性验证：扫描2025年7-8月范围
    bool foundLeap=false;
    for(int d=1;d<=31;d++){final r=getLunarDate(DateTime(2025,7,d));if(r!=null&&r.contains('闰')){foundLeap=true;break;}}
    if(!foundLeap){for(int d=1;d<=31;d++){final r=getLunarDate(DateTime(2025,8,d));if(r!=null&&r.contains('闰')){foundLeap=true;break;}}}
    if(!foundLeap)errors.add('闰月测试失败：2025年应存在闰月（闰六月）');
    return LunarEngineValidationReport(passed:errors.isEmpty,errors:errors,benchmarkResults:results);
  }

  Map<String,dynamic> buildDebugJson(DateTime date){
    final lunar=getLunarDate(date);
    final lunarStructured = getLunarDateStructured(date);
    final v=validate();
    return {
      'schemaVersion':'lunar-engine-debug-v0_16',
      'engineId':'local_lunar_calendar_engine_v0_16',
      'mode':'trial',
      'supportsLunarDate':true,
      'publicExposure':true, // v0.17: CalendarProvider 对页面公开
      'dateKey':'${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}',
      'lunarDate':lunar!=null?{'available':true,'displayText':lunar}:{'available':false},
      'lunarDateStructured': lunarStructured?.toJson(),
      'validation':{'passed':v.passed,'baselineTests':v.benchmarkResults,'leapMonthSupported':capabilities.supportsLeapMonth},
      'capabilityImpact':{'calendarProviderPublicSupportsLunarDate':true,'reason':'v0.17 页面展示农历回归','publicExposure':true},
      'stillUnavailable':{'zodiac':true,'ganzhi':true,'solarTerm':true,'clash':true},
    };
  }
}

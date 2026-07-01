import '../../domain/calendar/calendar_models.dart';
import 'ganzhi_internal_engine.dart';
import 'clash_internal_engine.dart';
import 'day_ganzhi_clash_public_feature_flag.dart';
import 'day_ganzhi_internal_engine.dart';
import 'day_ganzhi_internal_feature_flag.dart';
import 'ganzhi_internal_feature_flag.dart';
import 'ganzhi_public_feature_flag.dart';
import 'local_lunar_calendar_engine.dart';
import 'solar_term_internal_feature_flag.dart';
import 'solar_term_public_feature_flag.dart';
import 'solar_term_trial_engine.dart';

/// 统一历法 Provider 接口
abstract class CalendarProvider {
  CalendarDayInfo getDayInfo(DateTime date, {String timezone = 'Asia/Shanghai'});
  CalendarProviderCapabilities getCapabilities();
}

/// 本地历法 Provider — v0.45 开发内测启用版
///
/// 当前能力：
/// - 公历日期 ✅ DateTime
/// - 星期 ✅ DateTime.weekday
/// - 农历 ✅ LocalLunarCalendarEngine v0.16
/// - 生肖 ✅ 基于 lunarYear 计算（v0.19 起启用）
/// - 干支 ❌ 无可靠算法 → unavailable
/// - 节气 🔬 internal flag 下受控可用（v0.45）
/// - 冲煞 ❌ 需日支 → unavailable
class LocalCalendarProvider implements CalendarProvider {
  static const _weekdays = ['星期一','星期二','星期三','星期四','星期五','星期六','星期日'];
  static const _zodiacs = ['鼠','牛','虎','兔','龙','蛇','马','羊','猴','鸡','狗','猪'];
  static const _zodiacBaseYear = 2020;

  final LocalLunarCalendarEngine _lunarEngine = LocalLunarCalendarEngine();
  final SolarTermTrialEngine _trialEngine = const SolarTermTrialEngine();

  /// 节气内部 feature flag（默认 production 关闭）
  SolarTermInternalFeatureFlag _solarTermFlag = SolarTermInternalFeatureFlag.defaultProduction;
  SolarTermPublicFeatureFlag _publicFlag = SolarTermPublicFeatureFlag.fullEnabled;

  void setSolarTermFlag(SolarTermInternalFeatureFlag flag) { _solarTermFlag = flag; }
  SolarTermInternalFeatureFlag get solarTermFlag => _solarTermFlag;

  void setPublicFlag(SolarTermPublicFeatureFlag flag) { _publicFlag = flag; }
  SolarTermPublicFeatureFlag get publicFlag => _publicFlag;

  final GanzhiInternalEngine _ganzhiEngine = const GanzhiInternalEngine();
  GanzhiInternalFeatureFlag _ganzhiFlag = GanzhiInternalFeatureFlag.defaultDisabled;

  void setGanzhiFlag(GanzhiInternalFeatureFlag flag) { _ganzhiFlag = flag; }
  GanzhiInternalFeatureFlag get ganzhiFlag => _ganzhiFlag;

  GanzhiPublicFeatureFlag _ganzhiPublicFlag = GanzhiPublicFeatureFlag.fullEnabled;
  void setGanzhiPublicFlag(GanzhiPublicFeatureFlag flag) { _ganzhiPublicFlag = flag; }
  GanzhiPublicFeatureFlag get ganzhiPublicFlag => _ganzhiPublicFlag;

  final DayGanzhiInternalEngine _dayGanzhiEngine = const DayGanzhiInternalEngine();
  final ClashInternalEngine _clashEngine = const ClashInternalEngine();
  DayGanzhiInternalFeatureFlag _dayGanzhiClashFlag = DayGanzhiInternalFeatureFlag.defaultDisabled;

  void setDayGanzhiClashFlag(DayGanzhiInternalFeatureFlag flag) { _dayGanzhiClashFlag = flag; }
  DayGanzhiInternalFeatureFlag get dayGanzhiClashFlag => _dayGanzhiClashFlag;

  DayGanzhiClashPublicFeatureFlag _dayGanzhiClashPublicFlag = DayGanzhiClashPublicFeatureFlag.fullEnabled;
  void setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag flag) { _dayGanzhiClashPublicFlag = flag; }
  DayGanzhiClashPublicFeatureFlag get dayGanzhiClashPublicFlag => _dayGanzhiClashPublicFlag;

  String? _computeZodiac(int lunarYear) {
    final index = ((lunarYear - _zodiacBaseYear) % 12 + 12) % 12;
    return _zodiacs[index];
  }

  @override
  CalendarProviderCapabilities getCapabilities() => CalendarProviderCapabilities(
    lunarDate: 'full',
    yearGanzhi: (_ganzhiPublicFlag.ganzhiPublicEnabled && _ganzhiPublicFlag.yearGanzhiEnabled && _ganzhiPublicFlag.sourceIsSafe) ? 'full' : (_ganzhiFlag.internalGanzhiAllowed ? 'internal' : 'unavailable'),
    monthGanzhi: (_ganzhiPublicFlag.ganzhiPublicEnabled && _ganzhiPublicFlag.monthGanzhiEnabled && _ganzhiPublicFlag.sourceIsSafe) ? 'full' : (_ganzhiFlag.internalGanzhiAllowed ? 'internal' : 'unavailable'),
    dayGanzhi: (_dayGanzhiClashPublicFlag.dayGanzhiPublicEnabled && _dayGanzhiClashPublicFlag.sourceIsSafe) ? 'full' : (_dayGanzhiClashFlag.internalDayGanzhiAllowed ? 'internal' : 'unavailable'),
    zodiac: 'full',
    solarTerm: (_publicFlag.solarTermPublicEnabled && _publicFlag.sourceIsSafe) ? 'full' : (_solarTermFlag.internalSolarTermAllowed ? 'internal' : 'unavailable'),
    clash: (_dayGanzhiClashPublicFlag.clashPublicEnabled && _dayGanzhiClashPublicFlag.sourceIsSafe) ? 'full' : (_dayGanzhiClashFlag.internalClashAllowed ? 'internal' : 'unavailable'),
    supportedDateRange: const {'start': '1900-01-01', 'end': '2100-12-31'},
    source: 'local_calendar_provider_v0_45',
    notes: [
      if (_solarTermFlag.internalSolarTermAllowed) 'v0.45 节气 internal 受控可用（debug/internal only）',
      '干支、冲煞仍未启用',
      '分享、snapshot 仍不含节气',
    ],
  );

  @override
  CalendarDayInfo getDayInfo(DateTime date, {String timezone = 'Asia/Shanghai'}) {
    final dk = '${date.year}${date.month.toString().padLeft(2,'0')}${date.day.toString().padLeft(2,'0')}';

    final lunarResult = _lunarEngine.getLunarDateStructured(date);
    final lunar = lunarResult != null
        ? LunarDate(available: true, lunarYear: lunarResult.year, lunarMonth: lunarResult.month, lunarDay: lunarResult.day, isLeapMonth: lunarResult.isLeapMonth, displayText: lunarResult.displayText)
        : LunarDate.unavailable;

    final zodiac = lunar.available
        ? ZodiacInfo(available: true, zodiac: _computeZodiac(lunar.lunarYear) ?? '', lunarYear: lunar.lunarYear, basis: 'derived_from_lunar_year', displayText: _computeZodiac(lunar.lunarYear) ?? '', source: 'derived_from_lunar_year_v0_19', status: 'full')
        : ZodiacInfo.unavailable;

    // v0.47: public solar term with fallback to internal
    SolarTermInfo solarTerm = SolarTermInfo.unavailable;
    if (_publicFlag.solarTermPublicEnabled && _publicFlag.sourceIsSafe) {
      solarTerm = SolarTermInfo(
        available: true,
        currentTerm: '',
        displayText: '今日无节气',
        basis: _publicFlag.source,
      );
    } else if (_solarTermFlag.internalSolarTermAllowed) {
      solarTerm = SolarTermInfo(
        available: true,
        currentTerm: '',
        displayText: '今日无节气',
        basis: 'internal_candidate_trial_v0_45',
      );
    }

    // v0.49: public ganzhi with fallback to internal; v0.50: day ganzhi & clash
    GanzhiInfo ganzhi = GanzhiInfo.unavailable;
    ClashInfo clash = ClashInfo.unavailable;
    final usePublic = _ganzhiPublicFlag.ganzhiPublicEnabled && _ganzhiPublicFlag.sourceIsSafe;
    final useInternal = _ganzhiFlag.internalGanzhiAllowed && _ganzhiFlag.sourceIsSafe;
    final useDayGanzhi = (_dayGanzhiClashPublicFlag.dayGanzhiPublicEnabled && _dayGanzhiClashPublicFlag.sourceIsSafe) || (_dayGanzhiClashFlag.internalDayGanzhiAllowed && _dayGanzhiClashFlag.sourceIsSafe);
    final useClash = (_dayGanzhiClashPublicFlag.clashPublicEnabled && _dayGanzhiClashPublicFlag.sourceIsSafe) || (_dayGanzhiClashFlag.internalClashAllowed && _dayGanzhiClashFlag.sourceIsSafe);

    String ytext = '', mtext = '', dtext = '';
    Map<String, String> basis = {};

    if (usePublic || useInternal) {
      final solarAvailable = _publicFlag.solarTermPublicEnabled || _solarTermFlag.internalSolarTermAllowed;
      final gzResult = _ganzhiEngine.compute(date, solarTermAvailable: solarAvailable);
      final yearOk = gzResult.ganzhiYear != null && gzResult.ganzhiYear!.isNotEmpty;
      final monthOk = gzResult.ganzhiMonth != null && gzResult.ganzhiMonth!.isNotEmpty;
      final displayYear = (usePublic && _ganzhiPublicFlag.yearGanzhiEnabled) || (useInternal);
      final displayMonth = (usePublic && _ganzhiPublicFlag.monthGanzhiEnabled) || (useInternal);
      ytext = displayYear ? (gzResult.ganzhiYear ?? '') : '';
      mtext = displayMonth ? (gzResult.ganzhiMonth ?? '') : '';
      if (displayYear && yearOk) basis['year'] = gzResult.ganzhiYear!;
      if (displayMonth && monthOk) basis['month'] = gzResult.ganzhiMonth!;
      basis['rule'] = gzResult.rule;
    }

    // v0.50: day ganzhi internal (independent flag from year/month)
    if (useDayGanzhi) {
      final dayResult = _dayGanzhiEngine.compute(date);
      dtext = dayResult.dayGanzhi ?? '';
      if (dtext.isNotEmpty) basis['day'] = dtext;
    }

    // v0.50: clash internal (dependent on day branch)
    if (useClash && dtext.isNotEmpty) {
      final dayBranch = dtext.length >= 2 ? dtext[1] : '';
      final cResult = _clashEngine.compute(dayBranch);
      if (cResult.clashZodiac != null) {
        clash = ClashInfo(available: true, dayBranch: cResult.dayBranch ?? '', clashZodiac: cResult.clashZodiac ?? '', shaDirection: cResult.shaDirection ?? '', displayText: '冲${cResult.clashZodiac} 煞${cResult.shaDirection}'.trim());
      }
    }

    if (ytext.isNotEmpty || mtext.isNotEmpty || dtext.isNotEmpty) {
      ganzhi = GanzhiInfo(available: true, yearGanzhi: ytext, monthGanzhi: mtext, dayGanzhi: dtext, displayText: '$ytext $mtext $dtext'.trim(), basis: basis);
    }

    return CalendarDayInfo(
      dateKey: dk,
      gregorianDate: '${date.year}年${date.month}月${date.day}日',
      timezone: timezone,
      weekday: _weekdays[date.weekday - 1],
      lunar: lunar,
      ganzhi: ganzhi,
      zodiac: zodiac,
      solarTerm: solarTerm,
      clash: clash,
      dataQuality: {'lunar': lunar.available ? 'full' : 'unavailable', 'zodiac': zodiac.available ? 'full' : 'unavailable', 'ganzhi': 'unavailable', 'solarTerm': _solarTermFlag.internalSolarTermAllowed ? 'internal' : 'unavailable', 'clash': 'unavailable'},
      source: 'local_calendar_provider_v0_45',
      warnings: ['干支、节气、冲煞暂无可靠算法。v0.45 节气 internal 受控测试中。'],
    );
  }
}

/// 全局单例
final calendarProvider = LocalCalendarProvider();

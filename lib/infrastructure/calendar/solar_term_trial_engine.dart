import 'solar_term_trial_models.dart';
import 'solar_term_candidate_sandbox_loader.dart';

/// 节气候选数据试运行只读引擎 v0.32
///
/// 仅在 trial mode（readOnly/debugOnly）下通过 Debug inspection 返回 trial 结果。
/// 所有结果标记 status=trial_only，且 displayAllowed/shareAllowed/snapshotAllowed=false。
/// 不改变 CalendarProvider public capabilities。

class SolarTermTrialResult {
  final bool available;
  final String status; // trial_only | unavailable | blocked | none
  final String? termName;
  final String? date;
  final String? time;
  final String? timezone;
  final String source;
  final bool productionReady;
  final bool publicExposure;
  final bool calendarProviderIntegration;
  final bool displayAllowed;
  final bool shareAllowed;
  final bool snapshotAllowed;
  final bool ganzhiDependencyAllowed;
  final bool clashDependencyAllowed;
  final String? reason;

  const SolarTermTrialResult({
    this.available=false,
    this.status='unavailable',
    this.termName, this.date, this.time, this.timezone,
    this.source='solar_term_candidate_trial_v0_32',
    this.productionReady=false, this.publicExposure=false, this.calendarProviderIntegration=false,
    this.displayAllowed=false, this.shareAllowed=false, this.snapshotAllowed=false,
    this.ganzhiDependencyAllowed=false, this.clashDependencyAllowed=false,
    this.reason,
  });

  static const unavailable = SolarTermTrialResult(reason:'trial mode disabled or candidate data not available');
  static const blocked = SolarTermTrialResult(available:false,status:'blocked',reason:'trial mode blocked by config');

  Map<String, dynamic> toJson() => {
    'available':available,'status':status,
    if(termName!=null)'termName':termName,if(date!=null)'date':date,
    if(time!=null)'time':time,if(timezone!=null)'timezone':timezone,
    'source':source,
    'productionReady':productionReady,'publicExposure':publicExposure,'calendarProviderIntegration':calendarProviderIntegration,
    'displayAllowed':displayAllowed,'shareAllowed':shareAllowed,'snapshotAllowed':snapshotAllowed,
    'ganzhiDependencyAllowed':ganzhiDependencyAllowed,'clashDependencyAllowed':clashDependencyAllowed,
    if(reason!=null)'reason':reason,
  };
}

class SolarTermTrialEngine {
  final SolarTermTrialModeConfig config;
  final SolarTermCandidateSandboxLoader loader;

  const SolarTermTrialEngine({this.config = SolarTermTrialModeConfig.defaultConfig, this.loader = const SolarTermCandidateSandboxLoader()});

  /// Check all blocking conditions before any data access
  SolarTermTrialResult? _blockCheck() {
    if(!config.enabled) return SolarTermTrialResult.unavailable;
    if(!config.readOnly||!config.debugOnly) return SolarTermTrialResult.blocked;
    if(config.publicExposure||config.calendarProviderIntegration) return SolarTermTrialResult.blocked;
    if(config.pageDisplay||config.shareDisplay||config.snapshotWrite) return SolarTermTrialResult.blocked;
    if(config.ganzhiDependency||config.clashDependency) return SolarTermTrialResult.blocked;
    return null; // not blocked
  }

  /// Get trial solar term for a date (Debug inspection only)
  Future<SolarTermTrialResult> getTrialSolarTermForDate(DateTime date) async {
    final block = _blockCheck(); if(block!=null) return block;
    final inspect = await loader.inspect();
    if(!inspect.safeForSandbox||!inspect.candidateDataExists||!inspect.candidateDataReady) {
      return SolarTermTrialResult.unavailable;
    }
    final raw = inspect.rawData; if(raw==null) return SolarTermTrialResult.unavailable;
    final years = raw['years'] as List?; if(years==null||years.isEmpty) return SolarTermTrialResult.unavailable;

    for(final y in years) {
      final ym = y as Map<String,dynamic>; final yr = ym['year'] as int?;
      if(yr!=date.year) continue;
      final terms = ym['terms'] as List?; if(terms==null) continue;
      // Find term closest to or matching the date
      for(final t in terms) {
        final tm = t as Map<String,dynamic>; final td = tm['date'] as String?;
        if(td==null) continue;
        // Check if the date falls on or near this term (simple date match)
        final dk = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
        if(td==dk) {
          return SolarTermTrialResult(
            available:true,status:'trial_only',
            termName:tm['name'] as String?,date:td,
            time:tm['time'] as String?,timezone:tm['timezone'] as String?,
          );
        }
      }
    }
    return const SolarTermTrialResult(available:false,status:'none',reason:'no solar term found for this date');
  }

  /// Get all trial solar terms for a year
  Future<List<SolarTermTrialResult>> getTrialSolarTermsForYear(int year) async {
    final block = _blockCheck(); if(block!=null) return [block];
    final inspect = await loader.inspect();
    if(!inspect.safeForSandbox||!inspect.candidateDataExists||!inspect.candidateDataReady) {
      return [SolarTermTrialResult.unavailable];
    }
    final raw = inspect.rawData; if(raw==null) return [SolarTermTrialResult.unavailable];
    final years = raw['years'] as List?; if(years==null||years.isEmpty) return [SolarTermTrialResult.unavailable];

    for(final y in years) {
      final ym = y as Map<String,dynamic>; if(ym['year']!=year) continue;
      final terms = ym['terms'] as List?; if(terms==null) return [];
      return terms.map((t){
        final tm=t as Map<String,dynamic>;
        return SolarTermTrialResult(available:true,status:'trial_only',termName:tm['name'] as String?,date:tm['date'] as String?,time:tm['time'] as String?,timezone:tm['timezone'] as String?);
      }).toList();
    }
    return [];
  }

  /// Inspect trial data metadata
  Future<SolarTermCandidateSandboxInspectResult> inspectTrialData() async => await loader.inspect();

  /// Build debug JSON for trial engine
  Map<String, dynamic> buildDebugJson() {
    return {
      'schemaVersion': 'solar-term-trial-engine-debug-v0_32',
      'trialEngineEnabled': config.enabled,
      'trialReadOnly': config.readOnly,
      'trialDebugOnly': config.debugOnly,
      'trialResultAvailable': false,
      'trialResultStatus': 'unavailable',
      'productionReady': false,
      'publicExposure': false,
      'calendarProviderIntegration': false,
      'displayAllowed': false,
      'shareAllowed': false,
      'snapshotAllowed': false,
      'ganzhiDependencyAllowed': false,
      'clashDependencyAllowed': false,
      'calendarProviderSupportsSolarTerm': false,
      'pageDisplaysSolarTerm': false,
      'shareDisplaysSolarTerm': false,
      'blockedReasons': {
        'solarTerm': 'v0.32 仅提供节气试运行只读引擎，不公开节气能力',
        'monthGanzhi': '月干支仍依赖正式验收后的节气能力',
        'lichunBoundary': '立春边界仍依赖正式验收后的节气能力',
        'clash': '冲煞依赖更完整传统历法规则，当前不进入 MVP',
      },
    };
  }
}

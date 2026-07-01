/// 日干支与冲煞开发内测 Feature Flag v0.50
enum DayGanzhiFeatureEnvironment { debug, internal, production }

class DayGanzhiInternalFeatureFlag {
  final bool enabled; final DayGanzhiFeatureEnvironment environment;
  final String source; final String reason;
  final bool dayGanzhiAllowed; final bool clashAllowed; final bool hourGanzhiAllowed;
  final bool publicExposureAllowed; final bool shareAllowed; final bool snapshotAllowed;
  final bool baziDependencyAllowed;

  const DayGanzhiInternalFeatureFlag({
    this.enabled = false, this.environment = DayGanzhiFeatureEnvironment.production,
    this.source = 'day_ganzhi_clash_internal_v0_50', this.reason = 'v0.50 internal day ganzhi & clash',
    this.dayGanzhiAllowed = false, this.clashAllowed = false, this.hourGanzhiAllowed = false,
    this.publicExposureAllowed = false, this.shareAllowed = false, this.snapshotAllowed = false,
    this.baziDependencyAllowed = false,
  });

  static const defaultDisabled = DayGanzhiInternalFeatureFlag();
  static const debugEnabled = DayGanzhiInternalFeatureFlag(enabled: true, environment: DayGanzhiFeatureEnvironment.debug, dayGanzhiAllowed: true, clashAllowed: true);
  static const internalEnabled = DayGanzhiInternalFeatureFlag(enabled: true, environment: DayGanzhiFeatureEnvironment.internal, dayGanzhiAllowed: true, clashAllowed: true);

  bool get internalDayGanzhiAllowed {
    if (!enabled || !dayGanzhiAllowed) return false;
    if (publicExposureAllowed || shareAllowed || snapshotAllowed || baziDependencyAllowed) return false;
    return environment == DayGanzhiFeatureEnvironment.debug || environment == DayGanzhiFeatureEnvironment.internal;
  }

  bool get internalClashAllowed {
    if (!enabled || !clashAllowed) return false;
    if (publicExposureAllowed || shareAllowed || snapshotAllowed) return false;
    return environment == DayGanzhiFeatureEnvironment.debug || environment == DayGanzhiFeatureEnvironment.internal;
  }

  bool get sourceIsSafe { final s=source.toLowerCase(); return s.contains('internal')&&!s.contains('public')&&!s.contains('production')&&!s.contains('official_enabled'); }

  Map<String, dynamic> toJson() => {
    'enabled': enabled, 'environment': environment.name, 'source': source, 'reason': reason,
    'dayGanzhiAllowed': dayGanzhiAllowed, 'clashAllowed': clashAllowed, 'hourGanzhiAllowed': hourGanzhiAllowed,
    'publicExposureAllowed': publicExposureAllowed, 'shareAllowed': shareAllowed, 'snapshotAllowed': snapshotAllowed,
    'internalDayGanzhiAllowed': internalDayGanzhiAllowed, 'internalClashAllowed': internalClashAllowed,
  };
}

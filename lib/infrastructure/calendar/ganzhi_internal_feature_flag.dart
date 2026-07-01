/// 干支开发内测 Feature Flag v0.48
enum GanzhiFeatureEnvironment { debug, internal, production }

class GanzhiInternalFeatureFlag {
  final bool enabled;
  final GanzhiFeatureEnvironment environment;
  final String source; final String reason;
  final bool yearGanzhiAllowed; final bool monthGanzhiAllowed;
  final bool dayGanzhiAllowed; final bool hourGanzhiAllowed;
  final bool publicExposureAllowed; final bool shareAllowed; final bool snapshotAllowed;
  final bool clashDependencyAllowed;

  const GanzhiInternalFeatureFlag({
    this.enabled = false, this.environment = GanzhiFeatureEnvironment.production,
    this.source = 'ganzhi_internal_candidate_v0_48', this.reason = 'v0.48 internal ganzhi enablement',
    this.yearGanzhiAllowed = true, this.monthGanzhiAllowed = true,
    this.dayGanzhiAllowed = false, this.hourGanzhiAllowed = false,
    this.publicExposureAllowed = false, this.shareAllowed = false, this.snapshotAllowed = false,
    this.clashDependencyAllowed = false,
  });

  static const defaultDisabled = GanzhiInternalFeatureFlag();
  static const debugEnabled = GanzhiInternalFeatureFlag(enabled: true, environment: GanzhiFeatureEnvironment.debug, reason: 'debug internal testing');
  static const internalEnabled = GanzhiInternalFeatureFlag(enabled: true, environment: GanzhiFeatureEnvironment.internal, reason: 'internal testing');

  bool get internalGanzhiAllowed {
    if (!enabled) return false;
    if (publicExposureAllowed || shareAllowed || snapshotAllowed || clashDependencyAllowed) return false;
    return environment == GanzhiFeatureEnvironment.debug || environment == GanzhiFeatureEnvironment.internal;
  }

  bool get sourceIsSafe {
    final s = source.toLowerCase();
    return !s.contains('public') && !s.contains('production') && !s.contains('official_enabled') && s.contains('internal');
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled, 'environment': environment.name, 'source': source, 'reason': reason,
    'yearGanzhiAllowed': yearGanzhiAllowed, 'monthGanzhiAllowed': monthGanzhiAllowed,
    'dayGanzhiAllowed': dayGanzhiAllowed, 'hourGanzhiAllowed': hourGanzhiAllowed,
    'publicExposureAllowed': publicExposureAllowed, 'shareAllowed': shareAllowed, 'snapshotAllowed': snapshotAllowed,
    'clashDependencyAllowed': clashDependencyAllowed, 'internalGanzhiAllowed': internalGanzhiAllowed,
  };
}

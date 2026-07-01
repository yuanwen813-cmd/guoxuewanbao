/// 节气开发内测 Feature Flag v0.45
///
/// 仅在 debug/internal 环境下允许 CalendarProvider 返回 internal solarTerm。
/// production 默认关闭。publicExposure/share/snapshot/ganzhi/clash 一律阻断。

enum SolarTermFeatureEnvironment { debug, internal, production }

class SolarTermInternalFeatureFlag {
  final bool enabled;
  final SolarTermFeatureEnvironment environment;
  final String source;
  final String reason;
  final bool publicExposureAllowed;
  final bool shareAllowed;
  final bool snapshotAllowed;
  final bool ganzhiDependencyAllowed;
  final bool clashDependencyAllowed;

  const SolarTermInternalFeatureFlag({
    this.enabled = false,
    this.environment = SolarTermFeatureEnvironment.production,
    this.source = 'internal_candidate_trial_v0_45',
    this.reason = 'v0.45 internal enablement only',
    this.publicExposureAllowed = false,
    this.shareAllowed = false,
    this.snapshotAllowed = false,
    this.ganzhiDependencyAllowed = false,
    this.clashDependencyAllowed = false,
  });

  /// 默认 production 关闭
  static const defaultProduction = SolarTermInternalFeatureFlag();

  /// debug 内测开启
  static const debugEnabled = SolarTermInternalFeatureFlag(
    enabled: true,
    environment: SolarTermFeatureEnvironment.debug,
    reason: 'debug internal testing',
  );

  /// internal 内测开启
  static const internalEnabled = SolarTermInternalFeatureFlag(
    enabled: true,
    environment: SolarTermFeatureEnvironment.internal,
    reason: 'internal testing',
  );

  /// 是否允许 CalendarProvider 返回 internal solarTerm
  bool get internalSolarTermAllowed {
    if (!enabled) return false;
    if (publicExposureAllowed) return false;
    if (shareAllowed) return false;
    if (snapshotAllowed) return false;
    if (ganzhiDependencyAllowed) return false;
    if (clashDependencyAllowed) return false;
    return environment == SolarTermFeatureEnvironment.debug ||
        environment == SolarTermFeatureEnvironment.internal;
  }

  /// 是否允许页面展示（internal 环境）
  bool get pageDisplayAllowed => internalSolarTermAllowed;

  /// source 是否有禁止标识
  bool get sourceIsSafe {
    final s = source.toLowerCase();
    return !s.contains('public') && !s.contains('production') && !s.contains('official_enabled');
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled, 'environment': environment.name, 'source': source, 'reason': reason,
    'publicExposureAllowed': publicExposureAllowed, 'shareAllowed': shareAllowed,
    'snapshotAllowed': snapshotAllowed, 'ganzhiDependencyAllowed': ganzhiDependencyAllowed,
    'clashDependencyAllowed': clashDependencyAllowed,
    'internalSolarTermAllowed': internalSolarTermAllowed, 'pageDisplayAllowed': pageDisplayAllowed,
  };
}

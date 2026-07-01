/// 节气正式公开 Feature Flag v0.47
///
/// 独立控制 public display / share / snapshot 三个维度。
/// solarTermPublicEnabled=true 时 CalendarProvider 公开 supportsSolarTerm。
/// share/snapshot 默认 false，独立开关。

class SolarTermPublicFeatureFlag {
  final bool solarTermPublicEnabled;
  final bool solarTermShareEnabled;
  final bool solarTermSnapshotEnabled;
  final String source;
  final String sourceVersion;
  final String reason;
  final bool ganzhiDependencyAllowed;
  final bool clashDependencyAllowed;

  const SolarTermPublicFeatureFlag({
    this.solarTermPublicEnabled = false,
    this.solarTermShareEnabled = false,
    this.solarTermSnapshotEnabled = false,
    this.source = 'local_solar_term_v0_47',
    this.sourceVersion = 'v0.47.0',
    this.reason = 'v0.47 public solar term enablement',
    this.ganzhiDependencyAllowed = false,
    this.clashDependencyAllowed = false,
  });

  /// 默认关闭
  static const defaultDisabled = SolarTermPublicFeatureFlag();

  /// 公开启用（仅页面，分享/snapshot 仍关闭）
  static const publicEnabled = SolarTermPublicFeatureFlag(
    solarTermPublicEnabled: true,
    reason: 'public solar term display enabled',
  );

  /// 全量启用（页面+分享+snapshot）
  static const fullEnabled = SolarTermPublicFeatureFlag(
    solarTermPublicEnabled: true,
    solarTermShareEnabled: true,
    solarTermSnapshotEnabled: true,
    reason: 'full public solar term enabled',
  );

  /// source 是否安全（不含禁止标识）
  bool get sourceIsSafe {
    final s = source.toLowerCase();
    return !s.contains('trial') && !s.contains('candidate') && !s.contains('internal') &&
        !s.contains('random') && !s.contains('hash') && !s.contains('ai');
  }

  Map<String, dynamic> toJson() => {
    'solarTermPublicEnabled': solarTermPublicEnabled, 'solarTermShareEnabled': solarTermShareEnabled,
    'solarTermSnapshotEnabled': solarTermSnapshotEnabled,
    'source': source, 'sourceVersion': sourceVersion, 'reason': reason,
    'ganzhiDependencyAllowed': ganzhiDependencyAllowed, 'clashDependencyAllowed': clashDependencyAllowed,
  };
}

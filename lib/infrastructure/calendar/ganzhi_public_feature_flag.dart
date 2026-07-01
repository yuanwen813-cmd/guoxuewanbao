/// 干支正式公开 Feature Flag v0.49
class GanzhiPublicFeatureFlag {
  final bool ganzhiPublicEnabled;
  final bool ganzhiShareEnabled;
  final bool ganzhiSnapshotEnabled;
  final bool yearGanzhiEnabled;
  final bool monthGanzhiEnabled;
  final bool dayGanzhiEnabled;
  final bool hourGanzhiEnabled;
  final bool clashDependencyAllowed;
  final String source; final String sourceVersion; final String reason;

  const GanzhiPublicFeatureFlag({
    this.ganzhiPublicEnabled = false,
    this.ganzhiShareEnabled = false,
    this.ganzhiSnapshotEnabled = false,
    this.yearGanzhiEnabled = false,
    this.monthGanzhiEnabled = false,
    this.dayGanzhiEnabled = false,
    this.hourGanzhiEnabled = false,
    this.clashDependencyAllowed = false,
    this.source = 'local_ganzhi_v0_49',
    this.sourceVersion = 'v0.49.0',
    this.reason = 'v0.49 public ganzhi enablement',
  });

  static const defaultDisabled = GanzhiPublicFeatureFlag();
  static const publicEnabled = GanzhiPublicFeatureFlag(ganzhiPublicEnabled: true, yearGanzhiEnabled: true, monthGanzhiEnabled: true);
  static const fullEnabled = GanzhiPublicFeatureFlag(ganzhiPublicEnabled: true, yearGanzhiEnabled: true, monthGanzhiEnabled: true, ganzhiShareEnabled: true, ganzhiSnapshotEnabled: true);

  bool get sourceIsSafe { final s=source.toLowerCase(); return !s.contains('internal')&&!s.contains('trial')&&!s.contains('candidate')&&!s.contains('debug'); }

  Map<String, dynamic> toJson() => {
    'ganzhiPublicEnabled': ganzhiPublicEnabled, 'ganzhiShareEnabled': ganzhiShareEnabled,
    'ganzhiSnapshotEnabled': ganzhiSnapshotEnabled,
    'yearGanzhiEnabled': yearGanzhiEnabled, 'monthGanzhiEnabled': monthGanzhiEnabled,
    'dayGanzhiEnabled': dayGanzhiEnabled, 'hourGanzhiEnabled': hourGanzhiEnabled,
    'clashDependencyAllowed': clashDependencyAllowed,
    'source': source, 'sourceVersion': sourceVersion, 'reason': reason,
  };
}

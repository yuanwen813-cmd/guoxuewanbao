/// 日干支与冲煞正式公开 Feature Flag v0.51
class DayGanzhiClashPublicFeatureFlag {
  final bool dayGanzhiPublicEnabled; final bool clashPublicEnabled;
  final bool dayGanzhiShareEnabled; final bool clashShareEnabled;
  final bool dayGanzhiSnapshotEnabled; final bool clashSnapshotEnabled;
  final bool hourGanzhiEnabled; final bool baziDependencyAllowed;
  final String source; final String sourceVersion; final String reason;

  const DayGanzhiClashPublicFeatureFlag({
    this.dayGanzhiPublicEnabled = false, this.clashPublicEnabled = false,
    this.dayGanzhiShareEnabled = false, this.clashShareEnabled = false,
    this.dayGanzhiSnapshotEnabled = false, this.clashSnapshotEnabled = false,
    this.hourGanzhiEnabled = false, this.baziDependencyAllowed = false,
    this.source = 'local_day_ganzhi_clash_v0_51', this.sourceVersion = 'v0.51.0',
    this.reason = 'v0.51 public day ganzhi & clash enablement',
  });

  static const defaultDisabled = DayGanzhiClashPublicFeatureFlag();
  static const publicEnabled = DayGanzhiClashPublicFeatureFlag(dayGanzhiPublicEnabled: true, clashPublicEnabled: true);
  static const fullEnabled = DayGanzhiClashPublicFeatureFlag(dayGanzhiPublicEnabled: true, clashPublicEnabled: true, dayGanzhiShareEnabled: true, clashShareEnabled: true, dayGanzhiSnapshotEnabled: true, clashSnapshotEnabled: true);

  bool get sourceIsSafe { final s=source.toLowerCase(); return !s.contains('internal')&&!s.contains('trial')&&!s.contains('candidate')&&!s.contains('debug'); }

  Map<String, dynamic> toJson() => {
    'dayGanzhiPublicEnabled': dayGanzhiPublicEnabled, 'clashPublicEnabled': clashPublicEnabled,
    'dayGanzhiShareEnabled': dayGanzhiShareEnabled, 'clashShareEnabled': clashShareEnabled,
    'dayGanzhiSnapshotEnabled': dayGanzhiSnapshotEnabled, 'clashSnapshotEnabled': clashSnapshotEnabled,
    'hourGanzhiEnabled': hourGanzhiEnabled, 'baziDependencyAllowed': baziDependencyAllowed,
    'source': source, 'sourceVersion': sourceVersion, 'reason': reason,
  };
}

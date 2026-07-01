/// 节气试运行模式模型 v0.31
///
/// Trial mode is read-only, debug-only, no public exposure.
/// Does NOT integrate with CalendarProvider, page, share, or resultSnapshot.

class SolarTermTrialModeConfig {
  final String schemaVersion;
  final bool enabled;
  final bool readOnly;
  final bool debugOnly;
  final bool publicExposure;
  final bool calendarProviderIntegration;
  final bool pageDisplay;
  final bool shareDisplay;
  final bool snapshotWrite;
  final bool ganzhiDependency;
  final bool clashDependency;

  const SolarTermTrialModeConfig({
    this.schemaVersion = 'solar-term-trial-mode-v0_31',
    this.enabled = true,
    this.readOnly = true,
    this.debugOnly = true,
    this.publicExposure = false,
    this.calendarProviderIntegration = false,
    this.pageDisplay = false,
    this.shareDisplay = false,
    this.snapshotWrite = false,
    this.ganzhiDependency = false,
    this.clashDependency = false,
  });

  /// Default v0.31 trial config: read-only debug inspection only
  static const defaultConfig = SolarTermTrialModeConfig();

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'enabled': enabled, 'readOnly': readOnly, 'debugOnly': debugOnly,
    'publicExposure': publicExposure, 'calendarProviderIntegration': calendarProviderIntegration,
    'pageDisplay': pageDisplay, 'shareDisplay': shareDisplay, 'snapshotWrite': snapshotWrite,
    'ganzhiDependency': ganzhiDependency, 'clashDependency': clashDependency,
  };
}

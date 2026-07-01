/// 节气正式接入沙箱适配器 v0.38
///
/// 验证 trial result → public contract draft 字段映射完整性。
/// mapped_for_sandbox ≠ productionReady ≠ publicExposure。
/// 所有 guard flags 必须 false。

import 'solar_term_trial_engine.dart';

/// 沙箱 contract（10 字段映射自 trial result）
class SolarTermPublicSandboxContract {
  final String? solarTermName;
  final String? solarTermDate;
  final String? solarTermTime;
  final String source;
  final String sourceVersion;
  final String confidence;
  final String status;
  final String? timezone;
  final String? generatedAt;
  final String? unavailableReason;

  const SolarTermPublicSandboxContract({
    this.solarTermName, this.solarTermDate, this.solarTermTime,
    this.source = '', this.sourceVersion = 'v0_38_sandbox', this.confidence = 'sandbox',
    this.status = 'sandbox', this.timezone, this.generatedAt, this.unavailableReason,
  });

  /// 从 trial result 映射
  factory SolarTermPublicSandboxContract.fromTrial(SolarTermTrialResult trial) {
    if (!trial.available) {
      return SolarTermPublicSandboxContract(
        source: trial.source, status: trial.status,
        unavailableReason: trial.reason ?? 'trial data unavailable',
      );
    }
    return SolarTermPublicSandboxContract(
      solarTermName: trial.termName, solarTermDate: trial.date, solarTermTime: trial.time,
      source: trial.source, status: 'sandbox_mapped',
      timezone: trial.timezone,
      generatedAt: DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
    'solarTermName': solarTermName, 'solarTermDate': solarTermDate, 'solarTermTime': solarTermTime,
    'source': source, 'sourceVersion': sourceVersion, 'confidence': confidence, 'status': status,
    'timezone': timezone, 'generatedAt': generatedAt, 'unavailableReason': unavailableReason,
  };
}

/// 映射问题
class SolarTermPublicSandboxMappingIssue {
  final String field;
  final String reason;
  final String severity;
  final String date;
  final String suggestion;

  const SolarTermPublicSandboxMappingIssue({
    required this.field, required this.reason, this.severity = 'medium',
    required this.date, this.suggestion = '',
  });

  Map<String, dynamic> toJson() => {
    'field': field, 'reason': reason, 'severity': severity, 'date': date, 'suggestion': suggestion,
  };
}

/// 沙箱 guard（固定 false）
class SolarTermPublicSandboxGuard {
  final bool productionReady;
  final bool publicExposure;
  final bool calendarProviderIntegration;
  final bool displayAllowed;
  final bool shareAllowed;
  final bool snapshotAllowed;
  final bool ganzhiDependencyAllowed;
  final bool clashDependencyAllowed;

  const SolarTermPublicSandboxGuard()
      : productionReady = false, publicExposure = false, calendarProviderIntegration = false,
        displayAllowed = false, shareAllowed = false, snapshotAllowed = false,
        ganzhiDependencyAllowed = false, clashDependencyAllowed = false;

  bool get allSafe => !productionReady && !publicExposure && !calendarProviderIntegration &&
      !displayAllowed && !shareAllowed && !snapshotAllowed &&
      !ganzhiDependencyAllowed && !clashDependencyAllowed;

  Map<String, dynamic> toJson() => {
    'productionReady': productionReady, 'publicExposure': publicExposure,
    'calendarProviderIntegration': calendarProviderIntegration,
    'displayAllowed': displayAllowed, 'shareAllowed': shareAllowed, 'snapshotAllowed': snapshotAllowed,
    'ganzhiDependencyAllowed': ganzhiDependencyAllowed, 'clashDependencyAllowed': clashDependencyAllowed,
  };
}

/// 沙箱输出
class SolarTermPublicSandboxResult {
  final String schemaVersion;
  final String? sampleName;
  final String date;
  final String sandboxStatus;
  final SolarTermPublicSandboxContract contract;
  final List<SolarTermPublicSandboxMappingIssue> mappingIssues;
  final List<String> blockers;
  final List<String> warnings;
  final SolarTermPublicSandboxGuard guard;
  final String conclusionNote;

  const SolarTermPublicSandboxResult({
    this.schemaVersion = 'solar-term-public-sandbox-adapter-v0_38',
    this.sampleName, required this.date, required this.sandboxStatus,
    required this.contract, this.mappingIssues = const [],
    this.blockers = const [], this.warnings = const [],
    this.guard = const SolarTermPublicSandboxGuard(),
    this.conclusionNote = 'sandbox mapping only, not public solar term capability',
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    if (sampleName != null) 'sampleName': sampleName,
    'date': date, 'sandboxStatus': sandboxStatus,
    'contract': contract.toJson(),
    'mappingIssues': mappingIssues.map((i) => i.toJson()).toList(),
    'blockers': blockers, 'warnings': warnings,
    'guardFlags': guard.toJson(),
    'conclusionNote': conclusionNote,
  };
}

/// 沙箱适配器
class SolarTermPublicSandboxAdapter {
  static const forbiddenSourceTerms = ['public', 'production', 'official_enabled'];

  const SolarTermPublicSandboxAdapter();

  /// 适配 trial result 到 sandbox contract
  SolarTermPublicSandboxResult adapt({
    required SolarTermTrialResult trial,
    required String designStatus,
    required String date,
    String? sampleName,
  }) {
    final guard = const SolarTermPublicSandboxGuard();
    final issues = <SolarTermPublicSandboxMappingIssue>[];
    final blockers = <String>[];

    String status;

    // 1. guard check
    if (!guard.allSafe) {
      status = 'blocked'; blockers.add('sandbox_guard_unsafe');
    }
    // 2. design gate
    else if (designStatus != 'design_ready') {
      status = 'blocked'; blockers.add('design_not_ready: $designStatus');
    }
    // 3. source forbidden terms
    else if (forbiddenSourceTerms.any((t) => trial.source.toLowerCase().contains(t))) {
      status = 'blocked'; blockers.add('forbidden_source_term');
      issues.add(SolarTermPublicSandboxMappingIssue(field: 'source', reason: 'source 包含禁止标识: ${trial.source}', severity: 'high', date: date, suggestion: 'source 必须包含 trial/candidate'));
    }
    // 4. trial status check
    else if (trial.status == 'blocked') {
      status = 'blocked'; blockers.add('trial_blocked');
    } else if (trial.status == 'unavailable' || !trial.available) {
      status = 'unavailable';
    }
    // 5. trial_only → map
    else if (trial.status == 'trial_only' && trial.available) {
      // Check required fields
      final missing = <String>[];
      if (trial.termName == null || trial.termName!.isEmpty) missing.add('solarTermName');
      if (trial.date == null || trial.date!.isEmpty) missing.add('solarTermDate');
      if (trial.timezone == null || trial.timezone!.isEmpty) missing.add('timezone');

      if (missing.isNotEmpty) {
        status = 'mapping_failed';
        for (final f in missing) {
          issues.add(SolarTermPublicSandboxMappingIssue(field: f, reason: '必填字段缺失', severity: 'high', date: date, suggestion: '补充 $f'));
          blockers.add('missing_$f');
        }
      } else {
        status = 'mapped_for_sandbox';
      }
    } else {
      status = 'blocked'; blockers.add('unknown_trial_status: ${trial.status}');
    }

    return SolarTermPublicSandboxResult(
      sampleName: sampleName, date: date, sandboxStatus: status,
      contract: SolarTermPublicSandboxContract.fromTrial(trial),
      mappingIssues: issues, blockers: blockers,
    );
  }

  Map<String, dynamic> buildDebugJson() => {
    'schemaVersion': 'solar-term-public-sandbox-adapter-debug-v0_38',
    'sandboxAdapterEnabled': true,
    'sampleName': null, 'date': null, 'sandboxStatus': 'unavailable',
    'contractFields': ['solarTermName', 'solarTermDate', 'solarTermTime', 'source', 'sourceVersion', 'confidence', 'status', 'timezone', 'generatedAt', 'unavailableReason'],
    'mappingIssues': [], 'blockers': [], 'warnings': [],
    'guardFlags': const SolarTermPublicSandboxGuard().toJson(),
    'conclusionNote': 'sandbox mapping only, not public solar term capability',
  };
}

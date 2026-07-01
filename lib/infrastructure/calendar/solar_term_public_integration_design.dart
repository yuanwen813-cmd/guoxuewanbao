/// 节气正式接入设计 v0.37
///
/// 输出正式接入设计方案、字段契约、gates、回滚策略和风险清单。
/// design_ready ≠ productionReady ≠ publicExposure。
/// 所有 guard flags 必须 false。

/// 未来正式接入字段契约草案（不实际接入）
class SolarTermPublicIntegrationDesignContract {
  final List<String> fields;

  const SolarTermPublicIntegrationDesignContract()
      : fields = const [
          'solarTermName', 'solarTermDate', 'solarTermTime',
          'source', 'sourceVersion', 'confidence', 'status',
          'timezone', 'generatedAt', 'unavailableReason',
        ];

  Map<String, dynamic> toJson() => {'fields': fields, 'note': 'draft only, not connected to CalendarProvider'};
}

/// 接入 gate
class SolarTermPublicIntegrationDesignGate {
  final String id;
  final String title;
  final bool passed;
  final bool required;
  final String severity;
  final String note;

  const SolarTermPublicIntegrationDesignGate({
    required this.id, required this.title,
    this.passed = false, this.required = true,
    this.severity = 'critical', this.note = '',
  });

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'passed': passed, 'required': required, 'severity': severity, 'note': note};
}

/// 接入 gates 集合
class SolarTermPublicIntegrationDesignGates {
  final List<SolarTermPublicIntegrationDesignGate> items;

  const SolarTermPublicIntegrationDesignGates({required this.items});

  int get passedCount => items.where((g) => g.passed).length;
  int get failedCount => items.where((g) => !g.passed).length;
  List<SolarTermPublicIntegrationDesignGate> get failedRequired => items.where((g) => !g.passed && g.required).toList();

  Map<String, dynamic> toJson() => {
    'items': items.map((g) => g.toJson()).toList(),
    'passedCount': passedCount, 'failedCount': failedCount,
  };
}

/// 回滚计划步骤
class SolarTermPublicIntegrationDesignRollbackStep {
  final String id;
  final String title;
  final String action;

  const SolarTermPublicIntegrationDesignRollbackStep({required this.id, required this.title, this.action = ''});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'action': action};
}

/// 回滚计划
class SolarTermPublicIntegrationDesignRollbackPlan {
  final List<SolarTermPublicIntegrationDesignRollbackStep> steps;

  const SolarTermPublicIntegrationDesignRollbackPlan()
      : steps = const [
          SolarTermPublicIntegrationDesignRollbackStep(id: 'disableSupportsSolarTerm', title: '禁用 supportsSolarTerm', action: 'CalendarProvider supportsSolarTerm → false'),
          SolarTermPublicIntegrationDesignRollbackStep(id: 'hidePageSolarTerm', title: '隐藏页面节气', action: '页面恢复"节气信息暂未启用"'),
          SolarTermPublicIntegrationDesignRollbackStep(id: 'hideShareSolarTerm', title: '隐藏分享节气', action: '分享移除节气字段'),
          SolarTermPublicIntegrationDesignRollbackStep(id: 'stopSnapshotSolarTermWrite', title: '停止 snapshot 节气写入', action: 'resultSnapshot 移除 solarTermData'),
          SolarTermPublicIntegrationDesignRollbackStep(id: 'keepOldSnapshotCompatible', title: '保持旧 snapshot 兼容', action: '不重算、不补写旧历史'),
          SolarTermPublicIntegrationDesignRollbackStep(id: 'restoreUnavailableState', title: '恢复 unavailable 状态', action: '所有节气字段恢复 unavailable'),
          SolarTermPublicIntegrationDesignRollbackStep(id: 'preserveLunarAndZodiac', title: '保留农历和生肖', action: 'lunarDate 和 zodiac 不受影响'),
          SolarTermPublicIntegrationDesignRollbackStep(id: 'disableGanzhiDependency', title: '禁用干支依赖', action: '移除节气→干支链路'),
          SolarTermPublicIntegrationDesignRollbackStep(id: 'disableClashDependency', title: '禁用冲煞依赖', action: '移除节气→冲煞链路'),
          SolarTermPublicIntegrationDesignRollbackStep(id: 'rollbackDebugFlag', title: 'Debug 回滚标记', action: '记录回滚原因和时间'),
        ];

  Map<String, dynamic> toJson() => {'steps': steps.map((s) => s.toJson()).toList()};
}

/// 设计 guard（固定 false）
class SolarTermPublicIntegrationDesignGuard {
  final bool productionReady;
  final bool publicExposure;
  final bool calendarProviderIntegration;
  final bool displayAllowed;
  final bool shareAllowed;
  final bool snapshotAllowed;
  final bool ganzhiDependencyAllowed;
  final bool clashDependencyAllowed;

  const SolarTermPublicIntegrationDesignGuard()
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

/// 设计风险项
class SolarTermPublicIntegrationDesignRisk {
  final String description;
  final String severity;

  const SolarTermPublicIntegrationDesignRisk({required this.description, this.severity = 'medium'});

  Map<String, dynamic> toJson() => {'description': description, 'severity': severity};
}

/// 设计决策
class SolarTermPublicIntegrationDesignDecision {
  final String status; // blocked | design_not_allowed | design_ready
  final String reason;
  final List<String> blockers;

  const SolarTermPublicIntegrationDesignDecision({this.status = 'blocked', this.reason = '', this.blockers = const []});

  Map<String, dynamic> toJson() => {'status': status, 'reason': reason, 'blockers': blockers};
}

/// 设计结果
class SolarTermPublicIntegrationDesignResult {
  final String schemaVersion;
  final String? sampleName;
  final String dateRange;
  final String designStatus;
  final SolarTermPublicIntegrationDesignDecision decision;
  final SolarTermPublicIntegrationDesignContract contract;
  final SolarTermPublicIntegrationDesignGates gates;
  final SolarTermPublicIntegrationDesignRollbackPlan rollbackPlan;
  final List<SolarTermPublicIntegrationDesignRisk> riskList;
  final List<String> blockers;
  final List<String> warnings;
  final SolarTermPublicIntegrationDesignGuard guard;
  final String conclusionNote;

  const SolarTermPublicIntegrationDesignResult({
    this.schemaVersion = 'solar-term-public-integration-design-v0_37',
    this.sampleName,
    required this.dateRange,
    required this.designStatus,
    required this.decision,
    required this.contract,
    required this.gates,
    this.rollbackPlan = const SolarTermPublicIntegrationDesignRollbackPlan(),
    this.riskList = const [],
    this.blockers = const [],
    this.warnings = const [],
    this.guard = const SolarTermPublicIntegrationDesignGuard(),
    this.conclusionNote = 'design only, not public solar term capability',
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    if (sampleName != null) 'sampleName': sampleName,
    'dateRange': dateRange,
    'designStatus': designStatus,
    'decision': decision.toJson(),
    'contractDraft': contract.toJson(),
    'integrationGates': gates.toJson(),
    'rollbackPlan': rollbackPlan.toJson(),
    'riskList': riskList.map((r) => r.toJson()).toList(),
    'blockers': blockers, 'warnings': warnings,
    'guardFlags': guard.toJson(),
    'conclusionNote': conclusionNote,
  };
}

/// 正式接入设计器
class SolarTermPublicIntegrationDesign {
  const SolarTermPublicIntegrationDesign();

  /// 构建 gates
  SolarTermPublicIntegrationDesignGates _buildGates() {
    const items = [
      SolarTermPublicIntegrationDesignGate(id: 'dataSourceVerified', title: '数据源已验证', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'fullYearCoverageVerified', title: '全年覆盖已验证', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'boundaryDatesVerified', title: '边界日期已验证', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'crossValidationPassed', title: '交叉验证通过', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'manualReviewPassed', title: '人工复核通过', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'auditPassed', title: '审计通过', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'observationPassed', title: '观测通过', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'evidencePackagePassed', title: '证据包通过', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'readinessPassed', title: '准入评估通过', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'rollbackPlanReady', title: '回滚计划就绪', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'snapshotMigrationPlanReady', title: 'Snapshot 迁移计划就绪', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'displayStrategyReviewed', title: '展示策略已评审', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'shareStrategyReviewed', title: '分享策略已评审', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'ganzhiDependencyReviewed', title: '干支依赖已评审', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'clashDependencyReviewed', title: '冲煞依赖已评审', passed: false),
      SolarTermPublicIntegrationDesignGate(id: 'finalHumanApprovalRequired', title: '最终人工审批', passed: false),
    ];
    return const SolarTermPublicIntegrationDesignGates(items: items);
  }

  /// 执行设计
  SolarTermPublicIntegrationDesignResult design({
    required String readinessStatus,
    required String dateRange,
    String? sampleName,
    bool readinessGuardSafe = true,
    bool evidenceGuardSafe = true,
    bool hasHighRisk = false,
  }) {
    final guard = const SolarTermPublicIntegrationDesignGuard();
    final risks = <SolarTermPublicIntegrationDesignRisk>[];
    final blockers = <String>[];

    String status;
    String reason;

    if (!guard.allSafe) {
      status = 'blocked'; reason = 'Guard flags 不安全'; blockers.add('guard_violation');
      risks.add(const SolarTermPublicIntegrationDesignRisk(description: 'Guard flags 不安全', severity: 'high'));
    } else if (!readinessGuardSafe || !evidenceGuardSafe) {
      status = 'blocked'; reason = '上游 guard 异常'; blockers.add('upstream_guard_violation');
    } else if (readinessStatus == 'blocked') {
      status = 'blocked'; reason = '准入评估被 block'; blockers.add('readiness_blocked');
    } else if (readinessStatus == 'insufficient_evidence') {
      status = 'design_not_allowed'; reason = '准入评估证据不足';
    } else if (hasHighRisk) {
      status = 'blocked'; reason = '存在 high risk'; blockers.add('high_risk');
    } else if (readinessStatus == 'ready_for_design_review') {
      status = 'design_ready'; reason = '正式接入设计方案已准备好';
    } else {
      status = 'blocked'; reason = '未知 readiness status';
    }

    return SolarTermPublicIntegrationDesignResult(
      sampleName: sampleName, dateRange: dateRange,
      designStatus: status,
      decision: SolarTermPublicIntegrationDesignDecision(status: status, reason: reason, blockers: blockers),
      contract: const SolarTermPublicIntegrationDesignContract(),
      gates: _buildGates(),
      riskList: risks, blockers: blockers,
    );
  }

  Map<String, dynamic> buildDebugJson() => {
    'schemaVersion': 'solar-term-public-integration-design-debug-v0_37',
    'designEnabled': true,
    'sampleName': null, 'dateRange': null,
    'designStatus': 'design_not_allowed',
    'contractDraftFields': const SolarTermPublicIntegrationDesignContract().fields,
    'integrationGatePassedCount': 0,
    'integrationGateFailedCount': 16,
    'rollbackPlan': const SolarTermPublicIntegrationDesignRollbackPlan().toJson(),
    'blockers': [], 'warnings': [], 'riskList': [],
    'guardFlags': const SolarTermPublicIntegrationDesignGuard().toJson(),
    'conclusionNote': 'design only, not public solar term capability',
  };
}

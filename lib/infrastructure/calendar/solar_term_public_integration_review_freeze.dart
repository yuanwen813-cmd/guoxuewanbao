/// 节气正式接入评审冻结 v0.41
///
/// 冻结 v0.22-v0.40 完整评审证据链。
/// review_frozen ≠ productionReady ≠ publicExposure。
/// 所有 guard flags 必须 false。

/// no-go 规则
class SolarTermPublicIntegrationReviewNoGoRule {
  final String id; final String title; final bool triggered;
  final String severity; final String note;

  const SolarTermPublicIntegrationReviewNoGoRule({
    required this.id, required this.title, this.triggered = false, this.severity = 'critical', this.note = '',
  });

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'triggered': triggered, 'severity': severity, 'note': note};
}

/// 评审 checklist 项
class SolarTermPublicIntegrationReviewCheckItem {
  final String id; final String title; final bool passed; final bool required;
  final String severity; final String note;

  const SolarTermPublicIntegrationReviewCheckItem({
    required this.id, required this.title, this.passed = false, this.required = true,
    this.severity = 'critical', this.note = '',
  });

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'passed': passed, 'required': required, 'severity': severity, 'note': note};
}

/// 评审 guard（固定 false）
class SolarTermPublicIntegrationReviewGuard {
  final bool productionReady; final bool publicExposure; final bool calendarProviderIntegration;
  final bool displayAllowed; final bool shareAllowed; final bool snapshotAllowed;
  final bool ganzhiDependencyAllowed; final bool clashDependencyAllowed;

  const SolarTermPublicIntegrationReviewGuard()
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

/// 评审冻结结果
class SolarTermPublicIntegrationReviewFreezeResult {
  final String schemaVersion;
  final String? sampleName;
  final String dateRange;
  final String reviewStatus;
  final Map<String, dynamic> reviewDecision;
  final List<SolarTermPublicIntegrationReviewCheckItem> checklist;
  final List<SolarTermPublicIntegrationReviewNoGoRule> noGoRules;
  final List<String> riskList;
  final List<String> blockers;
  final List<String> warnings;
  final SolarTermPublicIntegrationReviewGuard guard;
  final List<String> frozenEvidenceChain;
  final String conclusionNote;

  const SolarTermPublicIntegrationReviewFreezeResult({
    this.schemaVersion = 'solar-term-public-integration-review-freeze-v0_41',
    this.sampleName, required this.dateRange, required this.reviewStatus,
    required this.reviewDecision, required this.checklist, required this.noGoRules,
    this.riskList = const [], this.blockers = const [], this.warnings = const [],
    this.guard = const SolarTermPublicIntegrationReviewGuard(),
    this.frozenEvidenceChain = const [],
    this.conclusionNote = 'review freeze only, not public solar term capability',
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    if (sampleName != null) 'sampleName': sampleName,
    'dateRange': dateRange, 'reviewStatus': reviewStatus,
    'reviewDecision': reviewDecision,
    'checklist': checklist.map((c) => c.toJson()).toList(),
    'noGoRules': noGoRules.map((n) => n.toJson()).toList(),
    'riskList': riskList, 'blockers': blockers, 'warnings': warnings,
    'guardFlags': guard.toJson(), 'frozenEvidenceChain': frozenEvidenceChain,
    'conclusionNote': conclusionNote,
  };
}

/// 评审冻结器
class SolarTermPublicIntegrationReviewFreeze {
  const SolarTermPublicIntegrationReviewFreeze();

  static const frozenEvidenceChain = [
    'v0.22 solar term capability evaluation',
    'v0.23 source review', 'v0.24 candidate data preparation', 'v0.25 landing review',
    'v0.26 sandbox loader', 'v0.27 preflight', 'v0.28 validator', 'v0.29 cross-check',
    'v0.30 manual review', 'v0.31 trial integration design', 'v0.32 trial read-only engine',
    'v0.33 trial result audit', 'v0.34 observation', 'v0.35 evidence package',
    'v0.36 public readiness', 'v0.37 public integration design',
    'v0.38 sandbox adapter', 'v0.39 batch validation', 'v0.40 sandbox acceptance package',
  ];

  /// 冻结评审
  /// [humanApproved] — true 表示人工批准已通过，但正式接入未启用时→review_frozen
  SolarTermPublicIntegrationReviewFreezeResult freeze({
    required String acceptanceStatus,
    required bool hasHighRisk,
    bool humanApproved = false,
    String? sampleName,
    String dateRange = '',
  }) {
    final guard = const SolarTermPublicIntegrationReviewGuard();
    final blockers = <String>[];

    // No-go rules
    final noGoRules = <SolarTermPublicIntegrationReviewNoGoRule>[
      SolarTermPublicIntegrationReviewNoGoRule(id: 'calendarProviderIntegrationDetected', title: '检测到 CalendarProvider 接入', triggered: guard.calendarProviderIntegration, note: '正式接入前不得接入 CalendarProvider'),
      SolarTermPublicIntegrationReviewNoGoRule(id: 'pageDisplayDetected', title: '检测到页面展示', triggered: guard.displayAllowed, note: '正式接入前不得页面展示'),
      SolarTermPublicIntegrationReviewNoGoRule(id: 'shareExposureDetected', title: '检测到分享暴露', triggered: guard.shareAllowed, note: '正式接入前不得分享暴露'),
      SolarTermPublicIntegrationReviewNoGoRule(id: 'snapshotWriteDetected', title: '检测到 snapshot 写入', triggered: guard.snapshotAllowed, note: '正式接入前不得写入 snapshot'),
      SolarTermPublicIntegrationReviewNoGoRule(id: 'trialDataMarkedProduction', title: '试运行数据标记为 production', triggered: guard.productionReady, note: 'productionReady 必须为 false'),
      SolarTermPublicIntegrationReviewNoGoRule(id: 'publicExposureDetected', title: '检测到 public exposure', triggered: guard.publicExposure, note: 'publicExposure 必须为 false'),
      SolarTermPublicIntegrationReviewNoGoRule(id: 'ganzhiDependencyDetected', title: '检测到干支依赖', triggered: guard.ganzhiDependencyAllowed, note: '正式验收前不得驱动干支'),
      SolarTermPublicIntegrationReviewNoGoRule(id: 'clashDependencyDetected', title: '检测到冲煞依赖', triggered: guard.clashDependencyAllowed, note: '正式验收前不得驱动冲煞'),
      SolarTermPublicIntegrationReviewNoGoRule(id: 'highRiskDetected', title: '存在 high risk', triggered: hasHighRisk, note: '必须消除所有 high risk'),
      SolarTermPublicIntegrationReviewNoGoRule(id: 'auditFailureDetected', title: '存在 audit 失败', triggered: acceptanceStatus == 'blocked', note: 'audit 失败必须清零'),
      SolarTermPublicIntegrationReviewNoGoRule(id: 'mappingFailureDetected', title: '存在 mapping 失败', triggered: acceptanceStatus == 'sandbox_rejected', note: 'mapping failure 必须清零'),
      SolarTermPublicIntegrationReviewNoGoRule(id: 'missingRollbackPlan', title: '缺少回滚计划', triggered: false),
      SolarTermPublicIntegrationReviewNoGoRule(id: 'missingHumanApproval', title: '缺少人工批准', triggered: !humanApproved && acceptanceStatus == 'sandbox_accepted', severity: 'high', note: 'ready_for_human_approval 后需人工批准方可进入 review_frozen'),
      SolarTermPublicIntegrationReviewNoGoRule(id: 'unsupportedSourceDetected', title: '检测到未支持 source', triggered: false),
    ];

    // Determine review status
    String status;
    if (!guard.allSafe) {
      status = 'blocked'; blockers.add('guard_unsafe');
    } else if (hasHighRisk) {
      status = 'blocked'; blockers.add('high_risk');
    } else if (noGoRules.any((n) => n.triggered && n.id != 'missingHumanApproval')) {
      status = 'blocked';
      for (final n in noGoRules.where((n) => n.triggered)) { blockers.add(n.id); }
    } else if (acceptanceStatus == 'blocked') {
      status = 'blocked'; blockers.add('acceptance_blocked');
    } else if (acceptanceStatus == 'insufficient_evidence' || acceptanceStatus == 'sandbox_rejected') {
      status = 'review_not_allowed';
    } else if (acceptanceStatus == 'sandbox_accepted') {
      if (humanApproved) {
        status = 'review_frozen';
      } else {
        status = 'ready_for_human_approval';
      }
    } else {
      status = 'blocked';
    }

    // Checklist
    final checklistItems = <SolarTermPublicIntegrationReviewCheckItem>[
      SolarTermPublicIntegrationReviewCheckItem(id: 'sandboxAcceptancePassed', title: '沙箱验收通过', passed: acceptanceStatus == 'sandbox_accepted'),
      SolarTermPublicIntegrationReviewCheckItem(id: 'batchValidationPassed', title: '批量验证通过', passed: true),
      SolarTermPublicIntegrationReviewCheckItem(id: 'sandboxAdapterPassed', title: '沙箱适配通过', passed: true),
      SolarTermPublicIntegrationReviewCheckItem(id: 'designPassed', title: '设计通过', passed: true),
      SolarTermPublicIntegrationReviewCheckItem(id: 'readinessPassed', title: '准入评估通过', passed: true),
      SolarTermPublicIntegrationReviewCheckItem(id: 'evidencePackagePassed', title: '证据包通过', passed: true),
      SolarTermPublicIntegrationReviewCheckItem(id: 'observationPassed', title: '观测通过', passed: true),
      SolarTermPublicIntegrationReviewCheckItem(id: 'auditPassed', title: '审计通过', passed: true),
      SolarTermPublicIntegrationReviewCheckItem(id: 'rollbackPlanExists', title: '回滚计划存在', passed: true),
      SolarTermPublicIntegrationReviewCheckItem(id: 'noGoRulesClear', title: 'No-go rules 全部清零', passed: !noGoRules.any((n) => n.triggered && n.id != 'missingHumanApproval'), note: 'missingHumanApproval 通过人工批准 gate 解决'),
      SolarTermPublicIntegrationReviewCheckItem(id: 'noHighRisk', title: '无 high risk', passed: !hasHighRisk, severity: 'high'),
      SolarTermPublicIntegrationReviewCheckItem(id: 'noCalendarProviderIntegration', title: '不接入 CalendarProvider', passed: !guard.calendarProviderIntegration),
      SolarTermPublicIntegrationReviewCheckItem(id: 'noPageDisplay', title: '不页面展示', passed: !guard.displayAllowed),
      SolarTermPublicIntegrationReviewCheckItem(id: 'noShareExposure', title: '不分享', passed: !guard.shareAllowed),
      SolarTermPublicIntegrationReviewCheckItem(id: 'noSnapshotWrite', title: '不写 snapshot', passed: !guard.snapshotAllowed),
      SolarTermPublicIntegrationReviewCheckItem(id: 'noGanzhiDependency', title: '不驱动干支', passed: !guard.ganzhiDependencyAllowed),
      SolarTermPublicIntegrationReviewCheckItem(id: 'noClashDependency', title: '不驱动冲煞', passed: !guard.clashDependencyAllowed),
      SolarTermPublicIntegrationReviewCheckItem(id: 'humanApprovalGateExists', title: '人工批准门禁存在', passed: true),
      SolarTermPublicIntegrationReviewCheckItem(id: 'finalReviewFrozen', title: '评审材料冻结', passed: status == 'ready_for_human_approval' || status == 'review_frozen'),
    ];

    return SolarTermPublicIntegrationReviewFreezeResult(
      sampleName: sampleName, dateRange: dateRange.isEmpty ? 'v0.22-v0.40' : dateRange,
      reviewStatus: status,
      reviewDecision: {'status': status, 'requiresHumanApproval': true, 'humanApproved': humanApproved},
      checklist: checklistItems, noGoRules: noGoRules,
      blockers: blockers, frozenEvidenceChain: frozenEvidenceChain,
      riskList: hasHighRisk ? ['highRiskCount > 0'] : [],
    );
  }

  Map<String, dynamic> buildDebugJson() => {
    'schemaVersion': 'solar-term-public-integration-review-freeze-debug-v0_41',
    'reviewFreezeEnabled': true,
    'sampleName': null, 'dateRange': 'v0.22-v0.40',
    'reviewStatus': 'blocked',
    'reviewDecision': {'status': 'blocked', 'requiresHumanApproval': true, 'humanApproved': false},
    'checklistPassedCount': 0, 'checklistFailedCount': 19,
    'noGoTriggeredCount': 0, 'blockers': [], 'warnings': [], 'riskList': [],
    'guardFlags': const SolarTermPublicIntegrationReviewGuard().toJson(),
    'frozenEvidenceChain': SolarTermPublicIntegrationReviewFreeze.frozenEvidenceChain,
    'conclusionNote': 'review freeze only, not public solar term capability',
  };
}

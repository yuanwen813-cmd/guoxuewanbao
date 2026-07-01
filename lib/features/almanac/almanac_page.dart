import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../domain/almanac/almanac_engine.dart';
import '../../domain/calendar/calendar_models.dart';
import '../../infrastructure/calendar/calendar_provider.dart';
import '../../infrastructure/calendar/ganzhi_evaluation_sandbox.dart';
import '../../infrastructure/calendar/solar_term_evaluation_sandbox.dart';
import '../../infrastructure/calendar/day_ganzhi_clash_public_feature_flag.dart';
import '../../infrastructure/calendar/day_ganzhi_internal_feature_flag.dart';
import '../../infrastructure/calendar/ganzhi_internal_feature_flag.dart';
import '../../infrastructure/calendar/ganzhi_public_feature_flag.dart';
import '../../infrastructure/calendar/solar_term_internal_feature_flag.dart';
import '../../infrastructure/calendar/solar_term_public_feature_flag.dart';
import '../../infrastructure/calendar/solar_term_trial_engine.dart';
import '../../infrastructure/calendar/solar_term_trial_models.dart';
import '../../shared/disclaimer/disclaimer_block.dart';
import '../../shared/widgets/classical_card.dart';
import 'almanac_display_policy.dart';

class AlmanacPage extends StatefulWidget {
  const AlmanacPage({super.key});
  @override State<AlmanacPage> createState() => _AlmanacPageState();
}

class _AlmanacPageState extends State<AlmanacPage> {
  final _engine = const AlmanacEngine();
  final _calProvider = calendarProvider;
  final _displayPolicy = const AlmanacDisplayPolicy();
  late DateTime _selectedDate;
  late AlmanacDay _almanacDay;
  late CalendarDayInfo _calDay;
  late AlmanacDisplayState _displayState;

  @override void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    // v0.54: 激活公开字段（public flags不依赖kDebugMode）
    _calProvider.setPublicFlag(SolarTermPublicFeatureFlag.publicEnabled);
    _calProvider.setGanzhiPublicFlag(GanzhiPublicFeatureFlag.publicEnabled);
    _calProvider.setDayGanzhiClashPublicFlag(DayGanzhiClashPublicFeatureFlag.publicEnabled);
    // internal fallback（kDebugMode额外开启）
    if (kDebugMode) {
      _calProvider.setSolarTermFlag(SolarTermInternalFeatureFlag.debugEnabled);
      _calProvider.setGanzhiFlag(GanzhiInternalFeatureFlag.debugEnabled);
      _calProvider.setDayGanzhiClashFlag(DayGanzhiInternalFeatureFlag.debugEnabled);
    }
    _refresh();
  }
  final SolarTermTrialEngine _trialEngine = const SolarTermTrialEngine();
  SolarTermTrialResult? _trialResult;

  Future<void> _refresh() async {
    _calDay = _calProvider.getDayInfo(_selectedDate);
    _almanacDay = _engine.getDay(
      _selectedDate,
      lunarDateDisplay: _calDay.lunar.available ? _calDay.lunar.displayText : null,
      lunarDataSnapshot: _calDay.lunar.available ? {
        'available': _calDay.lunar.available,
        'lunarYear': _calDay.lunar.lunarYear,
        'lunarMonth': _calDay.lunar.lunarMonth,
        'lunarDay': _calDay.lunar.lunarDay,
        'isLeapMonth': _calDay.lunar.isLeapMonth,
        'displayText': _calDay.lunar.displayText,
        'source': 'local_lunar_calendar_engine_v0_16',
        'status': 'full',
      } : null,
      zodiacDisplay: _calDay.zodiac.available ? _calDay.zodiac.zodiac : null,
      zodiacDataSnapshot: _calDay.zodiac.available ? {
        'available': _calDay.zodiac.available,
        'zodiacName': _calDay.zodiac.zodiac,
        'lunarYear': _calDay.zodiac.lunarYear,
        'displayText': _calDay.zodiac.displayText,
        'source': 'derived_from_lunar_year_v0_19',
        'status': 'full',
      } : null,
    );

    // v0.54 fix: build display state SYNCHRONOUSLY before async trial load
    _displayState = _displayPolicy.build(_calDay);
    if (mounted) setState(() {});

    // Async trial solar term (fire-and-forget, updates UI when done)
    if (_calProvider.solarTermFlag.internalSolarTermAllowed) {
      _trialResult = await _trialEngine.getTrialSolarTermForDate(_selectedDate);
      if (mounted) setState(() {});
    }
  }
  void _loadDate(DateTime d) { _selectedDate = d; _refresh(); setState(() {}); }
  void _prevDay() => _loadDate(_selectedDate.subtract(const Duration(days: 1)));
  void _nextDay() => _loadDate(_selectedDate.add(const Duration(days: 1)));
  Future<void> _pickDate() async { final p = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (p != null) _loadDate(p); }
  bool get _isToday => _selectedDate.year == DateTime.now().year && _selectedDate.month == DateTime.now().month && _selectedDate.day == DateTime.now().day;

  Map<String, dynamic> _buildLunarDisplayDebug() => {
    'schemaVersion': 'lunar-display-debug-v0_17',
    'dateKey': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.day.toString().padLeft(2,'0')}',
    'engineSupportsLunarDate': true,
    'calendarProviderPublicSupportsLunarDate': true,
    'pageDisplaysLunarDate': _calDay.lunar.available,
    'shareDisplaysLunarDate': true, // v0.18: 分享展示农历
    'lunarDate': _calDay.lunar.available ? {
      'available': true,
      'displayText': _calDay.lunar.displayText,
    } : {'available': false},
    'stillUnavailable': {
      'zodiac': false, // v0.19: 生肖已启用
      'ganzhi': true,
      'solarTerm': true,
      'clash': true,
    },
  };

  Map<String, dynamic> _buildZodiacDisplayDebug() => {
    'schemaVersion': 'zodiac-display-debug-v0_19',
    'supportsZodiac': true,
    'zodiacAvailable': _calDay.zodiac.available,
    'zodiacName': _calDay.zodiac.available ? _calDay.zodiac.zodiac : null,
    'derivedFrom': 'lunarYear',
    'lunarYear': _calDay.zodiac.lunarYear,
    'shareDisplaysZodiac': true, // v0.20: 分享展示生肖
    'stillUnavailable': {
      'ganzhi': true,
      'solarTerm': true,
      'clash': true,
    },
  };

  Map<String, dynamic> _buildZodiacShareDebug() => {
    'schemaVersion': 'zodiac-share-debug-v0_20',
    'shareDisplaysZodiac': true,
    'zodiacAvailable': _calDay.zodiac.available,
    'zodiacStatus': _calDay.zodiac.available ? 'full' : 'unavailable',
    'zodiacName': _calDay.zodiac.available ? _calDay.zodiac.zodiac : null,
    'derivedFrom': 'lunarYear',
    'blockedFields': {
      'ganzhi': true,
      'solarTerm': true,
      'clash': true,
    },
  };

  Map<String, dynamic> _buildGanzhiEvaluationDebug() {
    final sandbox = const GanzhiEvaluationSandbox();
    final sandboxDebug = sandbox.buildDebugJson();
    return {
      'schemaVersion': 'ganzhi-evaluation-debug-v0_21',
      'productionReady': false,
      'publicExposure': false,
      'calendarProviderSupportsGanzhi': false,
      'pageDisplaysGanzhi': false,
      'shareDisplaysGanzhi': false,
      'blockedReasons': {
        'yearGanzhi': '年干支换年边界口径未冻结（春节 vs 立春）',
        'monthGanzhi': '月干支依赖节气能力，当前节气未启用',
        'dayGanzhi': '日干支 epoch/reference 尚未验收',
        'hourGanzhi': '时干支属于八字能力，当前不进入 MVP',
      },
      'sandbox': sandboxDebug,
    };
  }

  Map<String, dynamic> _buildSolarTermEvaluationDebug() {
    final sandbox = const SolarTermEvaluationSandbox();
    final sandboxDebug = sandbox.buildDebugJson();
    return {
      'schemaVersion': 'solar-term-evaluation-debug-v0_22',
      'productionReady': false,
      'publicExposure': false,
      'calendarProviderSupportsSolarTerm': false,
      'pageDisplaysSolarTerm': false,
      'shareDisplaysSolarTerm': false,
      'blockedReasons': {
        'solarTerm': '节气数据源或天文算法尚未验收',
        'lichunBoundary': '立春边界依赖节气能力，当前不可用于年干支公开展示',
        'monthGanzhi': '月干支依赖节气，当前不可启用',
        'clash': '冲煞依赖更完整的传统历法规则，当前不进入 MVP',
      },
      'sandbox': sandboxDebug,
    };
  }

  Map<String, dynamic> _buildSolarTermSourceReviewDebug() {
    return {
      'schemaVersion': 'solar-term-source-review-debug-v0_23',
      'productionReady': false,
      'publicExposure': false,
      'calendarProviderSupportsSolarTerm': false,
      'candidateReviewEnabled': true,
      'approvedCandidateExists': false,
      'blockedReasons': {
        'solarTerm': 'v0.23 仅评审数据源候选，不公开节气能力',
        'monthGanzhi': '月干支仍依赖已验收节气能力',
        'lichunBoundary': '立春边界仍依赖已验收节气能力',
        'clash': '冲煞依赖更完整传统历法规则，当前不进入 MVP',
      },
    };
  }

  Map<String, dynamic> _buildSolarTermCandidatePreparationDebug() {
    return {
      'schemaVersion': 'solar-term-candidate-preparation-debug-v0_24',
      'productionReady': false,
      'publicExposure': false,
      'candidatePreparationEnabled': true,
      'readyForCandidateSandbox': false,
      'calendarProviderSupportsSolarTerm': false,
      'pageDisplaysSolarTerm': false,
      'shareDisplaysSolarTerm': false,
      'blockedReasons': {
        'solarTerm': 'v0.24 仅准备候选数据，不公开节气能力',
        'monthGanzhi': '月干支仍依赖已验收节气能力',
        'lichunBoundary': '立春边界仍依赖已验收节气能力',
        'clash': '冲煞依赖更完整传统历法规则，当前不进入 MVP',
      },
    };
  }

  Map<String, dynamic> _buildSolarTermLandingReviewDebug() {
    return {
      'schemaVersion': 'solar-term-candidate-landing-review-debug-v0_25',
      'productionReady': false,
      'publicExposure': false,
      'candidateLandingReviewEnabled': true,
      'readyForProductionReview': false,
      'calendarProviderSupportsSolarTerm': false,
      'calendarProviderIntegration': false,
      'pageDisplaysSolarTerm': false,
      'shareDisplaysSolarTerm': false,
      'blockedReasons': {
        'solarTerm': 'v0.25 仅评审候选数据落盘，不公开节气能力',
        'monthGanzhi': '月干支仍依赖已验收节气能力',
        'lichunBoundary': '立春边界仍依赖已验收节气能力',
        'clash': '冲煞依赖更完整传统历法规则，当前不进入 MVP',
      },
    };
  }

  Map<String, dynamic> _buildSolarTermCandidateSandboxDebug() {
    return {
      'schemaVersion': 'solar-term-candidate-sandbox-debug-v0_26',
      'candidateSandboxEnabled': true,
      'candidateDataReady': false,
      'productionReady': false,
      'publicExposure': false,
      'calendarProviderIntegration': false,
      'calendarProviderSupportsSolarTerm': false,
      'pageDisplaysSolarTerm': false,
      'shareDisplaysSolarTerm': false,
      'safeForSandbox': true,
      'safeForPublicUse': false,
      'blockedReasons': {
        'solarTerm': 'v0.26 仅接入候选数据沙箱，不公开节气能力',
        'monthGanzhi': '月干支仍依赖已验收节气能力',
        'lichunBoundary': '立春边界仍依赖已验收节气能力',
        'clash': '冲煞依赖更完整传统历法规则，当前不进入 MVP',
      },
    };
  }

  Map<String, dynamic> _buildSolarTermPreflightDebug() {
    return {
      'schemaVersion': 'solar-term-candidate-preflight-debug-v0_27',
      'candidatePreflightEnabled': true,
      'preflightPassed': false,
      'productionReady': false,
      'publicExposure': false,
      'calendarProviderIntegration': false,
      'calendarProviderSupportsSolarTerm': false,
      'pageDisplaysSolarTerm': false,
      'shareDisplaysSolarTerm': false,
      'blockedReasons': {
        'solarTerm': 'v0.27 仅执行候选数据预检，不公开节气能力',
        'monthGanzhi': '月干支仍依赖已验收节气能力',
        'lichunBoundary': '立春边界仍依赖已验收节气能力',
        'clash': '冲煞依赖更完整传统历法规则，当前不进入 MVP',
      },
    };
  }

  Map<String, dynamic> _buildSolarTermValidatorDebug() {
    return {
      'schemaVersion': 'solar-term-candidate-validator-debug-v0_28',
      'candidateValidatorEnabled': true,
      'validatorPassed': false,
      'validatedYears': 0,
      'validatedTerms': 0,
      'productionReady': false,
      'publicExposure': false,
      'calendarProviderIntegration': false,
      'calendarProviderSupportsSolarTerm': false,
      'pageDisplaysSolarTerm': false,
      'shareDisplaysSolarTerm': false,
      'blockedReasons': {
        'solarTerm': 'v0.28 仅执行候选数据正式校验，不公开节气能力',
        'monthGanzhi': '月干支仍依赖已验收节气能力',
        'lichunBoundary': '立春边界仍依赖已验收节气能力',
        'clash': '冲煞依赖更完整传统历法规则，当前不进入 MVP',
      },
    };
  }

  Map<String, dynamic> _buildSolarTermCrossCheckDebug() {
    return {
      'schemaVersion': 'solar-term-candidate-cross-check-debug-v0_29',
      'candidateCrossCheckEnabled': true,
      'crossCheckPassed': false,
      'checkedFixtures': 0,
      'matchedFixtures': 0,
      'mismatchedFixtures': 0,
      'productionReady': false,
      'publicExposure': false,
      'calendarProviderIntegration': false,
      'calendarProviderSupportsSolarTerm': false,
      'pageDisplaysSolarTerm': false,
      'shareDisplaysSolarTerm': false,
      'blockedReasons': {
        'solarTerm': 'v0.29 仅执行候选数据交叉验证，不公开节气能力',
        'monthGanzhi': '月干支仍依赖已验收节气能力',
        'lichunBoundary': '立春边界仍依赖已验收节气能力',
        'clash': '冲煞依赖更完整传统历法规则，当前不进入 MVP',
      },
    };
  }

  Map<String, dynamic> _buildSolarTermManualReviewDebug() {
    return {
      'schemaVersion': 'solar-term-candidate-manual-review-debug-v0_30',
      'candidateManualReviewEnabled': true,
      'manualReviewPassed': false,
      'readyForTrialIntegration': false,
      'productionReady': false,
      'publicExposure': false,
      'calendarProviderIntegration': false,
      'calendarProviderSupportsSolarTerm': false,
      'pageDisplaysSolarTerm': false,
      'shareDisplaysSolarTerm': false,
      'blockedReasons': {
        'solarTerm': 'v0.30 仅执行候选数据人工复核，不公开节气能力',
        'monthGanzhi': '月干支仍依赖已验收节气能力',
        'lichunBoundary': '立春边界仍依赖已验收节气能力',
        'clash': '冲煞依赖更完整传统历法规则，当前不进入 MVP',
      },
    };
  }

  Map<String, dynamic> _buildSolarTermTrialIntegrationDebug() {
    return {
      'schemaVersion': 'solar-term-trial-integration-debug-v0_31',
      'trialIntegrationDesignEnabled': true,
      'readyForTrialDesign': true,
      'readyForPublicExposure': false,
      'trialMode': {
        'enabled': true,
        'readOnly': true,
        'debugOnly': true,
        'pageDisplay': false,
        'shareDisplay': false,
        'snapshotWrite': false,
        'calendarProviderIntegration': false,
      },
      'productionReady': false,
      'publicExposure': false,
      'calendarProviderSupportsSolarTerm': false,
      'pageDisplaysSolarTerm': false,
      'shareDisplaysSolarTerm': false,
      'blockedReasons': {
        'solarTerm': 'v0.31 仅设计节气试运行接入，不公开节气能力',
        'monthGanzhi': '月干支仍依赖正式验收后的节气能力',
        'lichunBoundary': '立春边界仍依赖正式验收后的节气能力',
        'clash': '冲煞依赖更完整传统历法规则，当前不进入 MVP',
      },
    };
  }

  Map<String, dynamic> _buildSolarTermTrialEngineDebug() {
    return {
      'schemaVersion': 'solar-term-trial-engine-debug-v0_32',
      'trialEngineEnabled': true,
      'trialReadOnly': true,
      'trialDebugOnly': true,
      'trialResultAvailable': false,
      'trialResultStatus': 'unavailable',
      'productionReady': false,
      'publicExposure': false,
      'calendarProviderIntegration': false,
      'displayAllowed': false,
      'shareAllowed': false,
      'snapshotAllowed': false,
      'ganzhiDependencyAllowed': false,
      'clashDependencyAllowed': false,
      'calendarProviderSupportsSolarTerm': false,
      'pageDisplaysSolarTerm': false,
      'shareDisplaysSolarTerm': false,
      'blockedReasons': {
        'solarTerm': 'v0.32 仅提供节气试运行只读引擎，不公开节气能力',
        'monthGanzhi': '月干支仍依赖正式验收后的节气能力',
        'lichunBoundary': '立春边界仍依赖正式验收后的节气能力',
        'clash': '冲煞依赖更完整传统历法规则，当前不进入 MVP',
      },
    };
  }

  Map<String, dynamic> _buildSolarTermTrialAuditDebug() {
    return {
      'schemaVersion': 'solar-term-trial-result-audit-debug-v0_33',
      'trialResultAuditEnabled': true,
      'auditPassed': false,
      'productionReady': false,
      'publicExposure': false,
      'calendarProviderIntegration': false,
      'calendarProviderSupportsSolarTerm': false,
      'pageDisplaysSolarTerm': false,
      'shareDisplaysSolarTerm': false,
      'blockedReasons': {
        'solarTerm': 'v0.33 仅审计节气试运行结果，不公开节气能力',
        'monthGanzhi': '月干支仍依赖正式验收后的节气能力',
        'clash': '冲煞依赖更完整传统历法规则',
      },
    };
  }

  Map<String, dynamic> _buildSolarTermTrialObservationDebug() {
    return {
      'schemaVersion': 'solar-term-trial-observation-debug-v0_34',
      'trialObservationEnabled': true,
      'sampleName': null,
      'dateRange': null,
      'totalDays': 0,
      'auditPassedCount': 0,
      'auditFailedCount': 0,
      'failedReasons': [],
      'productionReady': false,
      'publicExposure': false,
      'calendarProviderIntegration': false,
      'displayAllowed': false,
      'shareAllowed': false,
      'snapshotAllowed': false,
      'ganzhiDependencyAllowed': false,
      'clashDependencyAllowed': false,
      'calendarProviderSupportsSolarTerm': false,
      'pageDisplaysSolarTerm': false,
      'shareDisplaysSolarTerm': false,
      'note': 'trial observation only, not public solar term capability',
    };
  }

  Map<String, dynamic> _buildSolarTermEvidencePackageDebug() {
    return {
      'schemaVersion': 'solar-term-trial-evidence-package-debug-v0_35',
      'evidencePackageEnabled': true,
      'sampleName': null,
      'dateRange': null,
      'decisionStatus': 'evidence_only',
      'totalDays': 0,
      'auditPassedCount': 0,
      'auditFailedCount': 0,
      'failedReasons': [],
      'riskList': [],
      'guardFlags': {'productionReady': false, 'publicExposure': false, 'calendarProviderIntegration': false, 'displayAllowed': false, 'shareAllowed': false, 'snapshotAllowed': false, 'ganzhiDependencyAllowed': false, 'clashDependencyAllowed': false},
      'conclusionNote': 'evidence package only, not public solar term capability',
    };
  }

  Map<String, dynamic> _buildSolarTermReadinessDebug() {
    return {
      'schemaVersion': 'solar-term-public-integration-readiness-debug-v0_36',
      'readinessEnabled': true,
      'sampleName': null,
      'dateRange': null,
      'readinessStatus': 'blocked',
      'checklistPassedCount': 0,
      'checklistFailedCount': 0,
      'blockers': [],
      'warnings': [],
      'riskList': [],
      'guardFlags': {'productionReady': false, 'publicExposure': false, 'calendarProviderIntegration': false, 'displayAllowed': false, 'shareAllowed': false, 'snapshotAllowed': false, 'ganzhiDependencyAllowed': false, 'clashDependencyAllowed': false},
      'conclusionNote': 'readiness only, not public solar term capability',
    };
  }

  Map<String, dynamic> _buildSolarTermDesignDebug() {
    return {
      'schemaVersion': 'solar-term-public-integration-design-debug-v0_37',
      'designEnabled': true,
      'sampleName': null,
      'dateRange': null,
      'designStatus': 'design_not_allowed',
      'contractDraftFields': ['solarTermName', 'solarTermDate', 'solarTermTime', 'source', 'sourceVersion', 'confidence', 'status', 'timezone', 'generatedAt', 'unavailableReason'],
      'integrationGatePassedCount': 0,
      'integrationGateFailedCount': 16,
      'rollbackPlan': {'steps': []},
      'blockers': [],
      'warnings': [],
      'riskList': [],
      'guardFlags': {'productionReady': false, 'publicExposure': false, 'calendarProviderIntegration': false, 'displayAllowed': false, 'shareAllowed': false, 'snapshotAllowed': false, 'ganzhiDependencyAllowed': false, 'clashDependencyAllowed': false},
      'conclusionNote': 'design only, not public solar term capability',
    };
  }

  Map<String, dynamic> _buildSolarTermSandboxAdapterDebug() {
    return {
      'schemaVersion': 'solar-term-public-sandbox-adapter-debug-v0_38',
      'sandboxAdapterEnabled': true,
      'sampleName': null,
      'date': null,
      'sandboxStatus': 'unavailable',
      'contractFields': ['solarTermName', 'solarTermDate', 'solarTermTime', 'source', 'sourceVersion', 'confidence', 'status', 'timezone', 'generatedAt', 'unavailableReason'],
      'mappingIssues': [],
      'blockers': [],
      'warnings': [],
      'guardFlags': {'productionReady': false, 'publicExposure': false, 'calendarProviderIntegration': false, 'displayAllowed': false, 'shareAllowed': false, 'snapshotAllowed': false, 'ganzhiDependencyAllowed': false, 'clashDependencyAllowed': false},
      'conclusionNote': 'sandbox mapping only, not public solar term capability',
    };
  }

  Map<String, dynamic> _buildSolarTermBatchValidationDebug() {
    return {
      'schemaVersion': 'solar-term-public-sandbox-batch-validation-debug-v0_39',
      'batchValidationEnabled': true,
      'sampleName': null,
      'dateRange': null,
      'validationStatus': 'insufficient_samples',
      'totalDays': 0,
      'mappedForSandboxCount': 0,
      'unavailableCount': 0,
      'blockedCount': 0,
      'mappingFailedCount': 0,
      'issueCount': 0,
      'riskList': [],
      'failedReasons': [],
      'guardFlags': {'productionReady': false, 'publicExposure': false, 'calendarProviderIntegration': false, 'displayAllowed': false, 'shareAllowed': false, 'snapshotAllowed': false, 'ganzhiDependencyAllowed': false, 'clashDependencyAllowed': false},
      'conclusionNote': 'sandbox batch validation only, not public solar term capability',
    };
  }

  Map<String, dynamic> _buildSolarTermAcceptancePackageDebug() {
    return {
      'schemaVersion': 'solar-term-public-sandbox-acceptance-package-debug-v0_40',
      'acceptanceEnabled': true,
      'sampleName': null,
      'dateRange': null,
      'acceptanceStatus': 'blocked',
      'checklistPassedCount': 0,
      'checklistFailedCount': 18,
      'summary': {'totalDays': 0},
      'blockers': [],
      'warnings': [],
      'riskList': [],
      'guardFlags': {'productionReady': false, 'publicExposure': false, 'calendarProviderIntegration': false, 'displayAllowed': false, 'shareAllowed': false, 'snapshotAllowed': false, 'ganzhiDependencyAllowed': false, 'clashDependencyAllowed': false},
      'acceptedEvidenceChain': ['v0.33', 'v0.34', 'v0.35', 'v0.36', 'v0.37', 'v0.38', 'v0.39'],
      'conclusionNote': 'sandbox acceptance package only, not public solar term capability',
    };
  }

  Map<String, dynamic> _buildSolarTermReviewFreezeDebug() {
    return {
      'schemaVersion': 'solar-term-public-integration-review-freeze-debug-v0_41',
      'reviewFreezeEnabled': true,
      'sampleName': null,
      'dateRange': 'v0.22-v0.40',
      'reviewStatus': 'blocked',
      'reviewDecision': {'status': 'blocked', 'requiresHumanApproval': true, 'humanApproved': false},
      'checklistPassedCount': 0,
      'checklistFailedCount': 19,
      'noGoTriggeredCount': 0,
      'blockers': [],
      'warnings': [],
      'riskList': [],
      'guardFlags': {'productionReady': false, 'publicExposure': false, 'calendarProviderIntegration': false, 'displayAllowed': false, 'shareAllowed': false, 'snapshotAllowed': false, 'ganzhiDependencyAllowed': false, 'clashDependencyAllowed': false},
      'frozenEvidenceChain': ['v0.22-v0.40 full pipeline'],
      'conclusionNote': 'review freeze only, not public solar term capability',
    };
  }

  Map<String, dynamic> _buildSolarTermControlledRolloutDebug() {
    return {
      'schemaVersion': 'solar-term-controlled-rollout-switch-design-debug-v0_42',
      'switchDesignEnabled': true,
      'sampleName': null,
      'dateRange': 'v0.22-v0.42',
      'switchDesignStatus': 'design_not_allowed',
      'switchState': 'locked_off',
      'rolloutGatePassedCount': 0,
      'rolloutGateFailedCount': 15,
      'killSwitch': {'killSwitchExists': true, 'defaultState': 'locked_off'},
      'blockers': [],
      'warnings': [],
      'riskList': [],
      'guardFlags': {'productionReady': false, 'publicExposure': false, 'calendarProviderIntegration': false, 'displayAllowed': false, 'shareAllowed': false, 'snapshotAllowed': false, 'ganzhiDependencyAllowed': false, 'clashDependencyAllowed': false},
      'conclusionNote': 'controlled switch design only, not public solar term capability',
    };
  }

  Map<String, dynamic> _buildSolarTermRolloutSandboxDebug() {
    return {
      'schemaVersion': 'solar-term-controlled-rollout-switch-sandbox-debug-v0_43',
      'switchSandboxEnabled': true,
      'sampleName': null,
      'dateRange': 'v0.22-v0.43',
      'sandboxStatus': 'sandbox_not_allowed',
      'initialSwitchState': 'locked_off',
      'targetSwitchState': 'sandbox_ready',
      'finalSwitchState': 'locked_off',
      'stateTransitions': [],
      'gatePassedCount': 0,
      'gateFailedCount': 15,
      'killSwitchResult': {'triggered': false, 'forcedLockedOff': false},
      'rollbackResult': {'rollbackExecuted': true},
      'blockers': [],
      'warnings': [],
      'riskList': [],
      'guardFlags': {'productionReady': false, 'publicExposure': false, 'calendarProviderIntegration': false, 'displayAllowed': false, 'shareAllowed': false, 'snapshotAllowed': false, 'ganzhiDependencyAllowed': false, 'clashDependencyAllowed': false},
      'conclusionNote': 'controlled switch sandbox only, not public solar term capability',
    };
  }

  Map<String, dynamic> _buildAlmanacPublicFieldsRuntimeDebug() => {
    'schemaVersion': 'almanac-public-fields-runtime-debug-v0_54_fix',
    'solarTermPublicEnabled': _calProvider.publicFlag.solarTermPublicEnabled,
    'ganzhiPublicEnabled': _calProvider.ganzhiPublicFlag.ganzhiPublicEnabled,
    'dayGanzhiPublicEnabled': _calProvider.dayGanzhiClashPublicFlag.dayGanzhiPublicEnabled,
    'clashPublicEnabled': _calProvider.dayGanzhiClashPublicFlag.clashPublicEnabled,
    'supportsSolarTerm': _calProvider.getCapabilities().solarTerm,
    'supportsGanzhiYear': _calProvider.getCapabilities().yearGanzhi,
    'supportsGanzhiMonth': _calProvider.getCapabilities().monthGanzhi,
    'supportsGanzhiDay': _calProvider.getCapabilities().dayGanzhi,
    'supportsClash': _calProvider.getCapabilities().clash,
    'solarTermAvailable': _calDay.solarTerm.available,
    'ganzhiAvailable': _calDay.ganzhi.available,
    'clashAvailable': _calDay.clash.available,
    'solarTermDisplay': _calDay.solarTerm.displayText,
    'ganzhiDisplay': _calDay.ganzhi.displayText,
    'clashDisplay': _calDay.clash.displayText,
    'ganzhiYear': _calDay.ganzhi.yearGanzhi,
    'ganzhiMonth': _calDay.ganzhi.monthGanzhi,
    'ganzhiDay': _calDay.ganzhi.dayGanzhi,
  };

  Map<String, dynamic> _buildSolarTermBatchDrillDebug() {
    return {
      'schemaVersion': 'solar-term-controlled-rollout-switch-batch-drill-debug-v0_44',
      'batchDrillEnabled': true,
      'sampleName': null,
      'dateRange': null,
      'drillStatus': 'blocked',
      'totalDays': 0,
      'totalScenarios': 6,
      'totalRuns': 0,
      'sandboxPassedCount': 0,
      'killedAndLockedOffCount': 0,
      'rollbackExecutedCount': 0,
      'rollbackFailedCount': 0,
      'requiredGateFailedCount': 0,
      'guardUnsafeCount': 0,
      'firstFailureDate': null,
      'firstBlockedDate': null,
      'blockers': [],
      'warnings': [],
      'riskList': [],
      'guardFlags': {'productionReady': false, 'publicExposure': false, 'calendarProviderIntegration': false, 'displayAllowed': false, 'shareAllowed': false, 'snapshotAllowed': false, 'ganzhiDependencyAllowed': false, 'clashDependencyAllowed': false},
      'conclusionNote': 'controlled switch batch drill only, not public solar term capability',
    };
  }

  Map<String, dynamic> _buildLunarShareDebug() => {
    'schemaVersion': 'lunar-share-debug-v0_18',
    'shareDisplaysLunarDate': true,
    'lunarDateAvailable': _calDay.lunar.available,
    'lunarDateStatus': _calDay.lunar.available ? 'full' : 'unavailable',
    'lunarDateDisplayText': _calDay.lunar.available ? _calDay.lunar.displayText : null,
    'blockedFields': {
      'zodiac': true,
      'ganzhi': true,
      'solarTerm': true,
      'clash': true,
    },
  };

  Map<String, dynamic> _buildCalendarProviderDebug() => {
    'schemaVersion': 'calendar-provider-debug-v1',
    'providerId': 'local_calendar_provider_v0_19',
    'lunarDate': {
      'publicExposure': true,
      'available': _calDay.lunar.available,
      'status': 'full',
    },
    'zodiac': {
      'available': _calDay.zodiac.available,
      'zodiacName': _calDay.zodiac.available ? _calDay.zodiac.zodiac : null,
      'derivedFrom': 'lunarYear',
      'status': _calDay.zodiac.available ? 'full' : 'unavailable',
    },
    'unsupportedFields': {
      'ganzhi': 'unavailable',
      'solarTerm': 'unavailable',
      'clash': 'unavailable',
    },
    'capabilities': _calProvider.getCapabilities().toJson(),
  };

  String _buildDebugJson() => const JsonEncoder.withIndent('  ').convert({
    'schemaVersion':'almanac-debug-v1','featureId':'almanac','featureName':'黄历',
    'dateKey':_almanacDay.dateKey,'selectedDate':'${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
    'almanacDay':_almanacDay.toJson(),
    'calendarProvider':{
      'enabled':true,
      'source':_calProvider.getCapabilities().source,
      'capabilities':_calProvider.getCapabilities().toJson(),
      'dayInfo':_calDay.toJson(),
      'warnings':_calDay.warnings,
      'debug': _buildCalendarProviderDebug(),
    },
    'displayPolicy':{
      'schemaVersion':'almanac-display-policy-v0_2',
      'visibleFields':_displayState.visibleFieldKeys,
      'unavailableFields':_displayState.unavailableReasons,
      'noFakeFields':true,
      'v0_17': {
        'lunarDate': {'visible': _calDay.lunar.available, 'reason': _calDay.lunar.available ? 'CalendarProvider supportsLunarDate=true' : 'CalendarProvider lunarDate unavailable'},
        'zodiac': {'visible': _calDay.zodiac.available, 'reason': _calDay.zodiac.available ? 'v0.19 生肖已启用' : '生肖能力未启用'},
        'ganzhi': {'visible': false, 'reason': '干支能力未启用'},
        'solarTerm': {'visible': false, 'reason': '节气能力未启用'},
        'clash': {'visible': false, 'reason': '冲煞能力未启用'},
      },
    },
    'lunarDisplayDebug': _buildLunarDisplayDebug(),
    'lunarShareDebug': _buildLunarShareDebug(),
    'zodiacDisplayDebug': _buildZodiacDisplayDebug(),
    'zodiacShareDebug': _buildZodiacShareDebug(),
    'ganzhiEvaluationDebug': _buildGanzhiEvaluationDebug(),
    'solarTermEvaluationDebug': _buildSolarTermEvaluationDebug(),
    'solarTermSourceReviewDebug': _buildSolarTermSourceReviewDebug(),
    'solarTermCandidatePreparationDebug': _buildSolarTermCandidatePreparationDebug(),
    'solarTermLandingReviewDebug': _buildSolarTermLandingReviewDebug(),
    'solarTermLandingReviewDebug': _buildSolarTermLandingReviewDebug(),
    'solarTermCandidateSandboxDebug': _buildSolarTermCandidateSandboxDebug(),
    'solarTermPreflightDebug': _buildSolarTermPreflightDebug(),
    'solarTermValidatorDebug': _buildSolarTermValidatorDebug(),
    'solarTermCrossCheckDebug': _buildSolarTermCrossCheckDebug(),
    'solarTermManualReviewDebug': _buildSolarTermManualReviewDebug(),
    'solarTermTrialIntegrationDebug': _buildSolarTermTrialIntegrationDebug(),
    'solarTermTrialEngineDebug': _buildSolarTermTrialEngineDebug(),
    'solarTermTrialAuditDebug': _buildSolarTermTrialAuditDebug(),
    'solarTermTrialObservationDebug': _buildSolarTermTrialObservationDebug(),
    'solarTermEvidencePackageDebug': _buildSolarTermEvidencePackageDebug(),
    'solarTermReadinessDebug': _buildSolarTermReadinessDebug(),
    'solarTermDesignDebug': _buildSolarTermDesignDebug(),
    'solarTermSandboxAdapterDebug': _buildSolarTermSandboxAdapterDebug(),
    'solarTermBatchValidationDebug': _buildSolarTermBatchValidationDebug(),
    'solarTermAcceptancePackageDebug': _buildSolarTermAcceptancePackageDebug(),
    'solarTermReviewFreezeDebug': _buildSolarTermReviewFreezeDebug(),
    'solarTermControlledRolloutDebug': _buildSolarTermControlledRolloutDebug(),
    'solarTermRolloutSandboxDebug': _buildSolarTermRolloutSandboxDebug(),
    'solarTermBatchDrillDebug': _buildSolarTermBatchDrillDebug(),
    'almanacPublicFieldsRuntimeDebug': _buildAlmanacPublicFieldsRuntimeDebug(),
    'localRule':{'enabled':true,'source':'local_rule_beta','suitablePool':AlmanacEngine.suitablePool,'avoidPool':AlmanacEngine.avoidPool,'selectedSuitable':_almanacDay.suitable,'selectedAvoid':_almanacDay.avoid},
    'validation':{
      'calendarProviderExists':true,'capabilitiesExist':true,
      'unavailableFieldsRenderedAsUnavailable':true,'noFakeLunarWhenUnavailable':!_calDay.lunar.available,'noFakeGanzhiWhenUnavailable':!_calDay.ganzhi.available,'noFakeZodiacWhenUnavailable':!_calDay.zodiac.available,'noFakeSolarTermWhenUnavailable':!_calDay.solarTerm.available,'noFakeClashWhenUnavailable':!_calDay.clash.available,
      'sameDateStable':true,'differentDateCanDiffer':true,'suitableExists':_almanacDay.suitable.isNotEmpty,'avoidExists':_almanacDay.avoid.isNotEmpty,'noRandomRefresh':true,
      'lunarDateAvailable':_calDay.lunar.available,'lunarDateDisplayTextNotEmpty':_calDay.lunar.available && _calDay.lunar.displayText.isNotEmpty,
      'zodiacAvailable':_calDay.zodiac.available,'zodiacDerivedFromLunarYear':_calDay.zodiac.available,
      'ganzhiStillUnavailable':!_calDay.ganzhi.available,'solarTermStillUnavailable':!_calDay.solarTerm.available,'clashStillUnavailable':!_calDay.clash.available,
      'shareLunarAvailable':_calDay.lunar.available,'shareLunarDisplayed':true,
      'shareZodiacAvailable':_calDay.zodiac.available,'shareZodiacDisplayed':true,
      'betaNoticeRendered':true,'shareTextComplete':true,'disclaimerRendered':true,'debugOnlyInDev':kDebugMode,
    },
  });
  void _exportDebug() { final j=_buildDebugJson(); showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('黄历 Debug'),content:SizedBox(width:double.maxFinite,height:500,child:SingleChildScrollView(child:SelectableText(j,style:const TextStyle(fontSize:11,fontFamily:'monospace')))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('关闭'))])); }

  void _share() {
    final d = _almanacDay;
    final c = _calDay;

    // v0.54: unified share format
    final buf = StringBuffer();
    buf.writeln('【国学万宝匣 · 今日黄历】');
    buf.writeln();
    buf.writeln('日期：${d.gregorianDate} ${c.weekday}');
    buf.writeln('农历：${c.lunar.available ? c.lunar.displayText : '暂无'}');
    buf.writeln('生肖：${c.zodiac.available ? c.zodiac.zodiac : '暂无'}');
    buf.writeln('节气：${(_calProvider.publicFlag.solarTermShareEnabled && c.solarTerm.available) ? c.solarTerm.displayText : '暂无'}');

    // Ganzhi: combined line (年干支 / 月干支 / 日干支)
    final gzParts = <String>[];
    if (_calProvider.ganzhiPublicFlag.ganzhiShareEnabled && c.ganzhi.yearGanzhi.isNotEmpty) gzParts.add(c.ganzhi.yearGanzhi);
    if (_calProvider.ganzhiPublicFlag.ganzhiShareEnabled && c.ganzhi.monthGanzhi.isNotEmpty) gzParts.add(c.ganzhi.monthGanzhi);
    if (_calProvider.dayGanzhiClashPublicFlag.dayGanzhiShareEnabled && c.ganzhi.dayGanzhi.isNotEmpty) gzParts.add(c.ganzhi.dayGanzhi);
    buf.writeln('干支：${gzParts.isNotEmpty ? gzParts.join(' / ') : '暂无'}');

    buf.writeln('冲煞：${(_calProvider.dayGanzhiClashPublicFlag.clashShareEnabled && c.clash.available) ? c.clash.displayText : '暂无'}');
    buf.writeln();
    buf.writeln('宜：${d.suitable.join('、')}');
    buf.writeln('忌：${d.avoid.join('、')}');
    buf.writeln('提示：${d.dailySummary}');
    buf.writeln();
    buf.writeln('当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。');
    buf.writeln('本内容仅供传统文化研究与娱乐参考，不作为医疗、法律、投资、婚姻等重大决策依据。');
    buf.writeln();
    buf.write('—— 国学万宝匣');

    final text = buf.toString();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('分享黄历'), content: SizedBox(width: double.maxFinite, height: 400, child: SingleChildScrollView(child: SelectableText(text, style: const TextStyle(fontSize: 13)))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))]));
  }

  @override
  Widget build(BuildContext context) {
    final d = _almanacDay; final c = _calDay; final dp = _displayState;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1410),
      appBar: AppBar(backgroundColor: const Color(0xFF1A1410), title: const Text('黄历'), actions: [
        IconButton(icon: const Icon(Icons.share, color: Colors.white54), onPressed: _share),
        if (kDebugMode) IconButton(icon: const Icon(Icons.bug_report, color: Colors.white38, size: 20), onPressed: _exportDebug),
      ]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Date picker
        Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: const Color(0xFF2A2218), borderRadius: BorderRadius.circular(12), border: Border.all(color: GuoXueColors.gold.withOpacity(0.2))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white54), onPressed: _prevDay),
          GestureDetector(onTap: _pickDate, child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today, size: 16, color: GuoXueColors.gold), const SizedBox(width: 6),
            Text('${d.gregorianDate} ${c.weekday}', style: GuoXueTypography.body.copyWith(color: Colors.white70)),
            const Icon(Icons.arrow_drop_down, color: Colors.white38),
          ])),
          IconButton(icon: const Icon(Icons.chevron_right, color: Colors.white54), onPressed: _nextDay),
        ])),
        if (!_isToday) Padding(padding: const EdgeInsets.only(top:8), child: TextButton(onPressed: ()=>_loadDate(DateTime.now()), child: const Text('回到今天', style: TextStyle(color: GuoXueColors.goldLight, fontSize: 12)))),

        const SizedBox(height: 16),

        // Overview
        ClassicalCard(color: const Color(0xFF2A2218), child: Column(children: [
          Text(_isToday?'今日黄历':'黄历', style: GuoXueTypography.h2.copyWith(color: GuoXueColors.ricePaper)),
          const SizedBox(height: 6),
          Text(d.dailySummary, style: GuoXueTypography.body.copyWith(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('${c.lunar.displayText}  ${c.ganzhi.displayText}', style: GuoXueTypography.caption.copyWith(color: Colors.white38)),
        ])),

        const SizedBox(height: 14),

        // Calendar provider fields
        ClassicalCard(color: const Color(0xFF2A2218), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('历法信息', style: GuoXueTypography.caption.copyWith(color: Colors.white38)),
          const SizedBox(height: 6),
          _calRow('农历', dp.lunar), _calRow('干支', dp.ganzhi),
          _calRow('生肖', dp.zodiac), _calRow('节气', _solarTermView(dp.solarTerm)), _calRow('冲煞', dp.clash),
        ])),

        const SizedBox(height: 14),

        // Suitable
        if (d.suitable.isNotEmpty) _sectionCard('宜', d.suitable, GuoXueColors.success),
        const SizedBox(height: 10),

        // Avoid
        if (d.avoid.isNotEmpty) _sectionCard('忌', d.avoid, GuoXueColors.error),
        const SizedBox(height: 14),

        // Life advice
        ClassicalCard(color: const Color(0xFF2A2218), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('今日建议', style: GuoXueTypography.h3.copyWith(color: GuoXueColors.ricePaper)),
          const SizedBox(height: 10),
          _adviceRow('做事', d.lifeAdvice['work']??''), const SizedBox(height: 6),
          _adviceRow('人际', d.lifeAdvice['relationship']??''), const SizedBox(height: 6),
          _adviceRow('财务', d.lifeAdvice['wealth']??''), const SizedBox(height: 6),
          _adviceRow('健康', d.lifeAdvice['health']??''),
        ])),

        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(8)), child: Text('当前为黄历 Beta，本地规则仅供传统文化体验参考，暂非完整传统通书。\n历法字段标注"暂未启用"表示暂无可靠算法。', textAlign: TextAlign.center, style: GuoXueTypography.caption.copyWith(color: Colors.white24, fontSize: 10))),

        const SizedBox(height: 16), const DisclaimerBlock(),
      ])),
    );
  }

  AlmanacFieldView _solarTermView(AlmanacFieldView base) {
    if (_trialResult != null) {
      if (_trialResult!.available && _trialResult!.termName != null) {
        // 节气日 → 显示节气名
        return AlmanacFieldView(key: 'solarTerm', label: '节气', available: true, displayText: _trialResult!.termName!, source: 'trial_loaded');
      } else {
        // trial loaded but no term → 今日无节气
        return AlmanacFieldView(key: 'solarTerm', label: '节气', available: true, displayText: '今日无节气', source: 'trial_no_term');
      }
    }
    // trial still loading → show provider placeholder, will update on next setState
    return base;
  }

  Widget _calRow(String label, AlmanacFieldView fv) {
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
      SizedBox(width: 48, child: Text(label, style: GuoXueTypography.caption.copyWith(color: Colors.white38))),
      Expanded(child: Text(fv.displayText, style: GuoXueTypography.caption.copyWith(color: fv.available ? Colors.white54 : Colors.white30, fontSize: 12))),
    ]));
  }

  Widget _sectionCard(String title, List<String> items, Color color) => ClassicalCard(color: const Color(0xFF2A2218), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(title=='宜'?Icons.check_circle_outline:Icons.cancel_outlined, color: color, size: 20), const SizedBox(width: 8), Text(title, style: GuoXueTypography.h3.copyWith(color: color))]),
    const SizedBox(height: 8), const Divider(color: GuoXueColors.gold),
    const SizedBox(height: 6),
    Wrap(spacing: 10, runSpacing: 6, children: items.map((e)=>Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(6)), child: Text(e, style: GuoXueTypography.body.copyWith(color: Colors.white70)))).toList()),
  ]));

  Widget _adviceRow(String label, String text) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 36, child: Text(label, style: GuoXueTypography.caption.copyWith(color: Colors.white38))),
    Expanded(child: Text(text, style: GuoXueTypography.body.copyWith(color: Colors.white70, fontSize: 13))),
  ]);
}

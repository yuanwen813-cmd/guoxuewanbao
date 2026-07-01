import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// 节气候选数据沙箱加载器 v0.26
///
/// 仅用于沙箱验证，不接入正式 CalendarProvider。
/// 所有数据标记 productionReady=false, publicExposure=false。

class SolarTermCandidateSandboxInspectResult {
  final String schemaVersion;
  final bool candidateDataExists;
  final bool candidateDataReady;
  final bool productionReady;
  final bool publicExposure;
  final bool calendarProviderIntegration;
  final bool safeForSandbox;
  final bool safeForPublicUse;
  final int yearsLoaded;
  final int termsLoaded;
  final List<String> blockingReasons;
  final List<String> warnings;
  final List<String> nextActions;
  final Map<String, dynamic>? rawData;

  const SolarTermCandidateSandboxInspectResult({
    this.schemaVersion = 'solar-term-candidate-sandbox-v0_26',
    this.candidateDataExists = false, this.candidateDataReady = false,
    this.productionReady = false, this.publicExposure = false, this.calendarProviderIntegration = false,
    this.safeForSandbox = false, this.safeForPublicUse = false,
    this.yearsLoaded = 0, this.termsLoaded = 0,
    this.blockingReasons = const [], this.warnings = const [], this.nextActions = const [],
    this.rawData,
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'candidateDataExists': candidateDataExists, 'candidateDataReady': candidateDataReady,
    'productionReady': productionReady, 'publicExposure': publicExposure, 'calendarProviderIntegration': calendarProviderIntegration,
    'safeForSandbox': safeForSandbox, 'safeForPublicUse': safeForPublicUse,
    'yearsLoaded': yearsLoaded, 'termsLoaded': termsLoaded,
    'blockingReasons': blockingReasons, 'warnings': warnings, 'nextActions': nextActions,
  };
}

class SolarTermCandidateSandboxLoader {
  static const _candidatePath = 'assets/data/calendar/solar_term_candidate.v0_26.json';
  static const _validTerms = ['立春','雨水','惊蛰','春分','清明','谷雨','立夏','小满','芒种','夏至','小暑','大暑','立秋','处暑','白露','秋分','寒露','霜降','立冬','小雪','大雪','冬至','小寒','大寒'];

  const SolarTermCandidateSandboxLoader();

  Future<Map<String, dynamic>?> loadCandidateData() async {
    try {
      final raw = await rootBundle.loadString(_candidatePath);
      if (raw.trim().isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) { return null; }
  }

  List<String> validateSafetyFlags(Map<String, dynamic> data) {
    final reasons = <String>[];
    if (data['productionReady'] != false) reasons.add('productionReady 必须为 false');
    if (data['publicExposure'] != false) reasons.add('publicExposure 必须为 false');
    if (data['calendarProviderIntegration'] != false) reasons.add('calendarProviderIntegration 必须为 false');
    if (data['usesAiGeneratedData'] != false) reasons.add('usesAiGeneratedData 必须为 false');
    if (data['requiresNetwork'] != false) reasons.add('requiresNetwork 必须为 false');
    if (data['usesFixedDateApproximation'] != false) reasons.add('usesFixedDateApproximation 必须为 false');
    return reasons;
  }

  List<String> validateSchemaShape(Map<String, dynamic> data) {
    final reasons = <String>[];
    final cdReady = data['candidateDataReady'] == true;

    if (cdReady) {
      final sy = data['coverageStartYear']; final ey = data['coverageEndYear'];
      if (sy == null || ey == null) reasons.add('candidateDataReady=true 但缺少 coverageStartYear/coverageEndYear');
      else {
        if (sy is int && sy > 1900) reasons.add('coverageStartYear 必须 <= 1900');
        if (ey is int && ey < 2100) reasons.add('coverageEndYear 必须 >= 2100');
      }

      final years = data['years'] as List?;
      if (years == null || years.isEmpty) reasons.add('candidateDataReady=true 但 years 为空');

      for (final y in (years ?? [])) {
        final yMap = y as Map<String, dynamic>;
        final terms = yMap['terms'] as List? ?? [];
        if (terms.length != 24) { reasons.add('年份 ${yMap['year']}: 节气数=${terms.length}，必须为24'); continue; }

        // Check sequenceIndex 1-24
        final indices = <int>{};
        for (final t in terms) {
          final tm = t as Map<String, dynamic>;
          final si = tm['sequenceIndex']; final name = tm['name'];
          if (si is! int || si < 1 || si > 24) reasons.add('sequenceIndex 必须在1-24: ${tm['year']} ${tm['name']} -> $si');
          if (name is String && !_validTerms.contains(name)) reasons.add('节气名不在24节气列表: $name');
          if (name is String) indices.add(si is int ? si : -1);
          final date = tm['date']; if (date is! String || date.isEmpty) reasons.add('date 缺失或非字符串');
          final tz = tm['timezone']; if (tz is! String || tz.isEmpty) reasons.add('timezone 缺失: ${tm['name']}');
        }
        if (indices.length != 24) reasons.add('年份 ${yMap['year']}: sequenceIndex 有重复或缺失');
      }
    } else {
      // candidateDataReady=false → years must be empty or placeholder
      final years = data['years'] as List?;
      if (years != null && years.isNotEmpty) reasons.add('candidateDataReady=false 但 years 非空');
    }
    return reasons;
  }

  List<String> validateManifestConsistency(Map<String, dynamic> data, Map<String, dynamic> manifest) {
    final reasons = <String>[];
    if (manifest['productionReady'] != data['productionReady']) reasons.add('manifest 与 data productionReady 不一致');
    if (manifest['publicExposure'] != data['publicExposure']) reasons.add('manifest 与 data publicExposure 不一致');
    if (manifest['calendarProviderIntegration'] != data['calendarProviderIntegration']) reasons.add('manifest 与 data calendarProviderIntegration 不一致');
    return reasons;
  }

  Future<SolarTermCandidateSandboxInspectResult> inspect() async {
    final data = await loadCandidateData();
    if (data == null) {
      return const SolarTermCandidateSandboxInspectResult(
        blockingReasons: ['candidate data file 不存在或无法解析'],
        warnings: ['请确认 assets/data/calendar/solar_term_candidate.v0_26.json 存在'],
        nextActions: ['创建候选数据文件或继续使用占位'],
      );
    }

    final cdReady = data['candidateDataReady'] == true;
    final blocking = <String>[];

    // Safety flags
    blocking.addAll(validateSafetyFlags(data));

    // Schema shape
    blocking.addAll(validateSchemaShape(data));

    // Load manifest for consistency check
    Map<String, dynamic>? manifest;
    try {
      final mr = await rootBundle.loadString('assets/data/calendar/solar_term_candidate_manifest.v0_25.json');
      manifest = jsonDecode(mr) as Map<String, dynamic>;
    } catch (_) { manifest = null; }

    if (manifest != null) {
      blocking.addAll(validateManifestConsistency(data, manifest));
    }

    final safe = blocking.isEmpty;
    int yearsLoaded = 0, termsLoaded = 0;
    if (cdReady) {
      final years = data['years'] as List? ?? [];
      yearsLoaded = years.length;
      for (final y in years) { termsLoaded += ((y as Map<String, dynamic>)['terms'] as List?)?.length ?? 0; }
    }

    final warnings = <String>[];
    if (!cdReady) warnings.add('candidateDataReady=false — 当前为安全占位，无真实节气数据');
    if (manifest == null) warnings.add('manifest 文件无法加载');

    final na = <String>[];
    if (safe && cdReady) na.add('安全标记通过，可进入下一步: normalization/sandbox/preflight/validator');
    else if (safe && !cdReady) na.add('安全占位状态正常，等待真实候选数据接入');
    else na.add('修复 blockingReasons 后重新 inspect');

    return SolarTermCandidateSandboxInspectResult(
      candidateDataExists: true, candidateDataReady: cdReady,
      productionReady: data['productionReady'] == true,
      publicExposure: data['publicExposure'] == true,
      calendarProviderIntegration: data['calendarProviderIntegration'] == true,
      safeForSandbox: safe, safeForPublicUse: false,
      yearsLoaded: yearsLoaded, termsLoaded: termsLoaded,
      blockingReasons: blocking, warnings: warnings, nextActions: na,
      rawData: data,
    );
  }

  Map<String, dynamic> buildDebugJson() {
    return {
      'schemaVersion': 'solar-term-candidate-sandbox-debug-v0_26',
      'candidateSandboxEnabled': true,
      'candidateDataExists': true,
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
}

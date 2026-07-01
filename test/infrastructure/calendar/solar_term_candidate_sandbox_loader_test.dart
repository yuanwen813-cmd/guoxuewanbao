import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_candidate_sandbox_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sandbox loader: asset files exist', () {
    test('candidate data file exists', () async {
      try { await rootBundle.loadString('assets/data/calendar/solar_term_candidate.v0_26.json'); }
      catch (_) { fail('candidate data file not found'); }
    });
    test('manifest file exists', () async {
      try { await rootBundle.loadString('assets/data/calendar/solar_term_candidate_manifest.v0_25.json'); }
      catch (_) { fail('manifest file not found'); }
    });
  });

  group('sandbox loader: placeholder inspect', () {
    test('inspect works on placeholder', () async {
      final loader = SolarTermCandidateSandboxLoader();
      final r = await loader.inspect();
      expect(r.candidateDataExists, true);
    });
    test('placeholder candidateDataReady=false', () async {
      final r = await const SolarTermCandidateSandboxLoader().inspect();
      expect(r.candidateDataReady, false);
    });
    test('placeholder productionReady=false', () async {
      final r = await const SolarTermCandidateSandboxLoader().inspect();
      expect(r.productionReady, false);
    });
    test('placeholder publicExposure=false', () async {
      final r = await const SolarTermCandidateSandboxLoader().inspect();
      expect(r.publicExposure, false);
    });
    test('placeholder calendarProviderIntegration=false', () async {
      final r = await const SolarTermCandidateSandboxLoader().inspect();
      expect(r.calendarProviderIntegration, false);
    });
    test('placeholder safeForSandbox=true', () async {
      final r = await const SolarTermCandidateSandboxLoader().inspect();
      expect(r.safeForSandbox, true);
    });
    test('placeholder safeForPublicUse=false', () async {
      final r = await const SolarTermCandidateSandboxLoader().inspect();
      expect(r.safeForPublicUse, false);
    });
    test('placeholder yearsLoaded=0', () async {
      final r = await const SolarTermCandidateSandboxLoader().inspect();
      expect(r.yearsLoaded, 0);
    });
  });

  group('sandbox loader: safety flag validation', () {
    test('productionReady=true detected', () {
      final reasons = const SolarTermCandidateSandboxLoader().validateSafetyFlags({'productionReady': true});
      expect(reasons.any((r) => r.contains('productionReady')), true);
    });
    test('publicExposure=true detected', () {
      final reasons = const SolarTermCandidateSandboxLoader().validateSafetyFlags({'publicExposure': true});
      expect(reasons.any((r) => r.contains('publicExposure')), true);
    });
    test('calendarProviderIntegration=true detected', () {
      final reasons = const SolarTermCandidateSandboxLoader().validateSafetyFlags({'calendarProviderIntegration': true});
      expect(reasons.any((r) => r.contains('calendarProviderIntegration')), true);
    });
    test('usesAiGeneratedData=true detected', () {
      final reasons = const SolarTermCandidateSandboxLoader().validateSafetyFlags({'usesAiGeneratedData': true});
      expect(reasons.any((r) => r.contains('usesAiGeneratedData')), true);
    });
    test('requiresNetwork=true detected', () {
      final reasons = const SolarTermCandidateSandboxLoader().validateSafetyFlags({'requiresNetwork': true});
      expect(reasons.any((r) => r.contains('requiresNetwork')), true);
    });
    test('usesFixedDateApproximation=true detected', () {
      final reasons = const SolarTermCandidateSandboxLoader().validateSafetyFlags({'usesFixedDateApproximation': true});
      expect(reasons.any((r) => r.contains('usesFixedDateApproximation')), true);
    });
    test('all false → no reasons', () {
      final reasons = const SolarTermCandidateSandboxLoader().validateSafetyFlags({
        'productionReady': false, 'publicExposure': false, 'calendarProviderIntegration': false,
        'usesAiGeneratedData': false, 'requiresNetwork': false, 'usesFixedDateApproximation': false,
      });
      expect(reasons, isEmpty);
    });
  });

  group('sandbox loader: schema shape validation', () {
    final loader = const SolarTermCandidateSandboxLoader();
    test('candidateDataReady=true no coverage → error', () {
      final reasons = loader.validateSchemaShape({'candidateDataReady': true, 'years': []});
      expect(reasons.any((r) => r.contains('coverage')), true);
    });
    test('candidateDataReady=true years empty → error', () {
      final reasons = loader.validateSchemaShape({'candidateDataReady': true, 'coverageStartYear': 1900, 'coverageEndYear': 2100, 'years': []});
      expect(reasons.any((r) => r.contains('years')), true);
    });
    test('candidateDataReady=true < 24 terms → error', () {
      final reasons = loader.validateSchemaShape({
        'candidateDataReady': true, 'coverageStartYear': 1900, 'coverageEndYear': 2100,
        'years': [{'year': 2026, 'terms': [{'name': '立春', 'date': '2026-02-04', 'time': '16:00', 'timezone': 'Asia/Shanghai', 'sequenceIndex': 1}]}]
      });
      expect(reasons.any((r) => r.contains('必须为24')), true);
    });
    test('candidateDataReady=true bad sequenceIndex → error', () {
      final terms = List.generate(24, (i) => {'name': '节气${i+1}', 'date': '2026-01-01', 'time': '00:00', 'timezone': 'Asia/Shanghai', 'sequenceIndex': i+1});
      final reasons = loader.validateSchemaShape({
        'candidateDataReady': true, 'coverageStartYear': 1900, 'coverageEndYear': 2100,
        'years': [{'year': 2026, 'terms': terms}]
      });
      expect(reasons.any((r) => r.contains('节气名不在')), true);
    });
    test('candidateDataReady=false years non-empty → error', () {
      final reasons = loader.validateSchemaShape({'candidateDataReady': false, 'years': [{'year': 2026}]});
      expect(reasons.any((r) => r.contains('years')), true);
    });
    test('candidateDataReady=false years empty → ok', () {
      final reasons = loader.validateSchemaShape({'candidateDataReady': false, 'years': []});
      expect(reasons, isEmpty);
    });
  });

  group('debug json', () {
    test('buildDebugJson schemaVersion', () {
      final dbg = const SolarTermCandidateSandboxLoader().buildDebugJson();
      expect(dbg['schemaVersion'], 'solar-term-candidate-sandbox-debug-v0_26');
    });
    test('safeForSandbox=true', () {
      final dbg = const SolarTermCandidateSandboxLoader().buildDebugJson();
      expect(dbg['safeForSandbox'], true);
    });
    test('safeForPublicUse=false', () {
      final dbg = const SolarTermCandidateSandboxLoader().buildDebugJson();
      expect(dbg['safeForPublicUse'], false);
    });
    test('calendarProviderIntegration=false', () {
      final dbg = const SolarTermCandidateSandboxLoader().buildDebugJson();
      expect(dbg['calendarProviderIntegration'], false);
    });
  });
}

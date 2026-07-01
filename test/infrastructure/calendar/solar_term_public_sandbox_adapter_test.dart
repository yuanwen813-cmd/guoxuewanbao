import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_public_sandbox_adapter.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_trial_engine.dart';

void main() {
  final adapter = const SolarTermPublicSandboxAdapter();

  SolarTermTrialResult _trial({bool available = true, String status = 'trial_only', String? name, String? date, String? tz, String source = 'solar_term_candidate_trial_v0_32'}) {
    return SolarTermTrialResult(available: available, status: status, termName: name, date: date, timezone: tz, source: source);
  }

  group('sandbox generation', () {
    test('can generate sandbox result', () {
      final r = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04', tz: 'Asia/Shanghai'), designStatus: 'design_ready', date: '2026-06-22', sampleName: 'test');
      expect(r.schemaVersion, 'solar-term-public-sandbox-adapter-v0_38');
      expect(r.sampleName, 'test');
      expect(r.date, '2026-06-22');
    });
  });

  group('sandboxStatus rules', () {
    test('design blocked → blocked', () {
      final r = adapter.adapt(trial: _trial(), designStatus: 'blocked', date: '');
      expect(r.sandboxStatus, 'blocked');
    });
    test('design_not_allowed → blocked', () {
      final r = adapter.adapt(trial: _trial(), designStatus: 'design_not_allowed', date: '');
      expect(r.sandboxStatus, 'blocked');
    });
    test('trial_only complete → mapped_for_sandbox', () {
      final r = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04', tz: 'Asia/Shanghai'), designStatus: 'design_ready', date: '');
      expect(r.sandboxStatus, 'mapped_for_sandbox');
    });
    test('trial unavailable → unavailable', () {
      final r = adapter.adapt(trial: _trial(available: false, status: 'unavailable'), designStatus: 'design_ready', date: '');
      expect(r.sandboxStatus, 'unavailable');
    });
    test('trial blocked → blocked', () {
      final r = adapter.adapt(trial: _trial(available: false, status: 'blocked'), designStatus: 'design_ready', date: '');
      expect(r.sandboxStatus, 'blocked');
    });
    test('missing name → mapping_failed', () {
      final r = adapter.adapt(trial: _trial(date: '2026-02-04', tz: 'Asia/Shanghai'), designStatus: 'design_ready', date: '');
      expect(r.sandboxStatus, 'mapping_failed');
    });
    test('missing date → mapping_failed', () {
      final r = adapter.adapt(trial: _trial(name: '立春', tz: 'Asia/Shanghai'), designStatus: 'design_ready', date: '');
      expect(r.sandboxStatus, 'mapping_failed');
    });
    test('missing timezone → mapping_failed', () {
      final r = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04'), designStatus: 'design_ready', date: '');
      expect(r.sandboxStatus, 'mapping_failed');
    });
  });

  group('source forbidden terms', () {
    test('source public → blocked', () {
      final r = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04', tz: 'Asia/Shanghai', source: 'public_data'), designStatus: 'design_ready', date: '');
      expect(r.sandboxStatus, 'blocked');
    });
    test('source production → blocked', () {
      final r = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04', tz: 'Asia/Shanghai', source: 'production_v1'), designStatus: 'design_ready', date: '');
      expect(r.sandboxStatus, 'blocked');
    });
    test('source official_enabled → blocked', () {
      final r = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04', tz: 'Asia/Shanghai', source: 'official_enabled_source'), designStatus: 'design_ready', date: '');
      expect(r.sandboxStatus, 'blocked');
    });
  });

  group('contract fields', () {
    final r = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04', tz: 'Asia/Shanghai'), designStatus: 'design_ready', date: '');
    test('solarTermName', () => expect(r.contract.solarTermName, '立春'));
    test('solarTermDate', () => expect(r.contract.solarTermDate, '2026-02-04'));
    test('solarTermTime', () { expect(r.contract.toJson().containsKey('solarTermTime'), true); });
    test('source', () { expect(r.contract.toJson().containsKey('source'), true); });
    test('sourceVersion', () { expect(r.contract.toJson().containsKey('sourceVersion'), true); });
    test('confidence', () { expect(r.contract.toJson().containsKey('confidence'), true); });
    test('status', () { expect(r.contract.toJson().containsKey('status'), true); });
    test('timezone', () => expect(r.contract.timezone, 'Asia/Shanghai'));
    test('generatedAt', () { expect(r.contract.toJson().containsKey('generatedAt'), true); });
    test('unavailableReason', () { expect(r.contract.toJson().containsKey('unavailableReason'), true); });
  });

  group('contract from unavailable trial', () {
    final r = adapter.adapt(trial: _trial(available: false, status: 'unavailable'), designStatus: 'design_ready', date: '');
    test('status is unavailable', () => expect(r.contract.status, 'unavailable'));
    test('has unavailableReason', () => expect(r.contract.unavailableReason, isNotNull));
  });

  group('mapping issues', () {
    test('records field', () {
      final r = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04', tz: 'Asia/Shanghai', source: 'public_data'), designStatus: 'design_ready', date: '2026-06-22');
      expect(r.mappingIssues.length, 1);
      expect(r.mappingIssues.first.field, 'source');
    });
    test('records reason', () {
      final r = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04', tz: 'Asia/Shanghai', source: 'public_data'), designStatus: 'design_ready', date: '2026-06-22');
      expect(r.mappingIssues.first.reason, contains('禁止标识'));
    });
    test('records severity', () {
      final r = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04', tz: 'Asia/Shanghai', source: 'public_data'), designStatus: 'design_ready', date: '2026-06-22');
      expect(r.mappingIssues.first.severity, 'high');
    });
    test('records date', () {
      final r = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04', tz: 'Asia/Shanghai', source: 'public_data'), designStatus: 'design_ready', date: '2026-06-22');
      expect(r.mappingIssues.first.date, '2026-06-22');
    });
    test('records suggestion', () {
      final r = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04', tz: 'Asia/Shanghai', source: 'public_data'), designStatus: 'design_ready', date: '2026-06-22');
      expect(r.mappingIssues.first.suggestion, isNotEmpty);
    });
  });

  group('guard flags', () {
    final r = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04', tz: 'Asia/Shanghai'), designStatus: 'design_ready', date: '');
    test('productionReady false', () => expect(r.guard.productionReady, false));
    test('publicExposure false', () => expect(r.guard.publicExposure, false));
    test('calendarProviderIntegration false', () => expect(r.guard.calendarProviderIntegration, false));
    test('displayAllowed false', () => expect(r.guard.displayAllowed, false));
    test('shareAllowed false', () => expect(r.guard.shareAllowed, false));
    test('snapshotAllowed false', () => expect(r.guard.snapshotAllowed, false));
    test('ganzhiDependencyAllowed false', () => expect(r.guard.ganzhiDependencyAllowed, false));
    test('clashDependencyAllowed false', () => expect(r.guard.clashDependencyAllowed, false));
  });

  group('mapped_for_sandbox guards', () {
    final r = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04', tz: 'Asia/Shanghai'), designStatus: 'design_ready', date: '');
    test('mapped → productionReady false', () { expect(r.sandboxStatus, 'mapped_for_sandbox'); expect(r.guard.productionReady, false); });
    test('mapped → publicExposure false', () => expect(r.guard.publicExposure, false));
    test('mapped → calProvider false', () => expect(r.guard.calendarProviderIntegration, false));
    test('mapped → display false', () => expect(r.guard.displayAllowed, false));
    test('mapped → share false', () => expect(r.guard.shareAllowed, false));
    test('mapped → snapshot false', () => expect(r.guard.snapshotAllowed, false));
  });

  group('result toJson', () {
    final j = adapter.adapt(trial: _trial(name: '立春', date: '2026-02-04', tz: 'Asia/Shanghai'), designStatus: 'design_ready', date: '').toJson();
    test('contains contract', () => expect(j.containsKey('contract'), true));
    test('contains mappingIssues', () => expect(j.containsKey('mappingIssues'), true));
    test('contains guardFlags', () => expect(j.containsKey('guardFlags'), true));
  });

  group('debug', () {
    test('schemaVersion', () => expect(adapter.buildDebugJson()['schemaVersion'], 'solar-term-public-sandbox-adapter-debug-v0_38'));
    test('conclusionNote', () => expect(adapter.buildDebugJson()['conclusionNote'], contains('sandbox mapping')));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_trial_models.dart';

void main() {
  group('TrialModeConfig', () {
    test('defaults',() {
      final c=SolarTermTrialModeConfig.defaultConfig;
      expect(c.enabled,true);
      expect(c.readOnly,true);
      expect(c.debugOnly,true);
      expect(c.publicExposure,false);
      expect(c.calendarProviderIntegration,false);
      expect(c.pageDisplay,false);
      expect(c.shareDisplay,false);
      expect(c.snapshotWrite,false);
      expect(c.ganzhiDependency,false);
      expect(c.clashDependency,false);
    });
    test('schemaVersion',() {
      expect(SolarTermTrialModeConfig.defaultConfig.schemaVersion,'solar-term-trial-mode-v0_31');
    });
    test('toJson keys',() {
      final j=SolarTermTrialModeConfig.defaultConfig.toJson();
      expect(j.containsKey('pageDisplay'),true);
      expect(j.containsKey('shareDisplay'),true);
      expect(j['snapshotWrite'],false);
      expect(j['calendarProviderIntegration'],false);
    });
    test('custom config',() {
      final c=const SolarTermTrialModeConfig(enabled:false);
      expect(c.enabled,false);
      expect(c.readOnly,true); // other defaults preserved
    });
  });
}

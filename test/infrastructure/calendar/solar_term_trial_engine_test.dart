import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_trial_engine.dart';
import 'package:guoxueapp/infrastructure/calendar/solar_term_trial_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final defaultEngine = const SolarTermTrialEngine();

  group('blocking: config checks', () {
    test('enabled=false→unavailable',() async {
      final e=SolarTermTrialEngine(config:SolarTermTrialModeConfig(enabled:false));
      final r=await e.getTrialSolarTermForDate(DateTime(2026,6,22));
      expect(r.available,false); expect(r.status,'unavailable');
    });
    test('readOnly=false→blocked',() async {
      final e=SolarTermTrialEngine(config:SolarTermTrialModeConfig(readOnly:false));
      final r=await e.getTrialSolarTermForDate(DateTime(2026,6,22));
      expect(r.status,'blocked');
    });
    test('debugOnly=false→blocked',() async {
      final e=SolarTermTrialEngine(config:SolarTermTrialModeConfig(debugOnly:false));
      expect((await e.getTrialSolarTermForDate(DateTime(2026,6,22))).status,'blocked');
    });
    test('publicExposure=true→blocked',() async {
      final e=SolarTermTrialEngine(config:SolarTermTrialModeConfig(publicExposure:true));
      expect((await e.getTrialSolarTermForDate(DateTime(2026,6,22))).status,'blocked');
    });
    test('calendarProviderIntegration=true→blocked',() async {
      final e=SolarTermTrialEngine(config:SolarTermTrialModeConfig(calendarProviderIntegration:true));
      expect((await e.getTrialSolarTermForDate(DateTime(2026,6,22))).status,'blocked');
    });
    test('pageDisplay=true→blocked',() async {
      final e=SolarTermTrialEngine(config:SolarTermTrialModeConfig(pageDisplay:true));
      expect((await e.getTrialSolarTermForDate(DateTime(2026,6,22))).status,'blocked');
    });
    test('shareDisplay=true→blocked',() async {
      final e=SolarTermTrialEngine(config:SolarTermTrialModeConfig(shareDisplay:true));
      expect((await e.getTrialSolarTermForDate(DateTime(2026,6,22))).status,'blocked');
    });
    test('snapshotWrite=true→blocked',() async {
      final e=SolarTermTrialEngine(config:SolarTermTrialModeConfig(snapshotWrite:true));
      expect((await e.getTrialSolarTermForDate(DateTime(2026,6,22))).status,'blocked');
    });
  });

  group('trial result structure', () {
    test('unavailable result fields',() {
      final r=SolarTermTrialResult.unavailable;
      expect(r.available,false); expect(r.productionReady,false); expect(r.publicExposure,false);
      expect(r.displayAllowed,false); expect(r.shareAllowed,false); expect(r.snapshotAllowed,false);
      expect(r.ganzhiDependencyAllowed,false); expect(r.clashDependencyAllowed,false);
    });
    test('blocked result fields',() {
      final r=SolarTermTrialResult.blocked;
      expect(r.available,false); expect(r.status,'blocked');
      expect(r.displayAllowed,false); expect(r.shareAllowed,false);
    });
    test('trial_only result has all guard fields false',() {
      final r=SolarTermTrialResult(available:true,status:'trial_only',termName:'立春');
      expect(r.available,true); expect(r.status,'trial_only');
      expect(r.productionReady,false); expect(r.displayAllowed,false); expect(r.ganzhiDependencyAllowed,false);
    });
    test('toJson includes guards',() {
      final j=SolarTermTrialResult(available:true,status:'trial_only',termName:'立春').toJson();
      expect(j['displayAllowed'],false); expect(j['snapshotAllowed'],false);
      expect(j['ganzhiDependencyAllowed'],false); expect(j['clashDependencyAllowed'],false);
    });
    test('toJson includes reason when present',() {
      final j=SolarTermTrialResult.unavailable.toJson();
      expect(j.containsKey('reason'),true);
    });
  });

  group('placeholder data (trial engine)', () {
    test('default config with placeholder data→unavailable (candidateDataReady=false)',() async {
      final r=await defaultEngine.getTrialSolarTermForDate(DateTime(2026,6,22));
      expect(r.available,false);
    });
    test('getTrialSolarTermsForYear returns unavailable for placeholder',() async {
      final r=await defaultEngine.getTrialSolarTermsForYear(2026);
      expect(r.length,1);
      expect(r.first.available,false);
    });
    test('buildDebugJson schemaVersion',() {
      expect(defaultEngine.buildDebugJson()['schemaVersion'],'solar-term-trial-engine-debug-v0_32');
    });
    test('buildDebugJson all guards false',() {
      final d=defaultEngine.buildDebugJson();
      expect(d['productionReady'],false); expect(d['publicExposure'],false);
      expect(d['displayAllowed'],false); expect(d['snapshotAllowed'],false);
    });
  });
}

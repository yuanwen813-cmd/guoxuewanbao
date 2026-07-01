import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/domain/calendar/lunar_calendar_engine.dart';

/// 农历引擎合约测试
/// 原则：没有可靠引擎时，不准伪造通过
void main() {
  group('LunarCalendarEngine contract', () {
    test('no engine → capabilities are none', () {
      final cap = LunarEngineCapabilities.none;
      expect(cap.engineId, 'none');
      expect(cap.supportsLeapMonth, false);
      expect(cap.supportsLunarNewYear, false);
    });

    test('default engine → supportsLunarNewYear is false', () {
      const cap = LunarEngineCapabilities();
      expect(cap.supportsLunarNewYear, false);
      expect(cap.supportsLeapMonth, false);
    });
  });

  group('Spring Festival benchmark (contract only — no engine yet)', () {
    // 这三个日期必须在引擎实现后全部通过，否则不准声明 full
    const benchmarks = ['2024-02-10', '2025-01-29', '2026-02-17'];

    test('benchmark dates are defined in contract', () {
      expect(benchmarks.length, 3);
    });

    test('without engine, none of the benchmarks pass', () {
      // 没有引擎 → 所有基准测试不应声称通过
      const cap = LunarEngineCapabilities.none;
      expect(cap.supportsLunarNewYear, false,
          reason: 'No engine installed; must not claim lunar capability');
    });
  });
}

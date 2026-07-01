import 'unified_models.dart';

/// 统一国学引擎接口
///
/// 所有功能引擎实现此接口即可接入 GuoxueFeatureRunner。
/// 引擎只负责"怎么算"，不关心 UI、AI、存储。
abstract class GuoxueEngine<I, O> {
  /// 引擎名称
  String get name;

  /// 从用户输入计算国学结果
  GuoxueResult calculate(I input);

  /// 验证输入是否合法
  String? validate(I input) => null;
}

/// 无输入引擎（如黄历、节气查询）
abstract class NoInputEngine extends GuoxueEngine<void, void> {
  @override
  GuoxueResult calculate(void input);
}

/// 查表引擎 —— 输入一个 key，从预置数据表中匹配结果
abstract class LookupEngine extends GuoxueEngine<String, void> {
  /// 预置数据
  Map<String, GuoxueResult> get lookupTable;

  @override
  GuoxueResult calculate(String key) {
    return lookupTable[key] ?? _notFound(key);
  }

  GuoxueResult _notFound(String key);
}

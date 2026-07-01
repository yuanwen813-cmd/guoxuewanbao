/// 设置仓储抽象接口
abstract class SettingsRepository {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<bool> getBool(String key, {bool defaultValue = false});
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
}

import '../../application/ports/settings_repository.dart';
import '../database/app_database.dart';

/// 设置仓储实现
class SettingsRepositoryImpl implements SettingsRepository {
  final AppDatabase _db;

  SettingsRepositoryImpl(this._db);

  @override
  Future<String?> getString(String key) async {
    final rows = await _db.db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> setString(String key, String value) async {
    await _db.db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await getString(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await setString(key, value.toString());
  }

  @override
  Future<void> remove(String key) async {
    await _db.db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
  }
}

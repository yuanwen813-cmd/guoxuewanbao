import 'secure_storage_service.dart';

/// API Key 存储
class ApiKeyStore {
  static const _key = 'deepseek_api_key';

  static Future<void> save(String apiKey) async {
    await SecureStorageService.instance.write(_key, apiKey);
  }

  static Future<String?> get() async {
    return await SecureStorageService.instance.read(_key);
  }

  static Future<void> delete() async {
    await SecureStorageService.instance.delete(_key);
  }

  static Future<bool> exists() async {
    final key = await get();
    return key != null && key.isNotEmpty;
  }
}

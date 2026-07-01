import 'package:flutter/foundation.dart';

import '../secure_storage/api_key_store.dart';
import 'deepseek_client.dart';

Future<DeepSeekClient> createDeepSeekClient() async {
  // Android: flutter_secure_storage 可能因 Keystore 挂起，加 2s 超时保护
  try {
    final apiKey = await ApiKeyStore.get().timeout(const Duration(seconds: 2));
    if (apiKey != null && apiKey.isNotEmpty) {
      debugPrint('[DeepSeek] 使用用户配置的 API Key');
      return DeepSeekClient(apiKey: apiKey);
    }
  } catch (e) {
    debugPrint('[DeepSeek] 用户 Key 查找失败: $e');
  }
  throw const DeepSeekException(
    '当前未配置 AI Key。公网版本请使用服务端 AI 解析接口，前端不再内置 DeepSeek Key。',
  );
}

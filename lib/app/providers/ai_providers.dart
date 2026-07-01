import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/dto/interpretation.dart';
import '../../application/ports/ai_port.dart';
import '../../infrastructure/ai/ai_gateway.dart';
import '../../infrastructure/secure_storage/api_key_store.dart';

/// API Key 状态 —— 优先从安全存储加载，Web 平台用内存
final apiKeyProvider = StateProvider<String?>((ref) => null);

/// 是否已配置 API Key
final hasApiKeyProvider = Provider<bool>((ref) {
  final key = ref.watch(apiKeyProvider);
  return key != null && key.isNotEmpty;
});

/// AI 网关 —— 优先使用用户配置的 API Key 直连 DeepSeek
final aiGatewayProvider = Provider<AiPort?>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  final hasKey = apiKey != null && apiKey.isNotEmpty;

  if (hasKey) {
    return AiGateway(apiKey: apiKey);
  }

  return null;
});

/// AI 解读状态 —— 按功能 ID 缓存
final interpretationProvider =
    StateProvider.family<AsyncValue<Interpretation>?, String>(
  (ref, id) => null,
);

/// 初始化 API Key（启动时调用，尝试从存储加载）
Future<void> initApiKey(WidgetRef ref) async {
  try {
    final stored = await ApiKeyStore.get();
    if (stored != null && stored.isNotEmpty) {
      ref.read(apiKeyProvider.notifier).state = stored;
    }
  } catch (e) {
    debugPrint('[ApiKey] 加载失败: $e');
  }
}

/// 保存 API Key
Future<void> saveApiKey(WidgetRef ref, String key) async {
  ref.read(apiKeyProvider.notifier).state = key;
  try {
    await ApiKeyStore.save(key);
  } catch (e) {
    debugPrint('[ApiKey] 持久化失败（Web 平台正常）: $e');
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/database/app_database.dart';
import '../infrastructure/secure_storage/secure_storage_service.dart';
import '../infrastructure/ai/prompt_registry.dart';

/// 初始化所有基础设施服务，返回预配置的 ProviderContainer。
/// 用于启动时的异步初始化（数据库、安全存储、日志等）。
Future<ProviderContainer> bootstrap() async {
  // 初始化安全存储（Web 平台不可用则跳过）
  try {
    await SecureStorageService.instance.init();
  } catch (e) {
    debugPrint('[Bootstrap] SecureStorage init failed (may be web): $e');
  }

  // 初始化数据库（Web 平台使用 sqflite_common_ffi）
  try {
    await AppDatabase.instance.init();
  } catch (e) {
    debugPrint('[Bootstrap] Database init failed (may be web): $e');
  }

  // 预热 PromptRegistry（缓存所有 YAML 提示词模板）
  try {
    await PromptRegistry.instance.init();
  } catch (e) {
    debugPrint('[Bootstrap] PromptRegistry init failed: $e');
  }

  // 创建顶层 ProviderContainer（可预先 override 一些 provider）
  final container = ProviderContainer();

  return container;
}

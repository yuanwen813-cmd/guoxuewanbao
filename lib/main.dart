import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'app/providers/ai_providers.dart';
import 'infrastructure/secure_storage/api_key_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = await bootstrap();

  // 初始化：尝试从安全存储加载 API Key
  try {
    final storedKey = await ApiKeyStore.get();
    if (storedKey != null && storedKey.isNotEmpty) {
      container.read(apiKeyProvider.notifier).state = storedKey;
    }
  } catch (_) {
    // Web 平台存储不可用，用户需在设置页手动输入 Key
  }

  runApp(
    ProviderScope(
      parent: container,
      child: const GuoXueApp(),
    ),
  );
}

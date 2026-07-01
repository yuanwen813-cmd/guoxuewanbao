import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/ai_providers.dart';
import '../../app/theme/guoxue_decoration.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../shared/widgets/guoxue_button.dart';

/// API Key 设置页面
class ApiKeyPage extends ConsumerStatefulWidget {
  const ApiKeyPage({super.key});

  @override
  ConsumerState<ApiKeyPage> createState() => _ApiKeyPageState();
}

class _ApiKeyPageState extends ConsumerState<ApiKeyPage> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    // 回填已保存的 Key
    final currentKey = ref.read(apiKeyProvider);
    if (currentKey != null) {
      _controller.text = currentKey;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;

    await saveApiKey(ref, key);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API Key 已保存')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Key 配置')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '配置你的 DeepSeek API Key',
              style: GuoXueTypography.h3,
            ),
            const SizedBox(height: 8),
            Text(
              'API Key 将安全存储在本设备中，仅用于 AI 解读功能。\n你可以在 DeepSeek 官网获取 API Key。',
              style: GuoXueTypography.bodySmall,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              decoration: GuoXueDecoration.guoxueInput(
                labelText: 'DeepSeek API Key',
                hintText: 'sk-...',
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GuoXueButton(
              label: '保存',
              icon: Icons.save,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

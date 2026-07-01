import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_decoration.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../shared/widgets/classical_card.dart';

/// AI 推荐页面
class RecommendPage extends ConsumerStatefulWidget {
  const RecommendPage({super.key});

  @override
  ConsumerState<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends ConsumerState<RecommendPage> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    // TODO: 调用 AI 推荐
    setState(() => _isLoading = true);
    // 模拟
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 智能推荐')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClassicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('你想了解什么？', style: GuoXueTypography.h2),
                  const SizedBox(height: 8),
                  Text(
                    '输入你的问题，AI 将推荐最适合的术数方法。\n例如：我想知道今年的财运怎么样',
                    style: GuoXueTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: GuoXueDecoration.guoxueInput(
                labelText: '你的问题',
                hintText: '输入你想了解的事情...',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: GuoXueColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('开始推荐', style: GuoXueTypography.bodyLarge.copyWith(
                      color: GuoXueColors.ricePaper)),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/registry/feature_registry.dart';
import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_decoration.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../domain/unified/guoxue_engine.dart';
import '../../domain/unified/guoxue_feature_runner.dart';
import '../../domain/unified/unified_models.dart';
import '../../features/result_new/guoxue_result_page.dart';
import '../../shared/widgets/classical_card.dart';
import '../../shared/widgets/guoxue_button.dart';
import '../../shared/widgets/yinyang_loader.dart';
import 'lot_drawing_engine.dart';

/// 统一抽签页面（观音/吕祖/关帝/诸葛神算共用）
class LotDrawingPage extends ConsumerStatefulWidget {
  final LotConfig lotConfig;
  final String featureId;

  const LotDrawingPage({
    super.key,
    required this.lotConfig,
    required this.featureId,
  });

  @override
  ConsumerState<LotDrawingPage> createState() => _LotDrawingPageState();
}

class _LotDrawingPageState extends ConsumerState<LotDrawingPage> {
  final _questionController = TextEditingController();
  late final LotDrawingEngine _engine;
  bool _drawing = false;
  GuoxueResult? _result;
  bool _interpreting = false;

  @override
  void initState() {
    super.initState();
    _engine = LotDrawingEngine(widget.lotConfig);
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _draw() async {
    setState(() => _drawing = true);
    await Future.delayed(const Duration(milliseconds: 1200)); // 仪式感延迟
    if (!mounted) return;
    final q = _questionController.text.trim();
    setState(() {
      _result = _engine.draw(userQuestion: q);
      _drawing = false;
    });
  }

  Future<void> _interpret() async {
    if (_result == null) return;
    setState(() => _interpreting = true);
    try {
      final runner = GuoxueFeatureRunner(
        feature: FeatureConfig(
          id: widget.featureId,
          title: widget.lotConfig.title,
          subtitle: '',
          categoryId: 'divination',
          route: '',
          icon: 'auto_awesome',
          status: 'beta',
          complexity: 'simple',
          ritualType: 'lot_drawing',
          engineType: 'local',
          promptTemplateId: 'lingqian_interpret',
          requiresBirthInfo: false,
          requiresQuestion: true,
          supportsHistory: true,
          supportsShare: true,
        ),
        engine: _LotResultEngine(_result!),
      );
      final withAI = await runner.run(null,
          userQuestion: _questionController.text.trim());
      if (mounted) setState(() { _result = withAI; _interpreting = false; });
    } catch (_) {
      if (mounted) setState(() => _interpreting = false);
    }
  }

  void _reset() {
    setState(() => _result = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return GuoxueResultPage(
        result: _result!,
        userQuestion: _questionController.text.trim().isNotEmpty
            ? _questionController.text.trim()
            : null,
        onRetry: _reset,
        onAIInterpret: _interpret,
        onSave: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已保存到历史记录')),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.lotConfig.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 签筒图示
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3E2723), Color(0xFF1B0000)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _drawing
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        YinYangLoader(size: 56),
                        SizedBox(height: 16),
                        Text('抽签中...',
                            style: TextStyle(color: GuoXueColors.gold)),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.water_drop, size: 56,
                            color: GuoXueColors.goldLight),
                        const SizedBox(height: 12),
                        Text(widget.lotConfig.subtitle,
                            style: GuoXueTypography.h3.copyWith(
                                color: GuoXueColors.ricePaper)),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(widget.lotConfig.ritual,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            // 事项输入
            ClassicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('所问事项（选填）', style: GuoXueTypography.body),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _questionController,
                    maxLength: 200,
                    maxLines: 2,
                    decoration: GuoXueDecoration.guoxueInput(
                      labelText: '',
                      hintText: '默念心中所问，然后输入...',
                    ).copyWith(counterText: ''),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GuoXueButton(
              label: _drawing ? '抽取中...' : '抽取灵签',
              icon: Icons.casino,
              onPressed: _drawing ? null : _draw,
            ),
          ],
        ),
      ),
    );
  }
}

/// 内部引擎：把已有 GuoxueResult 包装为引擎输出
class _LotResultEngine extends GuoxueEngine<void, void> {
  final GuoxueResult _result;
  _LotResultEngine(this._result);

  @override
  String get name => 'lot_result';

  @override
  GuoxueResult calculate(void input) => _result;
}

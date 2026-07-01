import 'package:flutter/material.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../app/registry/feature_registry.dart';
import '../../domain/unified/guoxue_engine.dart';
import '../../domain/unified/guoxue_feature_runner.dart';
import '../../domain/unified/unified_models.dart';
import '../../features/result_new/guoxue_result_page.dart';
import '../../shared/input_fields/dynamic_input_form.dart';
import '../../shared/widgets/classical_card.dart';
import '../../shared/widgets/guoxue_button.dart';
import '../../shared/widgets/yinyang_loader.dart';

/// 通用功能页面 —— 引擎 + 配置 = 完整功能
///
/// 适用于所有"配置驱动"的简单功能：
/// - 称骨算命、生肖运势、五行计算器等
/// - 输入表单自动根据 [InputFieldConfig] 渲染
/// - 结果统一用 [GuoxueResultPage] 展示
class GenericFeaturePage extends StatefulWidget {
  final String featureId;
  final String title;
  final String iconName;
  final List<InputFieldConfig> inputFields;
  final GuoxueResult Function(Map<String, dynamic> inputs) calculator;
  final String? promptTemplateId;
  final String? ritualText;

  const GenericFeaturePage({
    super.key,
    required this.featureId,
    required this.title,
    required this.iconName,
    required this.inputFields,
    required this.calculator,
    this.promptTemplateId,
    this.ritualText,
  });

  @override
  State<GenericFeaturePage> createState() => _GenericFeaturePageState();
}

class _GenericFeaturePageState extends State<GenericFeaturePage> {
  final _formKey = GlobalKey<DynamicInputFormState>();
  GuoxueResult? _result;
  bool _calculating = false;
  bool _interpreting = false;
  String? _userQuestion;

  void _calculate() {
    final inputs = DynamicInputForm.extractValues(_formKey.currentState!);
    setState(() {
      _calculating = true;
      _userQuestion = inputs['question'] as String?;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final r = widget.calculator(inputs);
      setState(() { _result = r; _calculating = false; });
    });
  }

  Future<void> _aiInterpret() async {
    if (_result == null || widget.promptTemplateId == null) return;
    setState(() => _interpreting = true);
    try {
      final runner = GuoxueFeatureRunner(
        feature: FeatureConfig(
          id: widget.featureId, title: widget.title, subtitle: '',
          categoryId: '', route: '', icon: widget.iconName,
          status: 'beta', complexity: 'simple', ritualType: 'none',
          engineType: 'local', promptTemplateId: widget.promptTemplateId,
          requiresBirthInfo: false, requiresQuestion: widget.inputFields.any((f) => f.key == 'question'),
          supportsHistory: true, supportsShare: true,
        ),
        engine: _ResultEngine(_result!),
      );
      final withAI = await runner.run(null, userQuestion: _userQuestion);
      if (mounted) setState(() { _result = withAI; _interpreting = false; });
    } catch (_) {
      if (mounted) setState(() => _interpreting = false);
    }
  }

  void _reset() => setState(() => _result = null);

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return GuoxueResultPage(
        result: _result!,
        userQuestion: _userQuestion,
        onAIInterpret: _interpreting ? null : _aiInterpret,
        onRetry: _reset,
        onSave: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存')),
        ),
      );
    }

    final fields = widget.inputFields.where((f) => f.key != 'question').toList();
    final hasQuestion = widget.inputFields.any((f) => f.key == 'question');

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 图标区
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: GuoXueColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(_icon(), size: 56, color: GuoXueColors.primary),
              ),
            ),
            const SizedBox(height: 20),

            if (widget.ritualText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClassicalCard(
                  child: Text(widget.ritualText!, style: GuoXueTypography.body, textAlign: TextAlign.center),
                ),
              ),

            if (hasQuestion)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClassicalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('想问什么？（选填）', style: GuoXueTypography.body),
                      const SizedBox(height: 8),
                      TextField(
                        maxLength: 200,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: '输入你想了解的事项...',
                          border: OutlineInputBorder(),
                        ).copyWith(counterText: ''),
                        onChanged: (v) => _userQuestion = v,
                      ),
                    ],
                  ),
                ),
              ),

            DynamicInputForm(
              key: _formKey,
              fields: fields,
            ),

            const SizedBox(height: 16),
            GuoXueButton(
              label: _calculating ? '计算中...' : '开始推算',
              icon: Icons.calculate_outlined,
              onPressed: _calculating ? null : _calculate,
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon() {
    return switch (widget.iconName) {
      'balance' => Icons.balance,
      'cruelty_free' => Icons.cruelty_free,
      'bedtime' => Icons.bedtime,
      'blur_on' => Icons.blur_on,
      'ac_unit' => Icons.ac_unit,
      'nightlight_round' => Icons.nightlight_round,
      'view_column' => Icons.view_column,
      _ => Icons.auto_awesome,
    };
  }
}

class _ResultEngine extends GuoxueEngine<void, void> {
  final GuoxueResult _r;
  _ResultEngine(this._r);
  @override String get name => 'result';
  @override GuoxueResult calculate(void input) => _r;
}

import 'package:flutter/material.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../shared/widgets/classical_card.dart';
import 'ask_question_templates.dart';

class AskQuestionTemplatePanel extends StatefulWidget {
  const AskQuestionTemplatePanel({
    super.key,
    required this.controller,
    this.scenarios,
    this.backgroundColor,
    this.foregroundColor,
    this.mutedColor,
    this.onTemplateApplied,
  });

  final TextEditingController controller;
  final List<AskScenario>? scenarios;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? mutedColor;
  final ValueChanged<AskQuestionTemplate>? onTemplateApplied;

  @override
  State<AskQuestionTemplatePanel> createState() =>
      _AskQuestionTemplatePanelState();
}

class _AskQuestionTemplatePanelState extends State<AskQuestionTemplatePanel> {
  late final List<AskScenario> _scenarios;
  String? _activeScenarioId;

  @override
  void initState() {
    super.initState();
    final source = widget.scenarios;
    _scenarios = AskQuestionTemplateLibrary.validate(source).isEmpty
        ? AskQuestionTemplateLibrary.enabledScenarios(source)
        : const [];
  }

  @override
  Widget build(BuildContext context) {
    if (_scenarios.isEmpty) return const SizedBox.shrink();
    final foreground = widget.foregroundColor ?? GuoXueColors.inkBlack;
    final muted = widget.mutedColor ?? GuoXueColors.inkGray;
    final active = _scenarios.where((item) => item.id == _activeScenarioId);
    final scenario = active.isEmpty ? null : active.first;

    return ClassicalCard(
      key: const Key('ask_question_template_panel'),
      color: widget.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '不知道怎么问？',
            style: GuoXueTypography.h3.copyWith(color: foreground),
          ),
          const SizedBox(height: 4),
          Text(
            '选择一个场景，看看大家通常会怎么问。',
            style: GuoXueTypography.bodySmall.copyWith(color: muted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _scenarios.map((item) {
              final selected = item.id == _activeScenarioId;
              return ChoiceChip(
                key: Key('ask_scenario_${item.id}'),
                label: Text(
                  item.name,
                  style: TextStyle(
                    color: selected ? GuoXueColors.inkBlack : foreground,
                  ),
                ),
                selected: selected,
                selectedColor: GuoXueColors.goldLight,
                backgroundColor: widget.backgroundColor,
                side: BorderSide(
                  color: selected
                      ? GuoXueColors.goldDark
                      : GuoXueColors.gold.withOpacity(0.45),
                ),
                onSelected: (_) => setState(() => _activeScenarioId = item.id),
              );
            }).toList(),
          ),
          if (scenario != null) ...[
            const SizedBox(height: 18),
            Text(
              '${scenario.name} · 可以参考这些问法',
              style: GuoXueTypography.body.copyWith(color: foreground),
            ),
            const SizedBox(height: 8),
            ...scenario.templates.map(
              (template) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TemplateButton(
                  template: template,
                  foreground: foreground,
                  muted: muted,
                  onTap: () => _applyTemplate(template),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _applyTemplate(AskQuestionTemplate template) async {
    if (widget.controller.text.trim().isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('使用问题模板'),
          content: const Text('输入框里已经有内容，是否使用这个问题模板替换原问题？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('替换原问题'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }

    widget.controller.value = TextEditingValue(
      text: template.text,
      selection: TextSelection.collapsed(offset: template.text.length),
    );
    widget.onTemplateApplied?.call(template);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已填入问题，你还可以继续修改。')),
    );
  }
}

class _TemplateButton extends StatelessWidget {
  const _TemplateButton({
    required this.template,
    required this.foreground,
    required this.muted,
    required this.onTap,
  });

  final AskQuestionTemplate template;
  final Color foreground;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('ask_template_${template.id}'),
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: GuoXueColors.gold.withOpacity(0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.format_quote_outlined, size: 18, color: muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  template.text,
                  style: GuoXueTypography.body.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

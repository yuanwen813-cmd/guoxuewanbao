import 'package:flutter/material.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_decoration.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../domain/unified/unified_models.dart';
import '../widgets/classical_card.dart';

/// 动态输入表单 —— 根据 InputFieldConfig 列表自动渲染表单
class DynamicInputForm extends StatefulWidget {
  final List<InputFieldConfig> fields;
  final String? submitLabel;
  final VoidCallback? onSubmit;
  final bool enabled;

  const DynamicInputForm({
    super.key,
    required this.fields,
    this.submitLabel,
    this.onSubmit,
    this.enabled = true,
  });

  /// 从 State 中提取当前输入值
  static Map<String, dynamic> extractValues(DynamicInputFormState state) {
    return Map.from(state._values);
  }

  @override
  State<DynamicInputForm> createState() => DynamicInputFormState();
}

class DynamicInputFormState extends State<DynamicInputForm> {
  final _values = <String, dynamic>{};
  final _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      _values[f.key] = f.defaultValue;
      if (f.type == InputFieldType.text || f.type == InputFieldType.multiline) {
        _controllers[f.key] = TextEditingController(text: f.defaultValue?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> get values => Map.from(_values);

  @override
  Widget build(BuildContext context) {
    return ClassicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.fields.map(_buildField),
          if (widget.submitLabel != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.enabled ? widget.onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: GuoXueColors.primary,
                foregroundColor: GuoXueColors.ricePaper,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(widget.submitLabel!, style: GuoXueTypography.bodyLarge),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(InputFieldConfig field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (field.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Text(field.label, style: GuoXueTypography.body),
                if (field.required) const Text(' *', style: TextStyle(color: GuoXueColors.error)),
              ]),
            ),
          switch (field.type) {
            InputFieldType.text || InputFieldType.multiline => TextField(
                controller: _controllers[field.key],
                maxLength: field.maxLength,
                maxLines: field.type == InputFieldType.multiline ? (field.maxLines ?? 3) : 1,
                decoration: GuoXueDecoration.guoxueInput(
                  labelText: '',
                  hintText: field.hint ?? '',
                ).copyWith(counterText: ''),
                onChanged: (v) => _values[field.key] = v,
              ),
            InputFieldType.number => Row(children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    final cur = (_values[field.key] as num?)?.toInt() ?? (field.defaultValue as int? ?? 0);
                    if (field.min == null || cur > (field.min as int)) {
                      setState(() => _values[field.key] = cur - 1);
                    }
                  },
                ),
                Text('${_values[field.key] ?? field.defaultValue ?? 0}',
                    style: GuoXueTypography.bodyLarge),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final cur = (_values[field.key] as num?)?.toInt() ?? (field.defaultValue as int? ?? 0);
                    if (field.max == null || cur < (field.max as int)) {
                      setState(() => _values[field.key] = cur + 1);
                    }
                  },
                ),
              ]),
            InputFieldType.dropdown => DropdownButton<dynamic>(
                value: _values[field.key] ?? field.defaultValue ?? field.options?.first,
                items: (field.options ?? []).map((o) => DropdownMenuItem(value: o, child: Text('$o'))).toList(),
                onChanged: (v) => setState(() => _values[field.key] = v),
                isExpanded: true,
              ),
            InputFieldType.date => OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_values[field.key]?.toString() ?? field.hint ?? '选择日期'),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) {
                    setState(() => _values[field.key] = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
                  }
                },
              ),
            InputFieldType.gender => SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('男')),
                  ButtonSegment(value: 1, label: Text('女')),
                ],
                selected: {_values[field.key] as int? ?? 0},
                onSelectionChanged: (v) => setState(() => _values[field.key] = v.first),
              ),
          },
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_decoration.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../domain/bazi/bazi_chart.dart';
import '../../domain/bazi/bazi_engine.dart';
import '../../domain/bazi/bazi_input.dart';
import '../../shared/widgets/classical_card.dart';
import '../../shared/widgets/dual_result_view.dart';
import '../../shared/widgets/guoxue_button.dart';

/// 八字页面
class BaziPage extends ConsumerStatefulWidget {
  const BaziPage({super.key});

  @override
  ConsumerState<BaziPage> createState() => _BaziPageState();
}

class _BaziPageState extends ConsumerState<BaziPage> {
  final _engine = const BaziEngine();

  int _year = 1990;
  int _month = 1;
  int _day = 1;
  int _hour = 0;
  int _gender = 0; // 0=男 1=女
  final _questionController = TextEditingController();

  bool _calculated = false;
  Map<String, String> _standardResults = {};
  Map<String, dynamic> _resultData = {};
  String _userQuestion = '';

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  static const _branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  void _calculate() {
    final input = BaziInput(
      year: _year,
      month: _month,
      day: _day,
      hour: _hour,
      gender: _gender == 0 ? Gender.male : Gender.female,
    );

    if (!input.isValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入合法日期')),
      );
      return;
    }

    try {
      final chart = _engine.calculate(input);
      final genderStr = _gender == 0 ? '男' : '女';
      final hourBranch = _branches[_hour ~/ 2 % 12];

      final results = <String, String>{};
      for (final p in chart.pillars) {
        results[p.name] = p.ganzhi.chineseName;
      }
      results['日主'] = chart.dayMaster;
      results['性别'] = genderStr;
      results['出生'] = '$_year年$_month月$_day日 $_hour时（${hourBranch}时）';

      final q = _questionController.text.trim();
      setState(() {
        _calculated = true;
        _userQuestion = q.isNotEmpty
            ? q
            : '八字命理分析：$_year年$_month月$_day日$_hour时，${genderStr}命';
        _standardResults = results;
        _resultData = chart.toJson()
          ..['gender'] = genderStr
          ..['birthYear'] = _year
          ..['birthMonth'] = _month
          ..['birthDay'] = _day
          ..['birthHour'] = _hour;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('排盘失败：$e')),
      );
    }
  }

  void _reset() {
    _questionController.clear();
    setState(() {
      _calculated = false;
      _standardResults = {};
      _resultData = {};
      _userQuestion = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('八字命理')),
      body: _calculated ? _buildResult() : _buildInput(),
    );
  }

  Widget _buildInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClassicalCard(
            child: Column(
              children: [
                _buildDropdown('出生年份', _year,
                    List.generate(151, (i) => 1950 + i),
                    (v) => setState(() => _year = v!)),
                const SizedBox(height: 12),
                _buildDropdown('出生月份', _month,
                    List.generate(12, (i) => i + 1),
                    (v) => setState(() => _month = v!),
                    displayFn: (m) => '$m月'),
                const SizedBox(height: 12),
                _buildDropdown('出生日', _day,
                    List.generate(31, (i) => i + 1),
                    (v) => setState(() => _day = v!),
                    displayFn: (d) => '$d日'),
                const SizedBox(height: 12),
                _buildDropdown('出生时辰', _hour,
                    List.generate(24, (i) => i),
                    (v) => setState(() => _hour = v!),
                    displayFn: (h) => '$h 时 (${_branches[h ~/ 2 % 12]}时)'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('性别', style: GuoXueTypography.body),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('男')),
                        ButtonSegment(value: 1, label: Text('女')),
                      ],
                      selected: {_gender},
                      onSelectionChanged: (v) =>
                          setState(() => _gender = v.first),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ClassicalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('命理咨询事项（选填）', style: GuoXueTypography.body),
                const SizedBox(height: 8),
                TextField(
                  controller: _questionController,
                  maxLength: 200,
                  maxLines: 3,
                  decoration: GuoXueDecoration.guoxueInput(
                    labelText: '',
                    hintText: '例如：我的事业运如何？何时有桃花运？',
                  ).copyWith(counterText: ''),
                  style: GuoXueTypography.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GuoXueButton(
            label: '开始排盘',
            icon: Icons.calculate_outlined,
            onPressed: _calculate,
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 八字排盘标题
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: GuoXueDecoration.classicalBlock,
            child: Column(
              children: [
                const Icon(Icons.calendar_month, size: 48,
                    color: GuoXueColors.primary),
                const SizedBox(height: 12),
                Text(_standardResults['日柱'] ?? '',
                    style: GuoXueTypography.h1),
                const SizedBox(height: 4),
                Text(
                    '日主：${_standardResults['日主'] ?? ''}    ${_standardResults['出生'] ?? ''}',
                    style: GuoXueTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 双栏结果
          DualResultView(
            methodId: 'bazi',
            standardResults: _standardResults,
            resultData: _resultData,
            userQuestion: _userQuestion,
          ),

          const SizedBox(height: 12),
          GuoXueButton(
            label: '重新排盘',
            icon: Icons.refresh,
            primary: false,
            onPressed: _reset,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T value,
    List<T> items,
    ValueChanged<T?> onChanged, {
    String Function(T)? displayFn,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GuoXueTypography.body),
        DropdownButton<T>(
          value: value,
          items: items.map((v) {
            final display = displayFn != null ? displayFn(v) : '$v';
            return DropdownMenuItem(value: v, child: Text(display));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

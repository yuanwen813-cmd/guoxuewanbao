import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_decoration.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../shared/widgets/classical_card.dart';
import '../../shared/widgets/dual_result_view.dart';
import '../../shared/widgets/guoxue_button.dart';

/// 小六壬页面
class XiaoLiuRenPage extends ConsumerStatefulWidget {
  const XiaoLiuRenPage({super.key});

  @override
  ConsumerState<XiaoLiuRenPage> createState() => _XiaoLiuRenPageState();
}

class _XiaoLiuRenPageState extends ConsumerState<XiaoLiuRenPage> {
  int _lunarMonth = 1;
  int _lunarDay = 1;
  int _hourIndex = 0; // 子=0
  final _questionController = TextEditingController();

  // 推算结果
  bool _calculated = false;
  Map<String, String> _standardResults = {};
  Map<String, dynamic> _resultData = {};
  String _userQuestion = '';

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  static const _hourBranches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
  static const _positions = ['大安', '留连', '速喜', '赤口', '小吉', '空亡'];
  static const _auspicious = ['吉', '凶', '吉', '凶', '吉', '大凶'];
  static const _elements = ['木', '水', '火', '金', '木', '土'];
  static const _directions = ['东方', '南方', '西方', '北方', '东方', '南方'];
  static const _descriptions = [
    '身不动时，五行属木，颜色青色，方位东方。求谋顺遂，凡事可成。',
    '卒未归时，五行属水，颜色黑色，方位南方。事难成就，去处未定。',
    '人便至时，五行属火，颜色红色，方位西方。喜事来临，凡事顺遂。',
    '官事凶时，五行属金，颜色白色，方位北方。口舌是非，凡事不和。',
    '人来喜时，五行属木，颜色青色，方位东方。凡事和合，多吉多利。',
    '音信稀时，五行属土，颜色黄色，方位南方。谋事不利，劳而无功。',
  ];

  void _calculate() {
    final monthPos = (_lunarMonth - 1) % 6;
    final dayPos = (monthPos + _lunarDay - 1) % 6;
    final finalPos = (dayPos + _hourIndex) % 6;

    final position = _positions[finalPos];
    final auspice = _auspicious[finalPos];
    final hourBranch = _hourBranches[_hourIndex];
    final q = _questionController.text.trim();

    setState(() {
      _calculated = true;
      _userQuestion = q.isNotEmpty
          ? q
          : '以农历$_lunarMonth月$_lunarDay日${hourBranch}时占卜';
      _standardResults = {
        '掌诀': position,
        '吉凶': auspice,
        '五行': _elements[finalPos],
        '方位': _directions[finalPos],
        '说明': _descriptions[finalPos],
      };
      _resultData = {
        'method': 'xiaoliuren',
        'position': position,
        'positionIndex': finalPos,
        'auspice': auspice,
        'element': _elements[finalPos],
        'direction': _directions[finalPos],
        'description': _descriptions[finalPos],
        'lunarMonth': _lunarMonth,
        'lunarDay': _lunarDay,
        'hourBranch': hourBranch,
      };
    });
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
      appBar: AppBar(title: const Text('小六壬')),
      body: _calculated ? _buildResult() : _buildInput(),
    );
  }

  Widget _buildInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 掌诀图示
          Container(
            height: 160,
            decoration: GuoXueDecoration.classicalBlock,
            child: const Center(
              child: Icon(Icons.pan_tool, size: 80, color: GuoXueColors.primary),
            ),
          ),
          const SizedBox(height: 20),

          ClassicalCard(
            child: Column(
              children: [
                _buildDropdown('农历月份', _lunarMonth, 12, '月', (v) => setState(() => _lunarMonth = v!)),
                const SizedBox(height: 12),
                _buildDropdown('农历日期', _lunarDay, 30, '日', (v) => setState(() => _lunarDay = v!)),
                const SizedBox(height: 12),
                _buildDropdown('时辰', _hourIndex, 12, '',
                    (v) => setState(() => _hourIndex = v!),
                    displayFn: (i) => '${_hourBranches[i]}时 (${i * 2}-${(i * 2 + 2) % 24}点)'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ClassicalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('占卜事项（选填）', style: GuoXueTypography.body),
                const SizedBox(height: 8),
                TextField(
                  controller: _questionController,
                  maxLength: 200,
                  maxLines: 3,
                  decoration: GuoXueDecoration.guoxueInput(
                    labelText: '',
                    hintText: '例如：最近事业运如何？与某人合作是否顺利？',
                  ).copyWith(counterText: ''),
                  style: GuoXueTypography.body,
                ),
                Text(
                  '${_questionController.text.length}/200',
                  style: GuoXueTypography.caption,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          GuoXueButton(
            label: '开始推算',
            icon: Icons.calculate_outlined,
            onPressed: _calculate,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>(String label, T value, int count, String suffix,
      ValueChanged<T?> onChanged, {String Function(T)? displayFn}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GuoXueTypography.body),
        DropdownButton<T>(
          value: value,
          items: List.generate(count, (i) {
            final v = (i + (T is int ? 1 : 0)) as T;
            final display = displayFn != null ? displayFn(v) : '$v$suffix';
            return DropdownMenuItem(value: v, child: Text(display));
          }),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildResult() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 掌诀大标题
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: GuoXueDecoration.classicalBlock,
            child: Column(
              children: [
                const Icon(Icons.pan_tool, size: 48, color: GuoXueColors.primary),
                const SizedBox(height: 12),
                Text(_standardResults['掌诀'] ?? '',
                    style: GuoXueTypography.h1.copyWith(
                      color: _standardResults['吉凶'] == '大凶'
                          ? GuoXueColors.error
                          : _standardResults['吉凶'] == '吉'
                              ? GuoXueColors.success
                              : GuoXueColors.warning,
                    )),
                const SizedBox(height: 4),
                Text('小六壬占卜', style: GuoXueTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 双栏结果：标准推算 + AI 解读
          DualResultView(
            methodId: 'xiaoliuren',
            standardResults: _standardResults,
            resultData: _resultData,
            userQuestion: _userQuestion,
          ),

          const SizedBox(height: 12),
          GuoXueButton(
            label: '重新占卜',
            icon: Icons.refresh,
            primary: false,
            onPressed: _reset,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

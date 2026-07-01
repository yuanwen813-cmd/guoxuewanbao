import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_decoration.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../shared/widgets/classical_card.dart';
import '../../shared/widgets/dual_result_view.dart';
import '../../shared/widgets/guoxue_button.dart';

/// 金钱卦页面
class MoneyHexagramPage extends ConsumerStatefulWidget {
  const MoneyHexagramPage({super.key});

  @override
  ConsumerState<MoneyHexagramPage> createState() => _MoneyHexagramPageState();
}

class _MoneyHexagramPageState extends ConsumerState<MoneyHexagramPage> {
  final _random = Random();
  final List<int> _throws = []; // 每爻正面数量 (0-3)
  bool _isShaking = false;
  bool _completed = false;
  final _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  // 卦名与爻名
  static const _yaoStages = ['初', '二', '三', '四', '五', '上'];
  static const _yaoSymbols = ['老阴 ⚋×', '少阳 ⚊', '少阴 ⚋', '老阳 ⚊○'];
  static const _yaoNames = ['老阴', '少阳', '少阴', '老阳'];

  String get _trigramName {
    if (_throws.length < 6) return '';
    // 上三爻为外卦，下三爻为内卦
    final upper = _throws.reversed.take(3).map(yinYang).join();
    final lower = _throws.reversed.skip(3).take(3).map(yinYang).join();
    return '$lower$upper';
  }

  /// 0→0(老阴), 1→1(少阳), 2→0(少阴), 3→1(老阳)  => 阴阳值
  static int yinYang(int heads) => heads == 0 || heads == 2 ? 0 : 1;

  String get _fullHexagram {
    // 简化：用64卦映射
    if (_throws.length < 6) return '';
    final lines = _throws.reversed.map(yinYang).toList();
    // 上卦(外) lines[0..2], 下卦(内) lines[3..5]
    return _identifyHexagram(lines);
  }

  Map<String, dynamic> get _resultData {
    if (_throws.length < 6) return {};
    return {
      'method': 'money_hexagram',
      'throws': _throws.reversed.toList(),
      'yaoLines': _throws.reversed
          .toList()
          .asMap()
          .entries
          .map((e) => {
                'stage': _yaoStages[e.key],
                'heads': e.value,
                'symbol': _yaoSymbols[e.value],
                'name': _yaoNames[e.value],
                'yinYang': yinYang(e.value),
              })
          .toList(),
      'hexagram': _fullHexagram,
      'trigramName': _trigramName,
    };
  }

  Map<String, String> get _standardResults {
    if (_throws.length < 6) return {};
    final yaoDescs = _throws.reversed.toList().asMap().entries.map((e) {
      final changing = e.value == 0 || e.value == 3 ? '（动爻）' : '';
      return '第${e.key + 1}爻（${_yaoStages[e.key]}）：${_yaoSymbols[e.value]} $changing';
    }).join('\n');

    final changingYaos = _throws.reversed
        .toList()
        .asMap()
        .entries
        .where((e) => e.value == 0 || e.value == 3)
        .map((e) => _yaoStages[e.key])
        .toList();

    return {
      '本卦': _fullHexagram,
      '上卦/下卦': _trigramName,
      '各爻': yaoDescs,
      if (changingYaos.isNotEmpty) '动爻': changingYaos.join('、'),
    };
  }

  void _shake() {
    if (_throws.length >= 6) return;

    setState(() => _isShaking = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final heads = _random.nextInt(4); // 0-3
      setState(() {
        _throws.add(heads);
        _isShaking = false;
        if (_throws.length >= 6) _completed = true;
      });
    });
  }

  void _reset() {
    _questionController.clear();
    setState(() {
      _throws.clear();
      _completed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('金钱卦')),
      body: _completed ? _buildResult() : _buildRitual(),
    );
  }

  Widget _buildRitual() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 铜钱仪式区
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
            child: Center(
              child: _isShaking
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monetization_on, size: 48, color: GuoXueColors.gold),
                        SizedBox(height: 8),
                        Text('摇卦中...', style: TextStyle(color: GuoXueColors.gold)),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '第 ${_throws.length + 1} / 6 次',
                          style: const TextStyle(color: GuoXueColors.goldLight, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '屏气凝神清空思想，心中拜神求问自己所卜之事，\n待到气息憋不住时（脑中极度空白），点击摇卦',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // 已摇列表
          if (_throws.isNotEmpty)
            ClassicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('已摇卦象', style: GuoXueTypography.h3),
                  const SizedBox(height: 8),
                  ...List.generate(_throws.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${_yaoStages[i]}爻：${_yaoSymbols[_throws[i]]}',
                        style: GuoXueTypography.body,
                      ),
                    );
                  }),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // 占卜事项输入
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
                    hintText: '例如：最近财运如何？某项目是否可成？',
                  ).copyWith(counterText: ''),
                  style: GuoXueTypography.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: GuoXueButton(
                  label: _throws.length >= 6
                      ? '成卦完毕'
                      : '摇卦（第${_throws.length + 1}/6次）',
                  icon: Icons.casino,
                  onPressed: _throws.length >= 6 || _isShaking ? null : _shake,
                ),
              ),
              if (_throws.isNotEmpty) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _isShaking ? null : _reset,
                  child: const Text('重来'),
                ),
              ],
            ],
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
          // 卦名大标题
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: GuoXueDecoration.classicalBlock,
            child: Column(
              children: [
                const Icon(Icons.monetization_on, size: 48, color: GuoXueColors.gold),
                const SizedBox(height: 12),
                Text(_fullHexagram, style: GuoXueTypography.h1),
                const SizedBox(height: 4),
                Text('金钱卦 · 六爻纳甲', style: GuoXueTypography.caption),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 双栏结果
          DualResultView(
            methodId: 'money_hexagram',
            standardResults: _standardResults,
            resultData: _resultData,
            userQuestion: _questionController.text.trim().isNotEmpty
                ? _questionController.text.trim()
                : '金钱卦占卜：${_fullHexagram}',
          ),

          const SizedBox(height: 12),
          GuoXueButton(
            label: '重新摇卦',
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

/// 简约64卦识别（用上下三爻的阴阳排列匹配）
String _identifyHexagram(List<int> lines) {
  // lines: [上1,上2,上3, 下1,下2,下3]  都是0或1
  final upper = lines.sublist(0, 3);
  final lower = lines.sublist(3, 6);

  // 八卦索引: 乾兑离震巽坎艮坤
  final trigrams = {
    '111': '乾', '110': '兑', '101': '离', '100': '震',
    '011': '巽', '010': '坎', '001': '艮', '000': '坤',
  };

  final upperName = trigrams[upper.join()] ?? '?';
  final lowerName = trigrams[lower.join()] ?? '?';

  // 六十四卦名（上下组合）
  final hexagramNames = {
    '乾乾': '乾为天', '乾兑': '泽天夬', '乾离': '火天大有', '乾震': '雷天大壮',
    '乾巽': '风天小畜', '乾坎': '水天需', '乾艮': '山天大畜', '乾坤': '地天泰',
    '兑乾': '天泽履', '兑兑': '兑为泽', '兑离': '火泽睽', '兑震': '雷泽归妹',
    '兑巽': '风泽中孚', '兑坎': '水泽节', '兑艮': '山泽损', '兑坤': '地泽临',
    '离乾': '天火同人', '离兑': '泽火革', '离离': '离为火', '离震': '雷火丰',
    '离巽': '风火家人', '离坎': '水火既济', '离艮': '山火贲', '离坤': '地火明夷',
    '震乾': '天雷无妄', '震兑': '泽雷随', '震离': '火雷噬嗑', '震震': '震为雷',
    '震巽': '风雷益', '震坎': '水雷屯', '震艮': '山雷颐', '震坤': '地雷复',
    '巽乾': '天风姤', '巽兑': '泽风大过', '巽离': '火风鼎', '巽震': '雷风恒',
    '巽巽': '巽为风', '巽坎': '水风井', '巽艮': '山风蛊', '巽坤': '地风升',
    '坎乾': '天水讼', '坎兑': '泽水困', '坎离': '火水未济', '坎震': '雷水解',
    '坎巽': '风水涣', '坎坎': '坎为水', '坎艮': '山水蒙', '坎坤': '地水师',
    '艮乾': '天山遁', '艮兑': '泽山咸', '艮离': '火山旅', '艮震': '雷山小过',
    '艮巽': '风山渐', '艮坎': '水山蹇', '艮艮': '艮为山', '艮坤': '地山谦',
    '坤乾': '天地否', '坤兑': '泽地萃', '坤离': '火地晋', '坤震': '雷地豫',
    '坤巽': '风地观', '坤坎': '水地比', '坤艮': '山地剥', '坤坤': '坤为地',
  };

  return hexagramNames['$upperName$lowerName'] ?? '$upperName$lowerName';
}

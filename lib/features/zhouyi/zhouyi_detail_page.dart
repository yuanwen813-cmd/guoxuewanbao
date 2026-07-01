import 'package:flutter/material.dart';
import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../shared/widgets/classical_card.dart';
import 'zhouyi_models.dart';

/// 周易本经卦详情页 —— 卦名/卦象/上下卦/卦辞/象辞/爻辞/白话说明
class ZhouyiDetailPage extends StatelessWidget {
  final ZhouyiHexagram hexagram;
  const ZhouyiDetailPage({super.key, required this.hexagram});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(hexagram.name),
        backgroundColor: const Color(0xFF1A1410),
      ),
      backgroundColor: const Color(0xFF1A1410),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            _buildTrigrams(),
            const SizedBox(height: 14),
            _buildJudgment(),
            const SizedBox(height: 10),
            _buildImage(),
            const SizedBox(height: 16),
            _buildYaoLines(),
            const SizedBox(height: 16),
            _buildPlainText(),
          ],
        ),
      ),
    );
  }

  /// 卦名 + 卦序 + 卦象
  Widget _buildHeader() {
    return ClassicalCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            hexagram.symbol,
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 8),
          Text(
            hexagram.name,
            style: GuoXueTypography.h2.copyWith(color: GuoXueColors.gold),
          ),
          const SizedBox(height: 4),
          Text(
            '第${hexagram.number}卦',
            style:
                GuoXueTypography.caption.copyWith(color: GuoXueColors.inkGray),
          ),
        ],
      ),
    );
  }

  /// 上卦 / 下卦
  Widget _buildTrigrams() {
    return ClassicalCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: _trigramBlock('下卦', hexagram.lowerTrigram),
          ),
          Container(
            width: 1,
            height: 40,
            color: GuoXueColors.gold.withOpacity(0.3),
          ),
          Expanded(
            child: _trigramBlock('上卦', hexagram.upperTrigram),
          ),
        ],
      ),
    );
  }

  Widget _trigramBlock(String label, String trigramName) {
    return Column(
      children: [
        Text(label,
            style: GuoXueTypography.caption
                .copyWith(color: GuoXueColors.inkLight)),
        const SizedBox(height: 4),
        Text(
          trigramName.isNotEmpty ? trigramName : '—',
          style: GuoXueTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: GuoXueColors.inkBlack,
          ),
        ),
      ],
    );
  }

  /// 卦辞
  Widget _buildJudgment() {
    return ClassicalCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('卦辞'),
          const SizedBox(height: 8),
          const Divider(color: GuoXueColors.gold),
          const SizedBox(height: 8),
          Text(
            hexagram.judgment.isNotEmpty ? hexagram.judgment : '（暂无）',
            style: GuoXueTypography.body.copyWith(
              color: GuoXueColors.inkBlack,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// 象辞
  Widget _buildImage() {
    return ClassicalCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('象辞'),
          const SizedBox(height: 8),
          const Divider(color: GuoXueColors.gold),
          const SizedBox(height: 8),
          Text(
            hexagram.image.isNotEmpty ? hexagram.image : '（暂无）',
            style: GuoXueTypography.body.copyWith(
              color: GuoXueColors.inkBlack,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// 六爻爻辞
  Widget _buildYaoLines() {
    return ClassicalCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('六爻'),
          const SizedBox(height: 8),
          const Divider(color: GuoXueColors.gold),
          const SizedBox(height: 8),
          for (final yao in hexagram.lines.reversed) // 上爻在上
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _yaoBlock(yao),
            ),
        ],
      ),
    );
  }

  Widget _yaoBlock(ZhouyiYaoLine yao) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: GuoXueColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: GuoXueColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  yao.lineName.isNotEmpty ? yao.lineName : '第${yao.line}爻',
                  style: GuoXueTypography.caption.copyWith(
                    color: GuoXueColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  yao.displayText,
                  style: GuoXueTypography.body.copyWith(
                    color: GuoXueColors.inkBlack,
                  ),
                ),
              ),
            ],
          ),
          if (yao.meaning.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              yao.displayMeaning,
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.inkGray,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 简短白话说明
  Widget _buildPlainText() {
    return ClassicalCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('白话说明'),
          const SizedBox(height: 8),
          const Divider(color: GuoXueColors.gold),
          const SizedBox(height: 8),
          Text(
            hexagram.plainText.isNotEmpty ? hexagram.plainText : '（暂无）',
            style: GuoXueTypography.body.copyWith(
              color: GuoXueColors.inkBlack,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: GuoXueColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GuoXueTypography.h3.copyWith(color: GuoXueColors.gold),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../shared/widgets/classical_card.dart';
import 'zhouyi_models.dart';
import 'zhouyi_repository.dart';

class TakashimaReferencePage extends StatefulWidget {
  const TakashimaReferencePage({super.key});

  @override
  State<TakashimaReferencePage> createState() => _TakashimaReferencePageState();
}

class _TakashimaReferencePageState extends State<TakashimaReferencePage> {
  final _repo = ZhouyiRepository();
  final _searchController = TextEditingController();
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.init();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('高岛易断资料'),
        backgroundColor: const Color(0xFF1A1410),
      ),
      backgroundColor: const Color(0xFF1A1410),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final hexagrams = _filteredHexagrams();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            key: const Key('takashima_search_field'),
            controller: _searchController,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            decoration: InputDecoration(
              hintText: '搜索卦名，例如：乾、坤、泰、未济',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white38, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.clear,
                        size: 18,
                        color: Colors.white38,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
        Expanded(
          child: hexagrams.isEmpty
              ? Center(
                  child: Text(
                    '没有找到相关卦名',
                    style: GuoXueTypography.body.copyWith(
                      color: Colors.white38,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: hexagrams.length,
                  itemBuilder: (context, index) {
                    final hexagram = hexagrams[index];
                    return _HexagramTile(hexagram: hexagram);
                  },
                ),
        ),
      ],
    );
  }

  List<ZhouyiHexagram> _filteredHexagrams() {
    final keyword = _query.toLowerCase();
    if (keyword.isEmpty) return _repo.allHexagrams;
    return _repo.allHexagrams.where((hexagram) {
      return hexagram.name.toLowerCase().contains(keyword) ||
          hexagram.number.toString() == keyword ||
          hexagram.upperTrigram.toLowerCase().contains(keyword) ||
          hexagram.lowerTrigram.toLowerCase().contains(keyword);
    }).toList();
  }
}

class _HexagramTile extends StatelessWidget {
  final ZhouyiHexagram hexagram;

  const _HexagramTile({required this.hexagram});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClassicalCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TakashimaReferenceDetailPage(hexagram: hexagram),
            ),
          );
        },
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(hexagram.symbol, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${hexagram.number}. ${hexagram.name}',
                    style: GuoXueTypography.body.copyWith(
                      color: GuoXueColors.inkBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${hexagram.lowerTrigram}卦 · ${hexagram.upperTrigram}卦 · 高岛式断法参考',
                    style: GuoXueTypography.caption.copyWith(
                      color: GuoXueColors.inkGray,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: GuoXueColors.inkLight),
          ],
        ),
      ),
    );
  }
}

class TakashimaReferenceDetailPage extends StatelessWidget {
  final ZhouyiHexagram hexagram;

  const TakashimaReferenceDetailPage({
    super.key,
    required this.hexagram,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('高岛易断 · ${hexagram.name}'),
        backgroundColor: const Color(0xFF1A1410),
      ),
      backgroundColor: const Color(0xFF1A1410),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(hexagram: hexagram),
            const SizedBox(height: 12),
            _TextSection(title: '卦辞', body: hexagram.judgment),
            const SizedBox(height: 10),
            _TextSection(title: '象辞', body: hexagram.image),
            const SizedBox(height: 10),
            _YaoSection(lines: hexagram.lines),
            const SizedBox(height: 10),
            _TextSection(title: '白话说明', body: hexagram.plainText),
            const SizedBox(height: 10),
            _TextSection(
              title: '高岛式断法参考',
              body: _takashimaReference(hexagram),
            ),
            const SizedBox(height: 10),
            _TextSection(
              title: '邵雍象数提示',
              body: _shaoyongNote(hexagram),
            ),
          ],
        ),
      ),
    );
  }

  String _takashimaReference(ZhouyiHexagram h) {
    return '高岛易断重视本卦、动爻、变卦与所问事项之间的取象。'
        '本卦为${h.name}，下${h.lowerTrigram}上${h.upperTrigram}。'
        '断事时宜先看卦辞定大势，再看象辞取象，最后以动爻定当前关键。'
        '若无动爻，可先按卦辞与象辞作为总体参考。';
  }

  String _shaoyongNote(ZhouyiHexagram h) {
    return '邵雍一系重先天象数、体用、动静与时位。'
        '当前已接入卦象和上下卦信息：${h.lowerTrigram}为下卦，${h.upperTrigram}为上卦。'
        '尚未接入可靠的邵雍逐卦逐爻原注底本；后续若确认公版来源，可继续补充逐条注解。';
  }
}

class _Header extends StatelessWidget {
  final ZhouyiHexagram hexagram;

  const _Header({required this.hexagram});

  @override
  Widget build(BuildContext context) {
    return ClassicalCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(hexagram.symbol, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(
            hexagram.name,
            style: GuoXueTypography.h2.copyWith(color: GuoXueColors.gold),
          ),
          const SizedBox(height: 4),
          Text(
            '第${hexagram.number}卦 · ${hexagram.lowerTrigram}卦 · ${hexagram.upperTrigram}卦',
            style: GuoXueTypography.caption.copyWith(
              color: GuoXueColors.inkGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  final String title;
  final String body;

  const _TextSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return ClassicalCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title),
          const SizedBox(height: 8),
          const Divider(color: GuoXueColors.gold),
          const SizedBox(height: 8),
          Text(
            body.isNotEmpty ? body : '（暂无）',
            style: GuoXueTypography.body.copyWith(
              color: GuoXueColors.inkBlack,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _YaoSection extends StatelessWidget {
  final List<ZhouyiYaoLine> lines;

  const _YaoSection({required this.lines});

  @override
  Widget build(BuildContext context) {
    return ClassicalCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('六爻'),
          const SizedBox(height: 8),
          const Divider(color: GuoXueColors.gold),
          const SizedBox(height: 8),
          for (final yao in lines.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${yao.lineName}：${yao.displayText}\n白话：${yao.displayMeaning}',
                style: GuoXueTypography.body.copyWith(
                  color: GuoXueColors.inkBlack,
                  height: 1.55,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
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

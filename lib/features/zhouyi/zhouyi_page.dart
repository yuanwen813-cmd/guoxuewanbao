import 'package:flutter/material.dart';
import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../shared/widgets/classical_card.dart';
import 'zhouyi_models.dart';
import 'zhouyi_repository.dart';
import 'zhouyi_detail_page.dart';

/// 周易本经列表页 —— 64 卦完整列表
class ZhouyiPage extends StatefulWidget {
  const ZhouyiPage({super.key});

  @override
  State<ZhouyiPage> createState() => _ZhouyiPageState();
}

class _ZhouyiPageState extends State<ZhouyiPage> {
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
        title: const Text('周易本经'),
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
            key: const Key('zhouyi_search_field'),
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
                      icon: const Icon(Icons.clear,
                          size: 18, color: Colors.white38),
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
              : _buildList(hexagrams),
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

  Widget _buildList(List<ZhouyiHexagram> hexagrams) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: hexagrams.length,
      itemBuilder: (context, index) {
        final h = hexagrams[index];
        return _HexagramTile(hexagram: h);
      },
    );
  }
}

/// 单个卦列表项
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
              builder: (_) => ZhouyiDetailPage(hexagram: hexagram),
            ),
          );
        },
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // 卦序
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: GuoXueColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${hexagram.number}',
                  style: GuoXueTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: GuoXueColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 卦象符号
            Text(
              hexagram.symbol,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 10),
            // 卦名 + 上下卦
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hexagram.name,
                    style: GuoXueTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: GuoXueColors.inkBlack,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${hexagram.lowerTrigram}下${hexagram.upperTrigram}上',
                    style: GuoXueTypography.caption.copyWith(
                      color: GuoXueColors.inkGray,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // 箭头
            const Icon(Icons.chevron_right, color: GuoXueColors.inkLight),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../domain/history/divination_history.dart';
import '../../infrastructure/history_service/history_service.dart';
import '../../shared/widgets/classical_card.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final _searchCtl = TextEditingController();
  String _activeFilter = 'all';
  String _searchText = '';

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  List<DivinationHistory> _getFiltered() {
    final svc = ref.read(historyServiceProvider);
    return svc.searchAndFilter(keyword: _searchText, featureId: _activeFilter);
  }

  void _toggleFavorite(String id) {
    ref.read(historyServiceProvider).toggleFavorite(id);
    setState(() {});
  }

  void _confirmDelete(BuildContext context, DivinationHistory r) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('确定删除这条记录吗？'),
              content: const Text('删除后不可恢复。'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消')),
                TextButton(
                    onPressed: () {
                      ref.read(historyServiceProvider).delete(r.id);
                      Navigator.pop(ctx);
                      setState(() {});
                    },
                    child: const Text('删除',
                        style: TextStyle(color: GuoXueColors.error))),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(historyServiceProvider);
    final records = _getFiltered();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1410),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1410),
        title: const Text('历史中心'),
        centerTitle: true,
      ),
      body: Column(children: [
        // 统计区
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _statChip('总记录', svc.count),
            _statChip('本周', svc.weeklyCount),
            _statChip('收藏', svc.favoriteCount),
          ]),
        ),

        // 搜索区
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: TextField(
            controller: _searchCtl,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            decoration: InputDecoration(
              hintText: '搜索问题、卦名或解读关键词',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white38, size: 20),
              suffixIcon: _searchText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          size: 18, color: Colors.white38),
                      onPressed: () {
                        _searchCtl.clear();
                        setState(() => _searchText = '');
                      })
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _searchText = v),
          ),
        ),

        // 筛选 Tab
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              _filterTab('全部', 'all'),
              _filterTab('每日一卦', 'daily_hexagram'),
              _filterTab('高岛易断', 'takashima_yi'),
              _filterTab('金钱卦', 'coin_hexagram'),
              _filterTab('小六壬', 'small_liuren'),
              _filterTab('梅花易数', 'meihua_yi'),
              _filterTab('收藏', 'favorite'),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // 列表
        Expanded(
          child: records.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: records.length,
                  itemBuilder: (_, i) => _buildCard(records[i]),
                ),
        ),
      ]),
    );
  }

  Widget _statChip(String label, int count) {
    return Column(children: [
      Text('$count',
          style: GuoXueTypography.h3
              .copyWith(color: GuoXueColors.gold, fontSize: 20)),
      Text(label,
          style: GuoXueTypography.caption
              .copyWith(color: Colors.white38, fontSize: 10)),
    ]);
  }

  Widget _filterTab(String label, String id) {
    final active = _activeFilter == id;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? GuoXueColors.gold.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: active
              ? Border.all(color: GuoXueColors.gold.withOpacity(0.4))
              : null,
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? GuoXueColors.gold : Colors.white54,
                fontSize: 12)),
      ),
    );
  }

  Widget _buildCard(DivinationHistory r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClassicalCard(
        onTap: () => context.push('/history/detail/${r.id}'),
        padding: const EdgeInsets.all(14),
        color: const Color(0xFF2A2218),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: GuoXueColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(r.featureName,
                    style: GuoXueTypography.caption.copyWith(
                        color: GuoXueColors.goldLight, fontSize: 10))),
            if (_hasAiReports(r)) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: GuoXueColors.gold.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: GuoXueColors.gold.withOpacity(0.28)),
                ),
                child: Text(
                  '含 AI 解析',
                  style: GuoXueTypography.caption.copyWith(
                    color: GuoXueColors.gold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Text(_formatTime(r.createdAt),
                style: GuoXueTypography.caption
                    .copyWith(color: Colors.white38, fontSize: 10)),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _toggleFavorite(r.id),
              child: Icon(r.isFavorite ? Icons.star : Icons.star_border,
                  size: 18,
                  color: r.isFavorite ? GuoXueColors.gold : Colors.white24),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _confirmDelete(context, r),
              child: const Icon(Icons.delete_outline,
                  size: 16, color: Colors.white24),
            ),
          ]),
          if (r.question != null && r.question!.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(r.question!,
                    style:
                        GuoXueTypography.body.copyWith(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(r.summary,
                  style: GuoXueTypography.caption
                      .copyWith(color: GuoXueColors.goldLight),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    final isSearch = _searchText.isNotEmpty;
    final isFilter = _activeFilter != 'all';
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(isSearch ? Icons.search_off : Icons.history,
          size: 48, color: Colors.white.withOpacity(0.15)),
      const SizedBox(height: 12),
      Text(
          isSearch
              ? '没有找到相关记录'
              : isFilter
                  ? '当前分类暂无记录'
                  : '暂无测算记录',
          style: GuoXueTypography.body.copyWith(color: Colors.white38)),
      const SizedBox(height: 4),
      Text(isSearch ? '可以换个关键词试试' : '完成一次占测后，可在这里回看结果。',
          style: GuoXueTypography.caption.copyWith(color: Colors.white24)),
      if (!isSearch && !isFilter) ...[
        const SizedBox(height: 16),
        TextButton(
            onPressed: () => context.go('/'), child: const Text('去首页看看')),
      ],
    ]));
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day)
      return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day)
      return '昨天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.month}/${dt.day}';
  }

  bool _hasAiReports(DivinationHistory record) {
    try {
      final reports = record.resultSnapshot['aiReports'];
      return reports is List && reports.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../domain/common/common_result_models.dart';
import '../../domain/history/divination_history.dart';
import '../../infrastructure/history_service/history_service.dart';
import '../../app/registry/feature_registry.dart';
import '../../shared/widgets/classical_card.dart';
import 'home_state.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  HomeState _homeState = const HomeState(todayDate: '', todayTip: '', dailyStatus: DailyHexagramStatus.loading);

  @override void initState() { super.initState(); _load(); }

  void _load() {
    final now = DateTime.now();
    final dateStr = '${now.year}年${now.month}月${now.day}日';
    final dateKey = '${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}';
    final tip = HomeState.tips[now.day % HomeState.tips.length];

    // Check daily hexagram status
    final records = ref.read(historyServiceProvider).getAll();
    DivinationHistory? todayDaily;
    for (final r in records) {
      if (r.featureId == 'daily_hexagram') {
        final snap = r.resultSnapshot;
        if (snap['dateKey'] == dateKey) { todayDaily = r; break; }
      }
    }

    String? dailySummary, dailyVerdict;
    DailyHexagramStatus dailyStatus = DailyHexagramStatus.notDrawn;
    if (todayDaily != null) {
      dailyStatus = DailyHexagramStatus.drawn;
      dailySummary = todayDaily.summary;
      try {
        final cr = CommonDivinationResult.fromJson(todayDaily.resultSnapshot);
        dailyVerdict = cr.finalVerdict;
      } catch (_) {}
    }

    // Recent 3 non-daily records
    final recent = records
        .where((r) => r.featureId != 'daily_hexagram')
        .take(3)
        .toList();

    setState(() {
      _homeState = HomeState(
        todayDate: dateStr, todayTip: tip, dailyStatus: dailyStatus,
        dailySummary: dailySummary, dailyVerdict: dailyVerdict,
        recentHistories: recent, featureCards: HomeState.featureConfigs,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _homeState;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1410),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 24),
            _buildBrand(s),
            const SizedBox(height: 24),
            _buildDailyCard(s),
            const SizedBox(height: 24),
            _buildToolSection(),
            const SizedBox(height: 24),
            _buildFeatureSection(),
            const SizedBox(height: 24),
            _buildCategorySection(),
            const SizedBox(height: 24),
            _buildRecentHistory(s),
            const SizedBox(height: 24),
            _buildFooter(),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  // ===== 品牌区 =====
  Widget _buildBrand(HomeState s) {
    return Column(children: [
      Text('国学万宝匣', style: GuoXueTypography.h1.copyWith(color: GuoXueColors.ricePaper, fontSize: 32)),
      const SizedBox(height: 6),
      Text('问事有法，观象知机', style: GuoXueTypography.body.copyWith(color: GuoXueColors.gold)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
        child: Text(s.todayDate, style: GuoXueTypography.bodySmall.copyWith(color: Colors.white54)),
      ),
      const SizedBox(height: 10),
      Text(s.todayTip, style: GuoXueTypography.caption.copyWith(color: Colors.white38, fontStyle: FontStyle.italic)),
    ]);
  }

  // ===== 每日一卦主卡片 =====
  Widget _buildDailyCard(HomeState s) {
    final isDrawn = s.dailyStatus == DailyHexagramStatus.drawn;
    return GestureDetector(
      onTap: () => context.push('/daily_hexagram'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3E2723), Color(0xFF1A0D05)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GuoXueColors.gold.withOpacity(0.2)),
        ),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.auto_awesome, color: GuoXueColors.gold, size: 28),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('每日一卦', style: GuoXueTypography.h2.copyWith(color: GuoXueColors.ricePaper)),
              const SizedBox(height: 2),
              Text('每日一念，观今日之象', style: GuoXueTypography.caption.copyWith(color: Colors.white54)),
            ]),
          ]),
          if (isDrawn && s.dailySummary != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Text(s.dailySummary!, style: GuoXueTypography.body.copyWith(color: Colors.white70), textAlign: TextAlign.center),
                if (s.dailyVerdict != null) ...[
                  const SizedBox(height: 6),
                  Text(s.dailyVerdict!, style: GuoXueTypography.caption.copyWith(color: GuoXueColors.goldLight), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                ],
              ]),
            ),
          ] else
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Icon(Icons.auto_awesome, color: GuoXueColors.gold, size: 56)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(color: GuoXueColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: GuoXueColors.gold.withOpacity(0.3))),
            child: Text(isDrawn ? '查看今日卦象' : '抽取今日卦象', style: GuoXueTypography.body.copyWith(color: GuoXueColors.gold)),
          ),
        ]),
      ),
    );
  }

  // ===== 每日工具 =====
  Widget _buildToolSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Text("每日工具", style: GuoXueTypography.h2.copyWith(color: GuoXueColors.ricePaper))),
      ...HomeState.toolConfigs.map(_buildFeatureCard),
    ]);
  }

  // ===== 8 大功能分类 =====
  Widget _buildCategorySection() {
    final registryAsync = ref.watch(featureRegistryProvider);
    return registryAsync.when(
      data: (registry) {
        final cats = registry.categories;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('功能分类', style: GuoXueTypography.h2.copyWith(color: GuoXueColors.ricePaper))),
          ...cats.map((cat) {
            final count = registry.featuresByCategory(cat.id).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClassicalCard(
                onTap: () => context.push('/category/${cat.id}'),
                padding: const EdgeInsets.all(14),
                color: const Color(0xFF2A2218),
                child: Row(children: [
                  Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: _hexToColor(cat.color).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(_resolveIcon(cat.icon), color: _hexToColor(cat.color), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(cat.name, style: GuoXueTypography.h3.copyWith(color: GuoXueColors.ricePaper)),
                    const SizedBox(height: 2),
                    Text('$count 项功能', style: GuoXueTypography.caption.copyWith(color: Colors.white54)),
                  ])),
                  const Icon(Icons.chevron_right, color: Colors.white24),
                ]),
              ),
            );
          }),
        ]);
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  Color _hexToColor(String hex) {
    try { return Color(int.parse(hex.replaceFirst('#', '0xff'))); } catch (_) { return GuoXueColors.primary; }
  }

  IconData _resolveIcon(String name) => switch (name) {
    'today' => Icons.today, 'auto_awesome' => Icons.auto_awesome, 'bolt' => Icons.bolt,
    'person' => Icons.person, 'card_giftcard' => Icons.card_giftcard, 'explore' => Icons.explore,
    'event' => Icons.event, 'celebration' => Icons.celebration, _ => Icons.category,
  };

  // ===== 常用占测 =====
  Widget _buildFeatureSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 12), child: Text('常用占测', style: GuoXueTypography.h2.copyWith(color: GuoXueColors.ricePaper))),
      ...HomeState.featureConfigs.map(_buildFeatureCard),
    ]);
  }

  Widget _buildFeatureCard(FeatureCardConfig f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClassicalCard(
        onTap: () => context.push(f.route),
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF2A2218),
        child: Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(color: GuoXueColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Icon(f.featureId == 'small_liuren' ? Icons.pan_tool_alt : f.featureId == 'takashima_yi' ? Icons.grass : Icons.local_florist, color: GuoXueColors.gold, size: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.featureName, style: GuoXueTypography.h3.copyWith(color: GuoXueColors.ricePaper)),
            const SizedBox(height: 2),
            Text(f.subtitle, style: GuoXueTypography.caption.copyWith(color: Colors.white54)),
            const SizedBox(height: 2),
            Text(f.description, style: GuoXueTypography.caption.copyWith(color: Colors.white38, fontSize: 11)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: GuoXueColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
            child: Text(f.buttonLabel, style: GuoXueTypography.caption.copyWith(color: GuoXueColors.goldLight)),
          ),
        ]),
      ),
    );
  }

  // ===== 最近历史 =====
  Widget _buildRecentHistory(HomeState s) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('最近记录', style: GuoXueTypography.h2.copyWith(color: GuoXueColors.ricePaper))),
        if (s.recentHistories.isNotEmpty)
          GestureDetector(onTap: () => context.push('/history'), child: Text('查看全部', style: GuoXueTypography.caption.copyWith(color: GuoXueColors.goldLight))),
      ]),
      const SizedBox(height: 10),
      if (s.recentHistories.isEmpty)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Icon(Icons.history, color: Colors.white.withOpacity(0.2), size: 40),
            const SizedBox(height: 10),
            Text('暂无测算记录', style: GuoXueTypography.caption.copyWith(color: Colors.white38)),
            const SizedBox(height: 4),
            Text('完成一次占测后，可在这里快速回看。', style: GuoXueTypography.caption.copyWith(color: Colors.white24, fontSize: 11)),
          ]),
        )
      else
        ...s.recentHistories.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ClassicalCard(
            onTap: () => context.push('/history/detail/${r.id}'),
            padding: const EdgeInsets.all(14),
            color: const Color(0xFF2A2218),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(r.featureName, style: GuoXueTypography.body.copyWith(color: GuoXueColors.ricePaper, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Text(_formatTime(r.createdAt), style: GuoXueTypography.caption.copyWith(color: Colors.white38, fontSize: 10)),
                ]),
                if (r.question != null && r.question!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(r.question!, style: GuoXueTypography.caption.copyWith(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Padding(padding: const EdgeInsets.only(top: 2), child: Text(r.summary, style: GuoXueTypography.caption.copyWith(color: GuoXueColors.goldLight), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ])),
              const Icon(Icons.chevron_right, color: Colors.white24),
            ]),
          ),
        )),
    ]);
  }

  // ===== 底部 =====
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
      child: Text('本应用内容仅供传统文化研究与娱乐参考，\n不构成投资、医疗、法律或其他专业建议。',
        textAlign: TextAlign.center,
        style: GuoXueTypography.caption.copyWith(color: Colors.white24, fontSize: 11)),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '今天 ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return '昨天 ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    }
    return '${dt.month}/${dt.day}';
  }
}

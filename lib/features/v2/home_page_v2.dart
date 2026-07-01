import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../domain/history/divination_history.dart';
import '../../infrastructure/history_service/history_service.dart';
import '../home/home_state.dart';
import 'feature_catalog_v2.dart';
import 'v2_page_scaffold.dart';

class HomePageV2 extends ConsumerWidget {
  const HomePageV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dateText = '${now.year}年${now.month}月${now.day}日';
    final tip = HomeState.tips[now.day % HomeState.tips.length];
    final recentRecords = ref.watch(historyServiceProvider).getRecent(2);

    return V2PageScaffold(
      title: '国学万宝匣',
      subtitle: '有事问卦，看命推演，每日查历，经典可考。',
      icon: Icons.auto_awesome,
      children: [
        _TodayStrip(dateText: dateText, tip: tip),
        const V2SectionTitle(title: '今日要览'),
        V2FeatureGrid(
          entries: [
            FeatureCatalogV2.homeHighlights[0],
            FeatureCatalogV2.homeHighlights[1],
          ],
        ),
        const SizedBox(height: 8),
        const V2SectionTitle(title: '功能导航'),
        V2FeatureGrid(
          entries: [
            FeatureCatalogV2.homeHighlights[2],
            FeatureCatalogV2.homeHighlights[3],
            FeatureCatalogV2.natalFeatures[1],
            FeatureCatalogV2.natalFeatures[2],
            FeatureCatalogV2.homeHighlights[4],
            FeatureCatalogV2.classicsFeatures[1],
          ],
        ),
        const SizedBox(height: 8),
        V2SectionTitle(
          title: '记录与钱包',
          trailing: '历史',
          onTapTrailing: () => context.push('/history'),
        ),
        if (recentRecords.isEmpty)
          const _HomeAssetPlaceholder()
        else
          _RecentRecordList(records: recentRecords),
      ],
    );
  }
}

class _TodayStrip extends StatelessWidget {
  final String dateText;
  final String tip;

  const _TodayStrip({required this.dateText, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: GuoXueColors.inkBlack,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_outlined,
              color: GuoXueColors.goldLight, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: GuoXueTypography.caption.copyWith(
                    color: GuoXueColors.goldLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tip,
                  style: GuoXueTypography.caption.copyWith(
                    color: Colors.white70,
                    letterSpacing: 0,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAssetPlaceholder extends StatelessWidget {
  const _HomeAssetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        V2FeatureTile(
          entry: FeatureEntryV2(
            id: 'history',
            title: '历史记录',
            subtitle: '问事记录、结果快照和后续复盘都会沉淀在这里',
            route: '/history',
            icon: Icons.history,
            category: FeatureCategoryV2.mine,
            status: FeatureStatusV2.stable,
            actionLabel: '查看',
          ),
        ),
        SizedBox(height: 10),
        V2FeatureTile(
          entry: FeatureEntryV2(
            id: 'wallet',
            title: '钱包充值',
            subtitle: '查看服务端钱包余额、充值和 AI 消费流水',
            route: '/wallet',
            icon: Icons.account_balance_wallet_outlined,
            category: FeatureCategoryV2.mine,
            status: FeatureStatusV2.stable,
            actionLabel: '进入',
          ),
        ),
      ],
    );
  }
}

class _RecentRecordList extends StatelessWidget {
  final List<DivinationHistory> records;

  const _RecentRecordList({required this.records});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final record in records)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.push('/history/detail/${record.id}'),
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: GuoXueColors.ricePaper,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: GuoXueColors.gold.withOpacity(0.18)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: GuoXueColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.featureName,
                            style: GuoXueTypography.body.copyWith(
                              color: GuoXueColors.inkBlack,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            record.summary,
                            style: GuoXueTypography.caption.copyWith(
                              color: GuoXueColors.inkGray,
                              letterSpacing: 0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: GuoXueColors.inkLight),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

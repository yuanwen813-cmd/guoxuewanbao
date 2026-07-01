import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import 'natal_inference_engine.dart';
import 'natal_profile_models.dart';
import 'natal_profile_store.dart';
import 'natal_result_sections.dart';
import 'v2_page_scaffold.dart';

class NatalResultSectionPage extends ConsumerWidget {
  final NatalResultSectionType sectionType;
  final BirthProfile? profile;

  const NatalResultSectionPage({
    super.key,
    required this.sectionType,
    this.profile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = profile == null
        ? null
        : const NatalInferenceEngine().generate(profile!);
    final saved = profile != null &&
        ref.watch(birthProfileStoreProvider).any(
              (item) => item.id == profile!.id,
            );

    return switch (sectionType) {
      NatalResultSectionType.lifeOverview => _LifeOverviewPage(
          report: report,
          saved: saved,
        ),
      NatalResultSectionType.baziPillars => _BaziPillarsPage(report: report),
      NatalResultSectionType.annualFortune => _AnnualFortunePage(
          report: report,
        ),
      NatalResultSectionType.monthlyFortune => _MonthlyFortunePage(
          report: report,
        ),
      NatalResultSectionType.tiebanShenshu => _TiebanPage(report: report),
    };
  }
}

class _LifeOverviewPage extends StatelessWidget {
  final NatalInferenceReport? report;
  final bool saved;

  const _LifeOverviewPage({
    required this.report,
    required this.saved,
  });

  @override
  Widget build(BuildContext context) {
    return V2PageScaffold(
      title: '本命总览',
      subtitle: '汇总八字结构、五行分布、日主和本命基础参考。',
      icon: Icons.account_tree_outlined,
      showAppBar: true,
      children: [
        if (report == null)
          const _MissingProfileBlock()
        else ...[
          const _TextBlock(
            title: '八字命理结果已生成',
            body: '当前展示基于出生资料生成的八字命理结构，默认按北京时间排盘；不启用真太阳时、出生地经度修正或子初换日。',
          ),
          const SizedBox(height: 10),
          _ProfileSummaryBlock(profile: report!.profile),
          const SizedBox(height: 10),
          if (saved) ...[
            const _SavedProfileNotice(),
            const SizedBox(height: 10),
          ],
          _PillarSummaryBlock(report: report!),
          const SizedBox(height: 10),
          _NotesBlock(notes: report!.notes),
          const SizedBox(height: 10),
          _InsightListBlock(
            title: '本命基础参考',
            items: report!.lifeOverview,
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const Key('open_bazi_detail_from_life_overview'),
            onPressed: () => context.push(
              '/natal/reading/result/section/${NatalResultSectionType.baziPillars.routeValue}',
              extra: report!.profile,
            ),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('查看八字四柱详情'),
          ),
          const SizedBox(height: 10),
          const _DisclaimerBlock(),
        ],
      ],
    );
  }
}

class _BaziPillarsPage extends StatelessWidget {
  final NatalInferenceReport? report;

  const _BaziPillarsPage({required this.report});

  @override
  Widget build(BuildContext context) {
    return V2PageScaffold(
      title: '八字四柱',
      subtitle: '查看年柱、月柱、日柱、时柱与五行结构。',
      icon: Icons.calendar_month_outlined,
      showAppBar: true,
      children: [
        if (report == null)
          const _MissingProfileBlock()
        else ...[
          const _TextBlock(
            title: '八字四柱本地结构试运行结果已生成',
            body: '本页面仅展示本地试运行命盘结构，不作为正式八字批命依据；默认按北京时间排盘，暂不启用真太阳时或子初换日。',
          ),
          const SizedBox(height: 10),
          _ProfileSummaryBlock(profile: report!.profile),
          const SizedBox(height: 10),
          _PillarCard(pillar: report!.yearPillar),
          const SizedBox(height: 10),
          _PillarCard(pillar: report!.monthPillar),
          const SizedBox(height: 10),
          _PillarCard(pillar: report!.dayPillar),
          const SizedBox(height: 10),
          _HourPillarCard(report: report!),
          const SizedBox(height: 10),
          _BaziElementBlock(report: report!),
          const SizedBox(height: 10),
          _NotesBlock(notes: report!.notes),
          const SizedBox(height: 10),
          const _DisclaimerBlock(),
        ],
      ],
    );
  }
}

class _AnnualFortunePage extends StatelessWidget {
  final NatalInferenceReport? report;

  const _AnnualFortunePage({required this.report});

  @override
  Widget build(BuildContext context) {
    return V2PageScaffold(
      title: '流年运势',
      subtitle: '按流年干支与日主五行关系生成年度参考。',
      icon: Icons.insights_outlined,
      showAppBar: true,
      children: [
        if (report == null)
          const _MissingProfileBlock()
        else ...[
          const _TextBlock(
            title: '流年参考已生成',
            body: '以下内容以当前年份起算，展示近五年的流年干支、五行关系和行动节奏参考。',
          ),
          const SizedBox(height: 10),
          _ProfileSummaryBlock(profile: report!.profile),
          const SizedBox(height: 10),
          _FortuneListBlock(items: report!.annualFortunes),
          const SizedBox(height: 10),
          const _DisclaimerBlock(),
        ],
      ],
    );
  }
}

class _MonthlyFortunePage extends StatelessWidget {
  final NatalInferenceReport? report;

  const _MonthlyFortunePage({required this.report});

  @override
  Widget build(BuildContext context) {
    return V2PageScaffold(
      title: '月度运势',
      subtitle: '按月令与日主五行关系生成阶段性参考。',
      icon: Icons.calendar_view_month_outlined,
      showAppBar: true,
      children: [
        if (report == null)
          const _MissingProfileBlock()
        else ...[
          _TextBlock(
            title: '月度参考已生成',
            body: '以下内容以 ${report!.generatedAt.year} 年为观察年份，展示十二个月的月令节奏参考。',
          ),
          const SizedBox(height: 10),
          _ProfileSummaryBlock(profile: report!.profile),
          const SizedBox(height: 10),
          _FortuneListBlock(items: report!.monthlyFortunes),
          const SizedBox(height: 10),
          const _DisclaimerBlock(),
        ],
      ],
    );
  }
}

class _TiebanPage extends StatelessWidget {
  final NatalInferenceReport? report;

  const _TiebanPage({required this.report});

  @override
  Widget build(BuildContext context) {
    return V2PageScaffold(
      title: '铁板神数',
      subtitle: '展示本地数序参考与核时校验要点。',
      icon: Icons.functions,
      showAppBar: true,
      children: [
        if (report == null)
          const _MissingProfileBlock()
        else ...[
          const _TextBlock(
            title: '铁板神数参考已生成',
            body: '本页根据出生资料与四柱结构生成本地数序候选，供后续核时与条文筛选使用。',
          ),
          const SizedBox(height: 10),
          _ProfileSummaryBlock(profile: report!.profile),
          const SizedBox(height: 10),
          _TiebanReferenceBlock(reference: report!.tiebanReference),
          const SizedBox(height: 10),
          const _DisclaimerBlock(),
        ],
      ],
    );
  }
}

class _PillarSummaryBlock extends StatelessWidget {
  final NatalInferenceReport report;

  const _PillarSummaryBlock({required this.report});

  @override
  Widget build(BuildContext context) {
    return _CardBlock(
      title: '八字结构摘要',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(label: '年柱', value: report.yearPillar.displayText),
          _SummaryRow(label: '月柱', value: report.monthPillar.displayText),
          _SummaryRow(label: '日柱', value: report.dayPillar.displayText),
          _SummaryRow(
            label: '时柱',
            value: report.hourPillar?.displayText ?? '需补充可靠出生时间',
          ),
          _SummaryRow(label: '生肖', value: report.zodiac),
          _SummaryRow(label: '五行摘要', value: report.fiveElementSummary),
          _SummaryRow(label: '日主', value: report.dayMaster),
        ],
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  final NatalPillar pillar;

  const _PillarCard({required this.pillar});

  @override
  Widget build(BuildContext context) {
    return _CardBlock(
      title: pillar.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(label: '当前结果', value: pillar.displayText),
          _SummaryRow(label: '生成依据', value: pillar.basis),
          _SummaryRow(label: '天干', value: pillar.stem.chinese),
          _SummaryRow(label: '地支', value: pillar.branch.chinese),
          _SummaryRow(
              label: '五行属性',
              value: '${pillar.stem.wuxing} / ${pillar.branch.wuxing}'),
          _SummaryRow(
              label: '阴阳属性',
              value: '${pillar.stem.yinYang} / ${pillar.branch.yinYang}'),
        ],
      ),
    );
  }
}

class _HourPillarCard extends StatelessWidget {
  final NatalInferenceReport report;

  const _HourPillarCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final pillar = report.hourPillar;
    if (pillar == null) {
      return const _CardBlock(
        title: '时柱',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(label: '当前结果', value: '需补充可靠出生时间'),
            _SummaryRow(label: '说明', value: '出生时间准确度不足，当前无法精确生成时柱。'),
          ],
        ),
      );
    }
    return _PillarCard(pillar: pillar);
  }
}

class _BaziElementBlock extends StatelessWidget {
  final NatalInferenceReport report;

  const _BaziElementBlock({required this.report});

  @override
  Widget build(BuildContext context) {
    return _CardBlock(
      title: '八字要素',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(label: '生肖', value: report.zodiac),
          _SummaryRow(label: '五行摘要', value: report.fiveElementSummary),
          _SummaryRow(label: '日主', value: report.dayMaster),
        ],
      ),
    );
  }
}

class _InsightListBlock extends StatelessWidget {
  final String title;
  final List<NatalReadingItem> items;

  const _InsightListBlock({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return _CardBlock(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GuoXueTypography.bodySmall.copyWith(
                      color: GuoXueColors.inkBlack,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    style: GuoXueTypography.caption.copyWith(
                      color: GuoXueColors.inkGray,
                      letterSpacing: 0,
                      height: 1.4,
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

class _FortuneListBlock extends StatelessWidget {
  final List<NatalFortuneItem> items;

  const _FortuneListBlock({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CardBlock(
              title: item.title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subtitle,
                    style: GuoXueTypography.bodySmall.copyWith(
                      color: GuoXueColors.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.body,
                    style: GuoXueTypography.caption.copyWith(
                      color: GuoXueColors.inkGray,
                      letterSpacing: 0,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TiebanReferenceBlock extends StatelessWidget {
  final TiebanLocalReference reference;

  const _TiebanReferenceBlock({required this.reference});

  @override
  Widget build(BuildContext context) {
    return _CardBlock(
      title: '数序参考',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(label: '出生数', value: reference.birthCode),
          _SummaryRow(label: '时辰码', value: reference.timeCode),
          _SummaryRow(
            label: '候选数序',
            value: reference.sequenceCandidates.join('、'),
          ),
          _SummaryRow(label: '说明', value: reference.summary),
          _SummaryRow(label: '核验提示', value: reference.calibrationPrompt),
        ],
      ),
    );
  }
}

class _ProfileSummaryBlock extends StatelessWidget {
  final BirthProfile profile;

  const _ProfileSummaryBlock({required this.profile});

  @override
  Widget build(BuildContext context) {
    return _CardBlock(
      title: '出生资料摘要',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(label: '名称', value: profile.displayName),
          _SummaryRow(label: '关系', value: profile.relationship.label),
          _SummaryRow(label: '性别', value: profile.gender.label),
          _SummaryRow(label: '公历出生', value: profile.birthDateText),
          _SummaryRow(label: '农历', value: profile.lunarBirthDateText ?? '未填写'),
          _SummaryRow(label: '出生地', value: profile.birthPlaceName ?? '未填写'),
          _SummaryRow(
            label: '时间准确度',
            value: profile.birthTimeAccuracy.label,
          ),
        ],
      ),
    );
  }
}

class _NotesBlock extends StatelessWidget {
  final List<String> notes;

  const _NotesBlock({required this.notes});

  @override
  Widget build(BuildContext context) {
    return _CardBlock(
      title: '计算说明',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                note,
                style: GuoXueTypography.caption.copyWith(
                  color: GuoXueColors.inkGray,
                  letterSpacing: 0,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MissingProfileBlock extends StatelessWidget {
  const _MissingProfileBlock();

  @override
  Widget build(BuildContext context) {
    return const _TextBlock(
      title: '请先填写出生资料',
      body: '从“八字命理”填写出生日期、时间和出生地后，即可生成完整结果。',
    );
  }
}

class _SavedProfileNotice extends StatelessWidget {
  const _SavedProfileNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GuoXueColors.success.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '已保存为命盘档案',
        style: GuoXueTypography.bodySmall.copyWith(
          color: GuoXueColors.success,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _DisclaimerBlock extends StatelessWidget {
  const _DisclaimerBlock();

  @override
  Widget build(BuildContext context) {
    return const _TextBlock(
      title: '说明',
      body: '本功能基于传统文化与命盘资料结构设计。本版本仅为本地测试和流程展示，不构成正式命理推算，也不构成医疗、法律、投资、婚姻等专业建议。',
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String title;
  final String body;

  const _TextBlock({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return _CardBlock(
      title: title,
      child: Text(
        body,
        style: GuoXueTypography.caption.copyWith(
          color: GuoXueColors.inkGray,
          letterSpacing: 0,
          height: 1.45,
        ),
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _CardBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GuoXueTypography.body.copyWith(
              color: GuoXueColors.inkBlack,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.inkLight,
                letterSpacing: 0,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.inkGray,
                letterSpacing: 0,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

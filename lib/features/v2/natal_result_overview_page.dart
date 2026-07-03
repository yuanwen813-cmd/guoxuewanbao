import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import 'destiny_ai_explanation_card.dart';
import 'natal_inference_engine.dart';
import 'natal_profile_models.dart';
import 'natal_result_sections.dart';
import 'natal_profile_store.dart';
import 'v2_page_scaffold.dart';

class NatalResultOverviewPage extends ConsumerWidget {
  final BirthProfile? profile;

  const NatalResultOverviewPage({super.key, this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = profile != null &&
        ref
            .watch(birthProfileStoreProvider)
            .any((item) => item.id == profile!.id);
    final report = profile == null
        ? null
        : const NatalInferenceEngine().generate(profile!);

    return V2PageScaffold(
      title: '八字命理结果',
      subtitle: '已生成八字命理结构，可进入本命总览、四柱、流年和月度查看。',
      icon: Icons.fact_check_outlined,
      showAppBar: true,
      children: [
        const _ResultScopeNotice(),
        if (profile != null) ...[
          const SizedBox(height: 10),
          _ProfileSummary(profile: profile!),
          const SizedBox(height: 10),
          if (saved)
            const _SavedNotice()
          else
            FilledButton.icon(
              key: const Key('save_birth_profile'),
              onPressed: () =>
                  ref.read(birthProfileStoreProvider.notifier).save(profile!),
              icon: const Icon(Icons.save_outlined),
              label: const Text('保存为命盘档案'),
            ),
        ],
        const SizedBox(height: 10),
        const V2SectionTitle(title: '结果子项'),
        _NatalResultSectionList(profile: profile),
        if (report != null) ...[
          const SizedBox(height: 10),
          DestinyAiExplanationCard(
            title: 'AI 详解',
            description: '可选填写想重点了解的方向；不填写则生成整体命盘详解。',
            systemPrompt:
                '你是国学万宝匣的八字命理解释助手。请基于结构化四柱、五行、流年和月度信息进行中文解释，表达要清楚、有边界。',
            contextText: report.buildAiContext(questionFocus: '整体命盘详解'),
            inputKeyName: 'bazi_ai_focus',
            buttonKeyName: 'bazi_ai_explain_button',
          ),
        ],
      ],
    );
  }
}

class _NatalResultSectionList extends StatelessWidget {
  final BirthProfile? profile;

  const _NatalResultSectionList({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final spec in natalResultSectionSpecs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NatalResultSectionTile(spec: spec, profile: profile),
          ),
      ],
    );
  }
}

class _NatalResultSectionTile extends StatelessWidget {
  final NatalResultSectionSpec spec;
  final BirthProfile? profile;

  const _NatalResultSectionTile({
    required this.spec,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('natal_section_${spec.type.routeValue}'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push(
        '/natal/reading/result/section/${spec.type.routeValue}',
        extra: profile,
      ),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GuoXueColors.ricePaper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GuoXueColors.gold.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: GuoXueColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(spec.icon, color: GuoXueColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          spec.title,
                          style: GuoXueTypography.body.copyWith(
                            color: GuoXueColors.inkBlack,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      V2StatusPill(status: spec.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    spec.positioning,
                    style: GuoXueTypography.caption.copyWith(
                      color: GuoXueColors.inkGray,
                      letterSpacing: 0,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: GuoXueColors.inkLight),
          ],
        ),
      ),
    );
  }
}

class _ResultScopeNotice extends StatelessWidget {
  const _ResultScopeNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.18)),
      ),
      child: Text(
        '八字命理结果已根据出生资料生成。默认按北京时间 UTC+8 排盘，暂不启用真太阳时、出生地经度修正或子初换日。AI 详解可不填写方向，默认生成整体命盘详解。',
        style: GuoXueTypography.caption.copyWith(
          color: GuoXueColors.inkGray,
          letterSpacing: 0,
          height: 1.45,
        ),
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  final BirthProfile profile;

  const _ProfileSummary({required this.profile});

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
            profile.displayName,
            style: GuoXueTypography.body.copyWith(
              color: GuoXueColors.inkBlack,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${profile.relationship.label} · ${profile.gender.label} · ${profile.birthDateText}',
            style: GuoXueTypography.caption.copyWith(
              color: GuoXueColors.inkGray,
              letterSpacing: 0,
            ),
          ),
          if (profile.birthPlaceName != null) ...[
            const SizedBox(height: 4),
            Text(
              '出生地：${profile.birthPlaceName}',
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.inkGray,
                letterSpacing: 0,
              ),
            ),
          ],
          if (profile.lunarBirthDateText != null) ...[
            const SizedBox(height: 4),
            Text(
              '农历：${profile.lunarBirthDateText}',
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.inkGray,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SavedNotice extends StatelessWidget {
  const _SavedNotice();

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

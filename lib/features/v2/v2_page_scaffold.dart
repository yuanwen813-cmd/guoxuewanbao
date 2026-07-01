import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import 'feature_catalog_v2.dart';

const _tabRoutes = {'/', '/ask', '/natal', '/mine'};

class V2PageScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final bool showAppBar;

  const V2PageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E7),
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _V2PageHeader(title: title, subtitle: subtitle, icon: icon),
              const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _V2PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _V2PageHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: GuoXueColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: GuoXueColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GuoXueTypography.h2.copyWith(
                    color: GuoXueColors.inkBlack,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GuoXueTypography.bodySmall.copyWith(
                    color: GuoXueColors.inkGray,
                    letterSpacing: 0,
                    height: 1.45,
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

class V2SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTapTrailing;

  const V2SectionTitle({
    super.key,
    required this.title,
    this.trailing,
    this.onTapTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GuoXueTypography.h3.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          if (trailing != null)
            TextButton(
              onPressed: onTapTrailing,
              child: Text(trailing!),
            ),
        ],
      ),
    );
  }
}

class V2FeatureList extends StatelessWidget {
  final List<FeatureEntryV2> entries;

  const V2FeatureList({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final visibleEntries = FeatureCatalogV2.visible(entries);
    return Column(
      children: [
        for (final entry in visibleEntries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: V2FeatureTile(entry: entry),
          ),
      ],
    );
  }
}

class V2FeatureGrid extends StatelessWidget {
  final List<FeatureEntryV2> entries;

  const V2FeatureGrid({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final visibleEntries = FeatureCatalogV2.visible(entries);
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 620 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleEntries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: constraints.maxWidth >= 620 ? 176 : 168,
          ),
          itemBuilder: (context, index) {
            return V2FeatureTile(entry: visibleEntries[index], compact: true);
          },
        );
      },
    );
  }
}

class V2FeatureTile extends StatelessWidget {
  final FeatureEntryV2 entry;
  final bool compact;

  const V2FeatureTile({
    super.key,
    required this.entry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = entry.route.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled ? () => _openEntry(context, entry) : null,
      child: Ink(
        padding: compact ? const EdgeInsets.all(12) : const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GuoXueColors.ricePaper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GuoXueColors.gold.withOpacity(0.18)),
        ),
        child: compact ? _buildCompact(context) : _buildList(context),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _FeatureIcon(icon: entry.icon),
            const Spacer(),
            V2StatusPill(status: entry.status),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          entry.title,
          style: GuoXueTypography.body.copyWith(
            color: GuoXueColors.inkBlack,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          entry.subtitle,
          style: GuoXueTypography.caption.copyWith(
            color: GuoXueColors.inkGray,
            letterSpacing: 0,
            height: 1.25,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              entry.actionLabel,
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 16, color: GuoXueColors.primary),
          ],
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    return Row(
      children: [
        _FeatureIcon(icon: entry.icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.title,
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
                  V2StatusPill(status: entry.status),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                entry.subtitle,
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
    );
  }

  void _openEntry(BuildContext context, FeatureEntryV2 entry) {
    if (_tabRoutes.contains(entry.route)) {
      context.go(entry.route);
      return;
    }
    context.push(entry.route);
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;

  const _FeatureIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: GuoXueColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: GuoXueColors.primary, size: 22),
    );
  }
}

class V2StatusPill extends StatelessWidget {
  final FeatureStatusV2 status;

  const V2StatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      FeatureStatusV2.stable => GuoXueColors.success,
      FeatureStatusV2.beta => GuoXueColors.info,
      FeatureStatusV2.trialPlanned => GuoXueColors.warning,
      FeatureStatusV2.comingSoon => GuoXueColors.inkLight,
      FeatureStatusV2.experimental => GuoXueColors.goldDark,
      FeatureStatusV2.hidden => GuoXueColors.inkGray,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: GuoXueTypography.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

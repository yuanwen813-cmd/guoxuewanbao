import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/registry/feature_registry.dart';
import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../shared/widgets/classical_card.dart';

/// 功能分类浏览页 —— 展示某一分类下的所有功能
class CategoryPage extends ConsumerWidget {
  final String categoryId;

  const CategoryPage({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registryAsync = ref.watch(featureRegistryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('功能大全')),
      body: registryAsync.when(
        data: (registry) => _buildContent(context, registry),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, FeatureRegistry registry) {
    final cat = registry.category(categoryId);
    final features = registry.featuresByCategory(categoryId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 分类头部
          if (cat != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _hexToColor(cat.color).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _hexToColor(cat.color).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(_resolveIcon(cat.icon),
                      size: 40, color: _hexToColor(cat.color)),
                  const SizedBox(height: 8),
                  Text(cat.name, style: GuoXueTypography.h2),
                  const SizedBox(height: 4),
                  Text(cat.description, style: GuoXueTypography.caption),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 功能网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.92,
            ),
            itemCount: features.length,
            itemBuilder: (_, i) => _FeatureTile(feature: features[i]),
          ),
        ],
      ),
    );
  }

  IconData _resolveIcon(String name) {
    return _kCatIconMap[name] ?? Icons.auto_awesome;
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

/// 功能卡片
class _FeatureTile extends ConsumerWidget {
  final FeatureConfig feature;

  const _FeatureTile({required this.feature});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClassicalCard(
      onTap: () {
        if (feature.isAvailable) {
          context.push(feature.route);
        } else {
          context.push('/placeholder/${feature.id}');
        }
      },
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标
          Stack(
            children: [
              Icon(
                _resolveIcon(feature.icon),
                size: 34,
                color: feature.isAvailable
                    ? GuoXueColors.primary
                    : GuoXueColors.inkLight,
              ),
              // 状态角标
              if (!feature.isAvailable)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: feature.isBeta
                          ? GuoXueColors.warning
                          : GuoXueColors.inkLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      feature.isBeta ? 'Beta' : '规划',
                      style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 标题
          Text(
            feature.title,
            style: GuoXueTypography.body.copyWith(
              fontWeight: FontWeight.w500,
              color: feature.isAvailable
                  ? GuoXueColors.inkBlack
                  : GuoXueColors.inkGray,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // 副标题
          Text(
            feature.subtitle,
            style: GuoXueTypography.caption.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _resolveIcon(String name) {
    return _kTileIconMap[name] ?? Icons.auto_awesome;
  }
}

// 分类 icon 映射
const _kCatIconMap = {
  'casino': Icons.casino,
  'auto_awesome': Icons.auto_awesome,
  'face': Icons.face,
  'compass_calibration': Icons.compass_calibration,
  'event_available': Icons.event_available,
  'drive_file_rename_outline': Icons.drive_file_rename_outline,
  'psychology': Icons.psychology,
  'menu_book': Icons.menu_book,
};

// 功能 tile icon 映射（精简版）
const _kTileIconMap = {
  'pan_tool_alt': Icons.pan_tool_alt,
  'monetization_on_outlined': Icons.monetization_on_outlined,
  'text_fields': Icons.text_fields,
  'water_drop': Icons.water_drop,
  'cloud': Icons.cloud,
  'shield': Icons.shield,
  'grass': Icons.grass,
  'local_florist': Icons.local_florist,
  'stars': Icons.stars,
  'calendar_month': Icons.calendar_month,
  'balance': Icons.balance,
  'nightlight': Icons.nightlight,
  'grid_on': Icons.grid_on,
  'wb_twilight': Icons.wb_twilight,
  'cruelty_free': Icons.cruelty_free,
  'calculate': Icons.calculate,
  'face_3': Icons.face_3,
  'front_hand': Icons.front_hand,
  'accessibility_new': Icons.accessibility_new,
  'mic': Icons.mic,
  'explore': Icons.explore,
  'home': Icons.home,
  'business': Icons.business,
  'house': Icons.house,
  'landscape': Icons.landscape,
  'today': Icons.today,
  'schedule': Icons.schedule,
  'construction': Icons.construction,
  'favorite': Icons.favorite,
  'badge': Icons.badge,
  'apartment': Icons.apartment,
  'child_care': Icons.child_care,
  'edit_note': Icons.edit_note,
  'bedtime': Icons.bedtime,
  'raven': Icons.pets,
  'text_increase': Icons.text_increase,
  'eco': Icons.eco,
  'book_outlined': Icons.book_outlined,
  'ac_unit': Icons.ac_unit,
  'nightlight_round': Icons.nightlight_round,
  'view_column': Icons.view_column,
  'blur_on': Icons.blur_on,
  'auto_awesome': Icons.auto_awesome,
  'casino': Icons.casino,
};

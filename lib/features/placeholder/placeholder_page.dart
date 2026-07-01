import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/registry/feature_registry.dart';
import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_decoration.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../shared/widgets/classical_card.dart';

/// 通用功能占位页
///
/// 任何未实现的功能均通过此页面展示：
/// - 已规划未开发的功能显示"敬请期待"
/// - 复杂功能显示"AI辅助解析版即将上线"
/// - 即将上线的Beta版本显示进度说明
class PlaceholderPage extends ConsumerWidget {
  final FeatureConfig feature;

  const PlaceholderPage({super.key, required this.feature});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(feature.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 功能图标
            Container(
              height: 140,
              decoration: GuoXueDecoration.classicalBlock,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _iconWidget(feature.icon),
                    const SizedBox(height: 12),
                    Text(feature.title, style: GuoXueTypography.h2),
                    const SizedBox(height: 4),
                    Text(feature.subtitle, style: GuoXueTypography.caption),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 状态说明
            ClassicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_statusIcon(feature.status),
                          color: _statusColor(feature.status), size: 22),
                      const SizedBox(width: 8),
                      Text(_statusTitle(feature.status),
                          style: GuoXueTypography.h3),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: GuoXueColors.gold),
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage(feature),
                    style: GuoXueTypography.body,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 功能信息卡
            ClassicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('功能信息', style: GuoXueTypography.h3),
                  const SizedBox(height: 12),
                  _infoRow('分类', _categoryName(feature.categoryId)),
                  const SizedBox(height: 6),
                  _infoRow('类型', feature.ritualType),
                  const SizedBox(height: 6),
                  _infoRow('引擎', feature.engineType),
                  const SizedBox(height: 6),
                  _infoRow('复杂度', feature.complexity),
                  if (feature.requiresBirthInfo) ...[
                    const SizedBox(height: 6),
                    _infoRow('需要', '出生日期信息'),
                  ],
                  if (feature.supportsAI) ...[
                    const SizedBox(height: 6),
                    _infoRow('AI解读', '支持'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 免责声明
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GuoXueColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '国学万宝匣 — 所有功能结果仅供传统文化研究和娱乐参考，\n不作为医疗、法律、投资、婚姻等重大决策依据。',
                style: GuoXueTypography.caption.copyWith(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconWidget(String iconName) {
    return Icon(_resolveIcon(iconName),
        size: 64, color: GuoXueColors.primary);
  }

  IconData _resolveIcon(String name) {
    // 映射 Material Icons 名称到实际 IconData
    // 实际项目中建议用 switch 或 icon 常量映射表
    return _kIconMap[name] ?? Icons.auto_awesome;
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text('$label：', style: GuoXueTypography.caption),
        ),
        Expanded(child: Text(value, style: GuoXueTypography.body)),
      ],
    );
  }

  String _categoryName(String catId) {
    const map = {
      'divination': '占卜类',
      'destiny': '命理类',
      'physiognomy': '相术类',
      'fengshui': '风水类',
      'date_selection': '择吉类',
      'naming': '姓名类',
      'misc_divination': '杂占类',
      'almanac': '通书工具类',
    };
    return map[catId] ?? catId;
  }

  String _statusTitle(String status) {
    return switch (status) {
      'stable' => '已上线 · 功能稳定',
      'beta' => 'Beta 测试中',
      'planned' => '规划中 · 敬请期待',
      _ => '未知状态',
    };
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'stable' => Icons.check_circle,
      'beta' => Icons.science,
      'planned' => Icons.pending,
      _ => Icons.help_outline,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'stable' => GuoXueColors.success,
      'beta' => GuoXueColors.warning,
      'planned' => GuoXueColors.inkLight,
      _ => GuoXueColors.inkGray,
    };
  }

  String _statusMessage(FeatureConfig f) {
    if (f.isStable) {
      return '此功能已完成开发和测试，可正常使用。\n\n包含完整的本地引擎计算与 AI 深度解读。';
    }
    if (f.isBeta) {
      return '此功能的核心引擎已实现，正在进行优化和测试。\n\n当前版本可以正常使用，但解读内容可能会持续完善。\n\n欢迎体验并提出反馈！';
    }
    if (f.engineType == 'ai_assisted') {
      return '此功能规划采用 AI 辅助解析模式。\n\n无需实现复杂的专业算法，通过 AI 对用户输入进行智能分析给出结果。\n\n此类功能开发成本低，将优先排期上线。';
    }
    if (f.engineType == 'placeholder') {
      return '此功能涉及非常复杂的传统术数算法，需要大量专业数据和长时间研发。\n\n短期内将以 AI 辅助简化版替代，逐渐迭代完善。\n\n敬请期待！';
    }
    return '此功能正在规划中，敬请期待。';
  }
}

/// 简化 Icon 名称映射表（只收录本 app 使用的 icon）
const _kIconMap = <String, IconData>{
  'casino': Icons.casino,
  'auto_awesome': Icons.auto_awesome,
  'face': Icons.face,
  'compass_calibration': Icons.compass_calibration,
  'event_available': Icons.event_available,
  'drive_file_rename_outline': Icons.drive_file_rename_outline,
  'psychology': Icons.psychology,
  'menu_book': Icons.menu_book,
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
};

extension FeatureConfigExt on FeatureConfig {
  bool get supportsAI => promptTemplateId != null;
}

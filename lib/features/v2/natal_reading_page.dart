import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import 'feature_catalog_v2.dart';
import 'natal_profile_models.dart';
import 'v2_page_scaffold.dart';

class NatalReadingPage extends StatefulWidget {
  const NatalReadingPage({super.key});

  @override
  State<NatalReadingPage> createState() => _NatalReadingPageState();
}

class _NatalReadingPageState extends State<NatalReadingPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _birthDateController = TextEditingController(text: '1990-01-01');
  final _birthTimeController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _lunarBirthDateController = TextEditingController();
  final _notesController = TextEditingController();

  BirthRelationship _relationship = BirthRelationship.other;
  BirthGender _gender = BirthGender.undisclosed;
  BirthTimeAccuracy _timeAccuracy = BirthTimeAccuracy.unknown;

  @override
  void dispose() {
    _displayNameController.dispose();
    _birthDateController.dispose();
    _birthTimeController.dispose();
    _birthPlaceController.dispose();
    _lunarBirthDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return V2PageScaffold(
      title: '八字命理',
      subtitle: '先了解结果结构，再填写生辰信息生成八字命理结果。',
      icon: Icons.account_circle_outlined,
      showAppBar: true,
      children: [
        const _BaziResultGuide(),
        const SizedBox(height: 12),
        const V2SectionTitle(title: '填写生辰信息'),
        _buildForm(context),
        const SizedBox(height: 12),
        const V2SectionTitle(title: '档案复看'),
        _ReadingModeCard(
          key: const Key('temporary_inference_entry'),
          title: FeatureCatalogV2.natalReadingModes[0].title,
          subtitle: FeatureCatalogV2.natalReadingModes[0].subtitle,
          icon: FeatureCatalogV2.natalReadingModes[0].icon,
          badge: '当前',
          selected: true,
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _ReadingModeCard(
          key: const Key('choose_birth_profile_entry'),
          title: FeatureCatalogV2.natalReadingModes[1].title,
          subtitle: FeatureCatalogV2.natalReadingModes[1].subtitle,
          icon: FeatureCatalogV2.natalReadingModes[1].icon,
          badge: '已保存档案',
          onTap: () => context.push('/natal/profiles'),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.18)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('natal_display_name'),
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: '称呼（可选）',
                hintText: '例如：本人、母亲、客户 A',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<BirthRelationship>(
              key: const Key('natal_relationship'),
              value: _relationship,
              decoration: const InputDecoration(labelText: '关系（可选）'),
              items: [
                for (final value in BirthRelationship.values)
                  DropdownMenuItem(value: value, child: Text(value.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _relationship = value);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<BirthGender>(
              key: const Key('natal_gender'),
              value: _gender,
              decoration: const InputDecoration(labelText: '性别'),
              items: [
                for (final value in BirthGender.values)
                  DropdownMenuItem(value: value, child: Text(value.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _gender = value);
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('natal_birth_date'),
              controller: _birthDateController,
              decoration: const InputDecoration(
                labelText: '公历出生日期',
                hintText: 'YYYY-MM-DD',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (!_isValidDate(text)) return '请输入有效日期，例如 1990-01-01';
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('natal_birth_time'),
              controller: _birthTimeController,
              decoration: const InputDecoration(
                labelText: '出生时间（可选）',
                hintText: 'HH:mm',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                if (!_isValidTime(text)) return '请输入有效时间，例如 08:30';
                return null;
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<BirthTimeAccuracy>(
              key: const Key('natal_time_accuracy'),
              value: _timeAccuracy,
              decoration: const InputDecoration(labelText: '出生时间准确度'),
              items: [
                for (final value in BirthTimeAccuracy.values)
                  DropdownMenuItem(value: value, child: Text(value.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _timeAccuracy = value);
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('natal_birth_place'),
              controller: _birthPlaceController,
              decoration: const InputDecoration(
                labelText: '出生地（可选）',
                hintText: '例如：杭州',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('natal_lunar_birth_date'),
              controller: _lunarBirthDateController,
              decoration: const InputDecoration(
                labelText: '农历生日文本（可选）',
                hintText: '例如：庚午年五月廿六',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('natal_notes'),
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '仅用于本次流程备注',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('natal_submit'),
              onPressed: () => _submit(context),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('生成八字命理结果'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final profile = BirthProfile.create(
      displayName: _displayNameController.text,
      relationship: _relationship,
      gender: _gender,
      gregorianBirthDateTime: _parseBirthDateTime(
        _birthDateController.text,
        _birthTimeController.text,
      ),
      birthTimeAccuracy: _timeAccuracy,
      birthPlaceName: _birthPlaceController.text,
      lunarBirthDateText: _lunarBirthDateController.text,
      notes: _notesController.text,
    );

    context.push('/natal/reading/result', extra: profile);
  }

  bool _isValidDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return false;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return false;
    if (year < 1900 || year > 2100) return false;
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day;
  }

  bool _isValidTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return false;
    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  DateTime _parseBirthDateTime(String dateText, String timeText) {
    final dateParts = dateText.trim().split('-').map(int.parse).toList();
    var hour = 0;
    var minute = 0;
    final cleanTime = timeText.trim();
    if (cleanTime.isNotEmpty) {
      final timeParts = cleanTime.split(':').map(int.parse).toList();
      hour = timeParts[0];
      minute = timeParts[1];
    }
    return DateTime(dateParts[0], dateParts[1], dateParts[2], hour, minute);
  }
}

class _ReadingModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final bool selected;
  final VoidCallback? onTap;

  const _ReadingModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? GuoXueColors.primary : GuoXueColors.gold.withOpacity(0.18);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GuoXueColors.ricePaper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: GuoXueColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: GuoXueColors.primary, size: 21),
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
                          title,
                          style: GuoXueTypography.body.copyWith(
                            color: GuoXueColors.inkBlack,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      _ModeBadge(label: badge),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GuoXueTypography.caption.copyWith(
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
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final String label;

  const _ModeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: GuoXueColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GuoXueTypography.caption.copyWith(
          color: GuoXueColors.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _BaziResultGuide extends StatelessWidget {
  const _BaziResultGuide();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.fact_check_outlined,
            color: GuoXueColors.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '推演结果说明',
                  style: GuoXueTypography.body.copyWith(
                    color: GuoXueColors.inkBlack,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '完成生辰填写后，可查看本命总览、八字四柱、流年运势、月度运势，并可生成 AI 详解。AI 详解可选填写关注方向；不填写则默认生成整体命盘详解。结果基于北京时间排盘，当前不启用真太阳时或出生地经度修正。',
                  style: GuoXueTypography.caption.copyWith(
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

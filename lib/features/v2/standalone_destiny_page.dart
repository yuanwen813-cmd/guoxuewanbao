import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../../domain/calendar/ganzhi.dart';
import 'destiny_ai_explanation_card.dart';
import 'natal_inference_engine.dart';
import 'natal_profile_models.dart';
import 'natal_profile_store.dart';
import 'v2_page_scaffold.dart';

enum StandaloneDestinyType {
  tieban(
    title: '铁板神数',
    subtitle: '输入出生资料，生成数序候选、核时要点与 AI 详解。',
    icon: Icons.functions,
  ),
  ziwei(
    title: '紫微斗数',
    subtitle: '输入出生资料，生成十二宫结构、命宫身宫与 AI 详解。',
    icon: Icons.stars_outlined,
  );

  final String title;
  final String subtitle;
  final IconData icon;

  const StandaloneDestinyType({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

enum _DestinyProfileSource {
  temporary,
  saved,
}

class StandaloneDestinyPage extends ConsumerStatefulWidget {
  final StandaloneDestinyType type;

  const StandaloneDestinyPage({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<StandaloneDestinyPage> createState() =>
      _StandaloneDestinyPageState();
}

class _StandaloneDestinyPageState extends ConsumerState<StandaloneDestinyPage> {
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
  _DestinyProfileSource _profileSource = _DestinyProfileSource.temporary;
  BirthProfile? _profile;

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
    final savedProfiles = ref.watch(birthProfileStoreProvider);
    return V2PageScaffold(
      title: widget.type.title,
      subtitle: widget.type.subtitle,
      icon: widget.type.icon,
      showAppBar: true,
      children: [
        const V2SectionTitle(title: '资料来源'),
        _buildProfileSourceSelector(),
        const SizedBox(height: 12),
        if (_profileSource == _DestinyProfileSource.temporary) ...[
          const V2SectionTitle(title: '填写生辰信息'),
          _buildForm(),
        ] else ...[
          const V2SectionTitle(title: '从命盘档案选择'),
          _buildSavedProfilePicker(savedProfiles),
        ],
        if (_profile != null) ...[
          const SizedBox(height: 12),
          _buildResult(_profile!),
        ],
      ],
    );
  }

  Widget _buildProfileSourceSelector() {
    return Column(
      children: [
        _ProfileSourceCard(
          key: Key('${widget.type.name}_temporary_source'),
          title: '临时填写出生资料',
          subtitle: '直接输入生辰信息，生成本次${widget.type.title}结果。',
          icon: Icons.edit_note_outlined,
          selected: _profileSource == _DestinyProfileSource.temporary,
          onTap: () => _switchProfileSource(_DestinyProfileSource.temporary),
        ),
        const SizedBox(height: 10),
        _ProfileSourceCard(
          key: Key('${widget.type.name}_saved_source'),
          title: '从命盘档案选择',
          subtitle: '复用已保存的出生资料，直接生成${widget.type.title}结果。',
          icon: Icons.badge_outlined,
          selected: _profileSource == _DestinyProfileSource.saved,
          onTap: () => _switchProfileSource(_DestinyProfileSource.saved),
        ),
      ],
    );
  }

  Widget _buildSavedProfilePicker(List<BirthProfile> profiles) {
    if (profiles.isEmpty) {
      return _CardBlock(
        title: '暂无命盘档案',
        child: Text(
          '可以先在本页临时填写出生资料，或在八字命理结果页保存为命盘档案后再来选择。',
          style: GuoXueTypography.caption.copyWith(
            color: GuoXueColors.inkGray,
            height: 1.45,
            letterSpacing: 0,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final profile in profiles)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SavedProfileChoiceCard(
              key: Key('${widget.type.name}_saved_profile_${profile.id}'),
              profile: profile,
              selected: _profile?.id == profile.id,
              onTap: () => setState(() => _profile = profile),
            ),
          ),
      ],
    );
  }

  void _switchProfileSource(_DestinyProfileSource source) {
    if (_profileSource == source) return;
    setState(() {
      _profileSource = source;
      _profile = null;
    });
  }

  Widget _buildForm() {
    return _CardBlock(
      title: '出生资料',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: Key('${widget.type.name}_display_name'),
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: '称呼（可选）',
                hintText: '例如：本人、母亲、客户 A',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<BirthRelationship>(
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
              key: Key('${widget.type.name}_birth_date'),
              controller: _birthDateController,
              decoration: const InputDecoration(
                labelText: '出生日期',
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
              key: Key('${widget.type.name}_birth_time'),
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
              controller: _birthPlaceController,
              decoration: const InputDecoration(
                labelText: '出生地（可选）',
                hintText: '例如：杭州',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _lunarBirthDateController,
              decoration: const InputDecoration(
                labelText: '农历生日文本（可选）',
                hintText: '例如：庚午年五月廿六',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: '备注（可选）'),
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: Key('${widget.type.name}_submit'),
              onPressed: _submit,
              icon: Icon(widget.type.icon),
              label: Text('生成${widget.type.title}结果'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(BirthProfile profile) {
    return switch (widget.type) {
      StandaloneDestinyType.tieban => _TiebanStandaloneResult(profile: profile),
      StandaloneDestinyType.ziwei => _ZiweiStandaloneResult(profile: profile),
    };
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _profile = BirthProfile.create(
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
    });
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

class _TiebanStandaloneResult extends StatelessWidget {
  final BirthProfile profile;

  const _TiebanStandaloneResult({required this.profile});

  @override
  Widget build(BuildContext context) {
    final report = const NatalInferenceEngine().generate(profile);
    final reference = report.tiebanReference;
    final contextText = [
      '出生资料：${profile.displayName}，${profile.relationship.label}，${profile.gender.label}，${profile.birthDateText}',
      '四柱：${report.pillarSummary}',
      '生肖：${report.zodiac}',
      '铁板出生数：${reference.birthCode}',
      '时辰码：${reference.timeCode}',
      '候选数序：${reference.sequenceCandidates.join('、')}',
      '说明：${reference.summary}',
      '核验提示：${reference.calibrationPrompt}',
    ].join('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileSummaryBlock(profile: profile),
        const SizedBox(height: 10),
        _CardBlock(
          title: '铁板神数结果',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(label: '出生数', value: reference.birthCode),
              _SummaryRow(label: '时辰码', value: reference.timeCode),
              _SummaryRow(
                label: '候选数序',
                value: reference.sequenceCandidates.join('、'),
              ),
              _SummaryRow(label: '四柱', value: report.pillarSummary),
              _SummaryRow(label: '说明', value: reference.summary),
              _SummaryRow(label: '核验提示', value: reference.calibrationPrompt),
            ],
          ),
        ),
        const SizedBox(height: 10),
        DestinyAiExplanationCard(
          title: 'AI 详解',
          description: '可选填写想重点了解的方向；不填写则生成整体命盘详解。',
          systemPrompt:
              '你是国学万宝匣的铁板神数解释助手。请基于出生资料、四柱结构、数序候选和核时提示进行中文解释，表达要清楚、有边界。',
          contextText: contextText,
          inputKeyName: 'tieban_ai_focus',
          buttonKeyName: 'tieban_ai_explain_button',
        ),
      ],
    );
  }
}

class _ZiweiStandaloneResult extends StatelessWidget {
  final BirthProfile profile;

  const _ZiweiStandaloneResult({required this.profile});

  @override
  Widget build(BuildContext context) {
    final chart = _ZiweiLocalEngine().generate(profile);
    final contextText = chart.toContextText(profile);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileSummaryBlock(profile: profile),
        const SizedBox(height: 10),
        _CardBlock(
          title: '紫微斗数命盘',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(label: '命宫', value: chart.lifePalace),
              _SummaryRow(label: '身宫', value: chart.bodyPalace),
              _SummaryRow(label: '命主', value: chart.lifeMaster),
              _SummaryRow(label: '身主', value: chart.bodyMaster),
              _SummaryRow(label: '四化参考', value: chart.transformations),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _CardBlock(
          title: '十二宫结构',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final palace in chart.palaces)
                _SummaryRow(label: palace.name, value: palace.summary),
            ],
          ),
        ),
        const SizedBox(height: 10),
        DestinyAiExplanationCard(
          title: 'AI 详解',
          description: '可选填写想重点了解的方向；不填写则生成整体命盘详解。',
          systemPrompt:
              '你是国学万宝匣的紫微斗数解释助手。请基于出生资料、命宫身宫、十二宫和主星结构进行中文解释，表达要清楚、有边界。',
          contextText: contextText,
          inputKeyName: 'ziwei_ai_focus',
          buttonKeyName: 'ziwei_ai_explain_button',
        ),
      ],
    );
  }
}

class _ZiweiLocalEngine {
  static const palaceNames = [
    '命宫',
    '兄弟',
    '夫妻',
    '子女',
    '财帛',
    '疾厄',
    '迁移',
    '交友',
    '官禄',
    '田宅',
    '福德',
    '父母',
  ];

  static const branches = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥'
  ];
  static const stars = [
    '紫微',
    '天机',
    '太阳',
    '武曲',
    '天同',
    '廉贞',
    '天府',
    '太阴',
    '贪狼',
    '巨门',
    '天相',
    '天梁'
  ];

  _ZiweiChart generate(BirthProfile profile) {
    final date = profile.gregorianBirthDateTime;
    final hourBranch = profile.birthTimeAccuracy == BirthTimeAccuracy.unknown
        ? DiZhi.zi
        : DiZhi.fromHour(date.hour);
    final lunarMonth =
        _parseLunarMonth(profile.lunarBirthDateText) ?? date.month;
    final lifeIndex = (lunarMonth + hourBranch.order) % 12;
    final bodyIndex = (lunarMonth + 12 - hourBranch.order) % 12;
    final starOffset = (date.year + date.month + date.day) % stars.length;
    final palaces = [
      for (var i = 0; i < 12; i += 1)
        _ZiweiPalace(
          name: '${palaceNames[i]}（${branches[(lifeIndex + i) % 12]}）',
          summary:
              '${stars[(starOffset + i) % stars.length]}坐守，辅以${stars[(starOffset + i + 4) % stars.length]}观察。',
        ),
    ];

    return _ZiweiChart(
      lifePalace: palaces[0].name,
      bodyPalace: palaces[(bodyIndex - lifeIndex) % 12].name,
      lifeMaster: stars[starOffset],
      bodyMaster: stars[(starOffset + hourBranch.order) % stars.length],
      transformations: _transformationsByYearStem(date.year),
      palaces: palaces,
    );
  }

  int? _parseLunarMonth(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    const map = {
      '正': 1,
      '一': 1,
      '二': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
      '十': 10,
      '冬': 11,
      '腊': 12,
    };
    for (final entry in map.entries) {
      if (text.contains('${entry.key}月')) return entry.value;
    }
    return null;
  }

  String _transformationsByYearStem(int year) {
    final stem = TianGan.fromOrder((year - 4) % 10).chinese;
    return switch (stem) {
      '甲' => '廉贞化禄、破军化权、武曲化科、太阳化忌',
      '乙' => '天机化禄、天梁化权、紫微化科、太阴化忌',
      '丙' => '天同化禄、天机化权、文昌化科、廉贞化忌',
      '丁' => '太阴化禄、天同化权、天机化科、巨门化忌',
      '戊' => '贪狼化禄、太阴化权、右弼化科、天机化忌',
      '己' => '武曲化禄、贪狼化权、天梁化科、文曲化忌',
      '庚' => '太阳化禄、武曲化权、太阴化科、天同化忌',
      '辛' => '巨门化禄、太阳化权、文曲化科、文昌化忌',
      '壬' => '天梁化禄、紫微化权、左辅化科、武曲化忌',
      _ => '破军化禄、巨门化权、太阴化科、贪狼化忌',
    };
  }
}

class _ZiweiChart {
  final String lifePalace;
  final String bodyPalace;
  final String lifeMaster;
  final String bodyMaster;
  final String transformations;
  final List<_ZiweiPalace> palaces;

  const _ZiweiChart({
    required this.lifePalace,
    required this.bodyPalace,
    required this.lifeMaster,
    required this.bodyMaster,
    required this.transformations,
    required this.palaces,
  });

  String toContextText(BirthProfile profile) {
    return [
      '出生资料：${profile.displayName}，${profile.relationship.label}，${profile.gender.label}，${profile.birthDateText}',
      '命宫：$lifePalace',
      '身宫：$bodyPalace',
      '命主：$lifeMaster',
      '身主：$bodyMaster',
      '四化参考：$transformations',
      '十二宫：${palaces.map((p) => '${p.name}:${p.summary}').join('；')}',
    ].join('\n');
  }
}

class _ZiweiPalace {
  final String name;
  final String summary;

  const _ZiweiPalace({
    required this.name,
    required this.summary,
  });
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
          _SummaryRow(label: '时间准确度', value: profile.birthTimeAccuracy.label),
        ],
      ),
    );
  }
}

class _ProfileSourceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileSourceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? GuoXueColors.primary.withOpacity(0.08)
              : GuoXueColors.ricePaper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? GuoXueColors.primary.withOpacity(0.45)
                : GuoXueColors.gold.withOpacity(0.18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: GuoXueColors.primary),
            const SizedBox(width: 10),
            Expanded(
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GuoXueTypography.caption.copyWith(
                      color: GuoXueColors.inkGray,
                      height: 1.35,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: GuoXueColors.primary),
          ],
        ),
      ),
    );
  }
}

class _SavedProfileChoiceCard extends StatelessWidget {
  final BirthProfile profile;
  final bool selected;
  final VoidCallback onTap;

  const _SavedProfileChoiceCard({
    super.key,
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? GuoXueColors.primary.withOpacity(0.08)
              : GuoXueColors.ricePaper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? GuoXueColors.primary.withOpacity(0.45)
                : GuoXueColors.gold.withOpacity(0.18),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.account_circle_outlined,
                color: GuoXueColors.primary),
            const SizedBox(width: 10),
            Expanded(
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
                  const SizedBox(height: 2),
                  Text(
                    '${profile.relationship.label} · ${profile.gender.label} · ${profile.birthDateText}',
                    style: GuoXueTypography.caption.copyWith(
                      color: GuoXueColors.inkGray,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle, color: GuoXueColors.primary),
              ),
          ],
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

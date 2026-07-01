import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import 'natal_profile_models.dart';
import 'natal_profile_store.dart';
import 'v2_page_scaffold.dart';

class NatalProfilesPage extends ConsumerWidget {
  const NatalProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(birthProfileStoreProvider);
    return V2PageScaffold(
      title: '命盘档案',
      subtitle: '查看和管理已保存的出生资料档案。档案可用于自己、家人、朋友或客户。',
      icon: Icons.badge_outlined,
      showAppBar: true,
      children: [
        if (profiles.isEmpty)
          const _EmptyProfiles()
        else
          for (final profile in profiles)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProfileCard(profile: profile),
            ),
      ],
    );
  }
}

class _EmptyProfiles extends StatelessWidget {
  const _EmptyProfiles();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          const Icon(Icons.folder_open_outlined, color: GuoXueColors.inkLight),
          const SizedBox(height: 8),
          Text(
            '暂无命盘档案',
            style: GuoXueTypography.body.copyWith(
              color: GuoXueColors.inkBlack,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '完成一次临时推演后，可手动保存为命盘档案。',
            style: GuoXueTypography.caption.copyWith(
              color: GuoXueColors.inkGray,
              letterSpacing: 0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  final BirthProfile profile;

  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                      '${profile.relationship.label} · ${profile.birthDateText}',
                      style: GuoXueTypography.caption.copyWith(
                        color: GuoXueColors.inkGray,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('open_profile_result'),
                  onPressed: () =>
                      context.push('/natal/reading/result', extra: profile),
                  child: const Text('进入推演结果'),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                key: const Key('delete_birth_profile'),
                onPressed: () => _confirmDelete(context, ref),
                child: const Text('删除'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除命盘档案'),
        content: Text('确定删除“${profile.displayName}”吗？删除后不会影响历史问事、黄历或周易本经记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            key: const Key('confirm_delete_birth_profile'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(birthProfileStoreProvider.notifier).delete(profile.id);
    }
  }
}

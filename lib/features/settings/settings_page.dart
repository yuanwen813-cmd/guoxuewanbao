import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_typography.dart';
import '../../infrastructure/history_service/history_service.dart';
import '../../shared/widgets/classical_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClassicalCard(
            child: Column(
              children: [
                _SettingsItem(
                  icon: Icons.cloud_sync_outlined,
                  title: '我的数据',
                  subtitle: '查看云同步说明，导出数据或注销账号',
                  onTap: () => context.push('/settings/account-data'),
                ),
                const Divider(),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  title: '隐私声明',
                  subtitle: '了解我们如何保护你的资料和记录',
                  onTap: () => context.push('/settings/privacy'),
                ),
                const Divider(),
                _SettingsItem(
                  icon: Icons.warning_amber_outlined,
                  title: '免责声明',
                  subtitle: '使用须知与免责声明',
                  onTap: () => context.push('/settings/disclaimer'),
                ),
                const Divider(),
                _SettingsItem(
                  icon: Icons.delete_outline,
                  title: '清除历史记录',
                  subtitle: '删除历史记录，不影响钱包、报告和命盘档案',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('确认清除'),
                        content: const Text(
                          '将删除当前账户的历史记录及本机副本。钱包余额、充值订单、已生成 AI 报告和命盘档案不受影响，此操作不可撤销。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              final cloudSynced = await ref
                                  .read(historyServiceProvider)
                                  .clearAllHistory();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    cloudSynced
                                        ? '历史记录已清除'
                                        : '本机记录已清除，云端将在网络恢复后同步删除',
                                  ),
                                ),
                              );
                            },
                            child: const Text('确认删除'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '国学万宝匣 v1.0.0',
            textAlign: TextAlign.center,
            style: GuoXueTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

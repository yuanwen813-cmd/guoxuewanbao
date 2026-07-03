import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_typography.dart';
import '../../shared/widgets/classical_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClassicalCard(
            child: Column(
              children: [
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
                  title: '清除数据',
                  subtitle: '清除本设备上的历史记录和缓存',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('确认清除'),
                        content: const Text(
                          '将清除本设备上的历史记录和缓存数据，此操作不可撤销。',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('数据已清除')),
                              );
                            },
                            child: const Text('确认清除'),
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

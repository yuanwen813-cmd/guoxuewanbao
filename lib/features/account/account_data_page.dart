import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../infrastructure/history_service/history_service.dart';
import '../auth/auth_store.dart';
import '../v2/natal_profile_store.dart';
import '../wallet/wallet_store.dart';
import 'user_data_api.dart';

class AccountDataPage extends ConsumerStatefulWidget {
  const AccountDataPage({super.key});

  @override
  ConsumerState<AccountDataPage> createState() => _AccountDataPageState();
}

class _AccountDataPageState extends ConsumerState<AccountDataPage> {
  final _api = UserDataApi();
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStoreProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的数据')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '登录后的历史记录和命盘档案会在本机与云端之间同步。断网时仍可查看本机数据，恢复网络后会继续同步。',
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('导出个人数据'),
            subtitle: const Text('导出账号、钱包流水、订单、AI 报告、历史记录和命盘档案'),
            trailing: const Icon(Icons.chevron_right),
            enabled: auth.isAuthenticated && !_working,
            onTap: _exportData,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_off_outlined),
            title: const Text('注销账号'),
            subtitle: const Text('清除个人资料与内容；财务流水依法保留但会去标识化'),
            trailing: const Icon(Icons.chevron_right),
            enabled: auth.isAuthenticated && !_working,
            onTap: _confirmDelete,
          ),
          if (!auth.isAuthenticated) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/login'),
              child: const Text('登录后管理个人数据'),
            ),
          ],
          if (_working) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    final token = ref.read(authStoreProvider).token;
    if (token == null || token.isEmpty) return;
    setState(() => _working = true);
    try {
      final data = await _api.exportAccount(token);
      final text = const JsonEncoder.withIndent('  ').convert(data);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '个人数据已生成',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('请选择复制或系统分享。导出内容含个人资料，请妥善保管。'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('复制导出内容'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Share.share(
                    text,
                    subject: '国学万宝匣个人数据导出',
                  ),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('系统分享'),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(userDataApiMessage(error, '个人数据导出失败'));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _confirmDelete() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认注销账号'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '注销前钱包余额必须为 0，且不能有待支付订单。注销后个人资料和内容不可恢复。请输入“确认注销”。',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '确认文字',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              controller.text.trim() == '确认注销',
            ),
            child: const Text('注销账号'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (confirmed != true) return;

    final token = ref.read(authStoreProvider).token;
    if (token == null || token.isEmpty) return;
    setState(() => _working = true);
    try {
      await _api.deleteAccount(token, '确认注销');
      await ref.read(historyServiceProvider).clearLocalData();
      await ref.read(birthProfileStoreProvider.notifier).clearLocalData();
      await ref.read(authStoreProvider.notifier).logout();
      await ref.read(walletStoreProvider.notifier).clearLocalSession();
      if (!mounted) return;
      context.go('/');
      _showMessage('账号已注销');
    } catch (error) {
      if (!mounted) return;
      _showMessage(userDataApiMessage(error, '账号注销失败'));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

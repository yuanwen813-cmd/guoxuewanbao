import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_store.dart';
import '../wallet/server_wallet_api.dart';

class MyReportsPage extends ConsumerStatefulWidget {
  const MyReportsPage({super.key});

  @override
  ConsumerState<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends ConsumerState<MyReportsPage> {
  late final ServerWalletApi _api = ServerWalletApi(
    tokenProvider: () async => ref.read(authStoreProvider).token,
  );
  Timer? _poll;
  List<ServerAiReport> _reports = const [];
  bool _loading = true;
  String? _error;
  String? _visibleUserId;

  @override
  void initState() {
    super.initState();
    _visibleUserId = ref.read(authStoreProvider).user?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_reports.any((report) => report.status == 'generating')) {
        _load(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final auth = ref.read(authStoreProvider);
    if (!mounted || !auth.isAuthenticated) return;
    final userId = auth.user!.id;
    if (!silent) setState(() => _loading = true);
    try {
      final reports = await _api.fetchAiReports();
      if (!mounted || ref.read(authStoreProvider).user?.id != userId) return;
      setState(() {
        _reports = reports;
        _error = null;
      });
    } catch (_) {
      if (mounted && ref.read(authStoreProvider).user?.id == userId) {
        setState(() => _error = '报告读取失败，请下拉刷新。');
      }
    } finally {
      if (mounted && ref.read(authStoreProvider).user?.id == userId) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _open(ServerAiReport summary) async {
    final userId = ref.read(authStoreProvider).user?.id;
    try {
      final report = await _api.fetchAiReportDetail(summary.id);
      if (!mounted || ref.read(authStoreProvider).user?.id != userId) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.85,
            child: Column(
              children: [
                ListTile(
                  title: Text(_title(report.productId)),
                  trailing: IconButton(
                    tooltip: '关闭',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (report.status == 'completed' &&
                          report.resultText?.trim().isNotEmpty == true)
                        SelectableText(report.resultText!)
                      else if (report.status == 'generating')
                        const Text('报告正在生成。完成后会保存在这里，请稍后刷新。')
                      else
                        Text(report.status == 'refunded'
                            ? '本次解析未完成，¥5 已自动退回钱包。'
                            : '报告未生成，请稍后重试。'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('报告详情读取失败，请稍后重试。')),
        );
      }
    }
  }

  String _title(String productId) {
    if (productId.startsWith('bazi')) return '八字命理 AI 解析';
    if (productId.startsWith('ziwei')) return '紫微斗数 AI 解析';
    if (productId.startsWith('tieban')) return '铁板神数 AI 解析';
    return 'AI 解析报告';
  }

  String _status(String status) => switch (status) {
        'completed' => '已完成',
        'generating' => '生成中',
        'refunded' => '已退款',
        _ => '未完成',
      };

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStoreProvider, (_, next) {
      if (_visibleUserId == next.user?.id) return;
      setState(() {
        _visibleUserId = next.user?.id;
        _reports = const [];
        _error = null;
        _loading = next.isAuthenticated;
      });
      if (next.isAuthenticated) unawaited(_load());
    });
    final auth = ref.watch(authStoreProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的报告'),
        leading: IconButton(
          tooltip: '返回',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(),
          ),
        ],
      ),
      body: !auth.isAuthenticated
          ? Center(
              child: FilledButton(
                onPressed: () => context.push('/login'),
                child: const Text('登录后查看报告'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_loading) const LinearProgressIndicator(),
                  if (_error != null) Text(_error!),
                  if (!_loading && _reports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: Text('还没有 AI 解析报告')),
                    ),
                  for (final report in auth.user?.id == _visibleUserId
                      ? _reports : const <ServerAiReport>[])
                    Card(
                      child: ListTile(
                        title: Text(_title(report.productId)),
                        subtitle: Text(
                          '${_status(report.status)} · '
                          '${report.createdAt?.toLocal().toString().substring(0, 16) ?? ''}',
                        ),
                        trailing: report.status == 'generating'
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () => _open(report),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

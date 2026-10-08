import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_store.dart';
import '../wallet/server_wallet_api.dart';
import '../wallet/wallet_store.dart';
import 'ai_report_content.dart';

class AiReportDetailSheet extends ConsumerStatefulWidget {
  final ServerWalletApi api;
  final ServerAiReport report;
  final String title;
  final String ownerId;

  const AiReportDetailSheet(
      {super.key,
      required this.api,
      required this.report,
      required this.title,
      required this.ownerId});

  @override
  ConsumerState<AiReportDetailSheet> createState() =>
      _AiReportDetailSheetState();
}

class _AiReportDetailSheetState extends ConsumerState<AiReportDetailSheet> {
  late ServerAiReport _report = widget.report;
  Timer? _poll;
  bool _refreshing = false;
  bool _refreshFailed = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_report.status == 'generating') unawaited(_refresh());
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_refreshing || ref.read(authStoreProvider).user?.id != widget.ownerId)
      return;
    setState(() => _refreshing = true);
    try {
      final report = await widget.api.fetchAiReportDetail(_report.id);
      if (!mounted || ref.read(authStoreProvider).user?.id != widget.ownerId)
        return;
      setState(() {
        _report = report;
        _refreshFailed = false;
      });
      if (report.status == 'refunded') {
        await ref.read(walletStoreProvider.notifier).syncFromServer();
      }
    } catch (_) {
      if (mounted) setState(() => _refreshFailed = true);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _report.resultText ?? ''));
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('报告已复制')));
  }

  @override
  Widget build(BuildContext context) {
    final ownsReport = ref.watch(authStoreProvider).user?.id == widget.ownerId;
    final completed = _report.status == 'completed' &&
        _report.resultText?.trim().isNotEmpty == true;
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(children: [
          ListTile(
            title: Text(ownsReport ? widget.title : '请重新登录后查看报告'),
            subtitle: ownsReport && _report.createdAt != null
                ? Text(_report.createdAt!.toLocal().toString().substring(0, 16))
                : null,
            trailing: IconButton(
                tooltip: '关闭',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop()),
          ),
          const Divider(height: 1),
          Expanded(
              child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (ownsReport && completed)
                AiReportContent(text: _report.resultText!)
              else if (ownsReport && _report.status == 'generating') ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
                const Text('报告正在生成，完成后会自动显示。你可以离开页面，稍后到“我的报告”查看。'),
              ] else if (ownsReport)
                Text(_report.status == 'refunded'
                    ? '本次解析未完成，${formatPointsCenti(_report.priceCents)}已自动退回。'
                    : '报告未生成，请稍后重试。'),
              if (ownsReport && _refreshFailed) ...[
                const SizedBox(height: 16),
                const Text('暂时无法刷新，任务不会因此重复扣费。'),
              ],
            ],
          )),
          if (ownsReport)
            Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  if (completed)
                    TextButton.icon(
                        onPressed: _copy,
                        icon: const Icon(Icons.copy),
                        label: const Text('复制报告')),
                  const Spacer(),
                  if (!completed)
                    TextButton.icon(
                        onPressed: _refreshing ? null : _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('刷新状态')),
                ])),
        ]),
      ),
    );
  }
}

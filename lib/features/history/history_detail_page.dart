import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/common/common_result_models.dart';
import '../../domain/history/divination_history.dart';
import '../../features/result_common/common_divination_result_page.dart';
import '../../infrastructure/history_service/history_service.dart';

/// 历史详情页 —— 从保存的快照恢复通用结果页，不重新起卦，不重新请求 AI
class HistoryDetailPage extends ConsumerWidget {
  final String recordId;

  const HistoryDetailPage({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyService = ref.watch(historyServiceProvider);
    final record = historyService.getById(recordId);

    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('历史详情')),
        body: const Center(child: Text('记录不存在或已被删除')),
      );
    }

    // 从 resultJson 快照恢复，不重新请求 AI
    final result = CommonDivinationResult.fromJson(record.resultSnapshot);

    return CommonDivinationResultPage(
      result: result,
      onShare: () {
        final text = CommonDivinationResultPage.buildShareText(result);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('分享结果'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: SingleChildScrollView(
                child:
                    SelectableText(text, style: const TextStyle(fontSize: 13)),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('分享内容已复制')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('复制'),
              ),
              TextButton.icon(
                onPressed: () => Share.share(text),
                icon: const Icon(Icons.ios_share_outlined),
                label: const Text('系统分享'),
              ),
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
            ],
          ),
        );
      },
      showDebugButton: false, // 历史详情不显示 Debug
    );
  }
}

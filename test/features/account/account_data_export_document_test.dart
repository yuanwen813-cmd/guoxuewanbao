import 'package:flutter_test/flutter_test.dart';
import 'package:guoxueapp/features/account/account_data_export_document.dart';

void main() {
  test('builds a readable and escaped account data HTML export', () {
    final data = <String, dynamic>{
      'exportedAt': '2026-08-28T12:30:00+08:00',
      'account': {
        'phone': '13800000000',
        'nickname': '<测试用户>',
        'status': 'active',
      },
      'wallet': {'balance_cents': 390, 'currency': 'CNY'},
      'walletTransactions': [
        {
          'type': 'ai_refund',
          'amount_cents': 390,
          'created_at': '2026-08-28T12:30:00+08:00',
        },
      ],
      'rechargeOrders': const [],
      'aiReports': [
        {
          'report_type': 'question_full',
          'price_cents': 390,
          'status': 'completed',
          'result_text': '这是 AI 报告内容。',
        },
      ],
      'histories': const [],
      'birthProfiles': const [],
    };

    final html = AccountDataExportDocument.buildHtml(data);
    final plainText = AccountDataExportDocument.buildPlainText(data);

    expect(html, contains('<html lang="zh-CN">'));
    expect(html, contains('国学万宝匣个人数据导出'));
    expect(html, contains('当前余额'));
    expect(html, contains('¥3.90'));
    expect(html, contains('AI 解析退款'));
    expect(html, contains('这是 AI 报告内容。'));
    expect(html, contains('&lt;测试用户&gt;'));
    expect(html, isNot(contains('<测试用户>')));
    expect(plainText, contains('完整数据：'));
    expect(
      AccountDataExportDocument.buildFileName(DateTime(2026, 8, 28, 12, 30)),
      'guoxuewanbao-personal-data-20260828-123000.html',
    );
  });
}

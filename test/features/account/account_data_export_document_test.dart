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
      'wallet': {'balanceCents': 390, 'currency': 'CNY'},
      'walletTransactions': [
        {
          'type': 'ai_refund',
          'amountCents': 390,
          'balanceAfterCents': 780,
          'createdAt': '2026-08-28T12:30:00+08:00',
        },
      ],
      'rechargeOrders': [
        {
          'provider': 'alipay',
          'amountCents': 100,
          'status': 'closed',
          'createdAt': '2026-08-28T12:30:00+08:00',
          'payUrl': 'https://payment.example/private-link',
          'outTradeNo': 'PRIVATE_ORDER_ID',
        },
      ],
      'aiReports': [
        {
          'reportType': 'question_full',
          'priceCents': 390,
          'status': 'completed',
          'resultText': '这是 AI 报告内容。',
          'promptSnapshot': '内部提示词',
          'questionResultJson': {'secret': 'internal'},
        },
      ],
      'histories': const [],
      'birthProfiles': const [],
    };

    final html = AccountDataExportDocument.buildHtml(data);

    expect(html, contains('<html lang="zh-CN">'));
    expect(html, contains('国学万宝匣个人数据导出'));
    expect(html, contains('当前余额'));
    expect(html, contains('¥3.90'));
    expect(html, contains('AI 解析退款'));
    expect(html, contains('这是 AI 报告内容。'));
    expect(html, contains('&lt;测试用户&gt;'));
    expect(html, isNot(contains('<测试用户>')));
    expect(html, isNot(contains('payment.example/private-link')));
    expect(html, isNot(contains('PRIVATE_ORDER_ID')));
    expect(html, isNot(contains('内部提示词')));
    expect(html, isNot(contains('报告数据')));
    expect(html, isNot(contains('完整原始数据')));
    expect(
      AccountDataExportDocument.buildFileName(DateTime(2026, 8, 28, 12, 30)),
      'guoxuewanbao-personal-data-20260828-123000.html',
    );
  });
}

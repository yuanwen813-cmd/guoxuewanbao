import 'dart:convert';

class AccountDataExportDocument {
  static String buildFileName([DateTime? exportedAt]) {
    final time = exportedAt ?? DateTime.now();
    return 'guoxuewanbao-personal-data-'
        '${time.year.toString().padLeft(4, '0')}'
        '${time.month.toString().padLeft(2, '0')}'
        '${time.day.toString().padLeft(2, '0')}-'
        '${time.hour.toString().padLeft(2, '0')}'
        '${time.minute.toString().padLeft(2, '0')}'
        '${time.second.toString().padLeft(2, '0')}.html';
  }

  static String buildHtml(Map<String, dynamic> data, {DateTime? exportedAt}) {
    final exported = exportedAt ??
        DateTime.tryParse(data['exportedAt']?.toString() ?? '') ??
        DateTime.now();
    final account = _map(data['account']);
    final wallet = _map(data['wallet']);
    final transactions = _records(data['walletTransactions']);
    final recharges = _records(data['rechargeOrders']);
    final reports = _records(data['aiReports']);
    final histories = _records(data['histories']);
    final profiles = _records(data['birthProfiles']);

    return '''<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>国学万宝匣个人数据导出</title>
  <style>
    :root { color-scheme: light; }
    * { box-sizing: border-box; }
    body { margin: 0; background: #f7f3ec; color: #24211d; font: 15px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", "Microsoft YaHei", sans-serif; }
    main { max-width: 980px; margin: 0 auto; padding: 34px 20px 56px; }
    header { border-left: 5px solid #a93a2f; padding: 4px 0 4px 16px; margin-bottom: 20px; }
    h1 { margin: 0; font-size: 28px; }
    h2 { margin: 0 0 14px; font-size: 20px; }
    h3 { margin: 0 0 8px; font-size: 16px; }
    .muted { color: #6f685e; }
    .notice { margin: 20px 0; padding: 14px 16px; border: 1px solid #ead6bb; border-radius: 8px; background: #fff9eb; color: #67481a; }
    section { margin-top: 18px; padding: 20px; border: 1px solid #e4ded3; border-radius: 8px; background: #fffdfa; box-shadow: 0 1px 2px rgba(57, 45, 28, .04); }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(210px, 1fr)); gap: 12px; }
    .item { min-width: 0; padding: 11px 12px; border-radius: 6px; background: #f8f4ed; }
    .label { display: block; margin-bottom: 2px; color: #766e63; font-size: 12px; }
    .value { overflow-wrap: anywhere; font-weight: 600; }
    details { margin-top: 10px; overflow: hidden; border: 1px solid #e9e2d7; border-radius: 6px; background: #fff; }
    summary { cursor: pointer; padding: 11px 12px; font-weight: 600; }
    .detail { padding: 0 12px 12px; }
    pre, .report { margin: 0; padding: 12px; overflow-x: auto; border-radius: 5px; background: #f7f5f1; color: #3d3933; font: 12px/1.55 ui-monospace, SFMono-Regular, Consolas, monospace; white-space: pre-wrap; overflow-wrap: anywhere; }
    .report { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Microsoft YaHei", sans-serif; font-size: 14px; }
    .empty { margin: 0; color: #766e63; }
    footer { margin-top: 24px; color: #766e63; font-size: 13px; }
  </style>
</head>
<body>
  <main>
    <header>
      <h1>国学万宝匣个人数据导出</h1>
      <div class="muted">导出时间：${_escape(_dateText(exported))}</div>
    </header>
    <div class="notice">此文件包含个人资料、出生资料、历史记录和消费信息。请仅在可信设备保存，不要随意转发给他人。</div>
    <section>
      <h2>账号与钱包</h2>
      <div class="grid">
        ${_field('手机号', account['phone'])}
        ${_field('昵称', account['nickname'])}
        ${_field('账户状态', account['status'])}
        ${_field('账户创建时间', account['created_at'])}
        ${_field('当前余额', _money(wallet['balance_cents']))}
        ${_field('货币', wallet['currency'] ?? 'CNY')}
      </div>
    </section>
    ${_recordSection('钱包流水', transactions, _walletTransactionTitle)}
    ${_recordSection('充值订单', recharges, _rechargeTitle)}
    ${_aiReportSection(reports)}
    ${_recordSection('历史记录', histories, _historyTitle)}
    ${_recordSection('命盘档案', profiles, _profileTitle)}
    <section>
      <h2>导出摘要</h2>
      <div class="grid">
        ${_field('钱包流水', '${transactions.length} 条')}
        ${_field('充值订单', '${recharges.length} 条')}
        ${_field('AI 报告', '${reports.length} 条')}
        ${_field('历史记录', '${histories.length} 条')}
        ${_field('命盘档案', '${profiles.length} 条')}
      </div>
      <details>
        <summary>查看完整原始数据备份</summary>
        <div class="detail"><pre>${_escape(const JsonEncoder.withIndent('  ').convert(data))}</pre></div>
      </details>
    </section>
    <footer>本文件由国学万宝匣生成，用于用户个人数据查阅与留存。</footer>
  </main>
</body>
</html>''';
  }

  static String buildPlainText(Map<String, dynamic> data,
      {DateTime? exportedAt}) {
    final exported = exportedAt ??
        DateTime.tryParse(data['exportedAt']?.toString() ?? '') ??
        DateTime.now();
    final account = _map(data['account']);
    final wallet = _map(data['wallet']);
    return '''国学万宝匣个人数据导出
导出时间：${_dateText(exported)}

账号：${account['phone'] ?? '未提供'}
昵称：${account['nickname'] ?? '未提供'}
当前余额：${_money(wallet['balance_cents'])}
钱包流水：${_records(data['walletTransactions']).length} 条
充值订单：${_records(data['rechargeOrders']).length} 条
AI 报告：${_records(data['aiReports']).length} 条
历史记录：${_records(data['histories']).length} 条
命盘档案：${_records(data['birthProfiles']).length} 条

完整数据：
${const JsonEncoder.withIndent('  ').convert(data)}''';
  }

  static String _recordSection(
    String title,
    List<Map<String, dynamic>> records,
    String Function(Map<String, dynamic>, int) titleBuilder,
  ) {
    if (records.isEmpty) {
      return '''<section><h2>$title</h2><p class="empty">暂无可导出的记录。</p></section>''';
    }
    final items = records.asMap().entries.map((entry) {
      final record = entry.value;
      return '''<details><summary>${_escape(titleBuilder(record, entry.key))}</summary><div class="detail"><pre>${_escape(const JsonEncoder.withIndent('  ').convert(record))}</pre></div></details>''';
    }).join();
    return '<section><h2>$title（${records.length} 条）</h2>$items</section>';
  }

  static String _aiReportSection(List<Map<String, dynamic>> reports) {
    if (reports.isEmpty) {
      return '<section><h2>AI 报告</h2><p class="empty">暂无可导出的报告。</p></section>';
    }
    final items = reports.asMap().entries.map((entry) {
      final report = entry.value;
      final resultText = report['result_text']?.toString().trim() ?? '';
      return '''<details><summary>${_escape(_aiReportTitle(report, entry.key))}</summary><div class="detail">${resultText.isEmpty ? '<p class="empty">该报告暂无可展示内容。</p>' : '<h3>报告内容</h3><div class="report">${_escape(resultText)}</div>'}<h3 style="margin-top:12px">报告数据</h3><pre>${_escape(const JsonEncoder.withIndent('  ').convert(report))}</pre></div></details>''';
    }).join();
    return '<section><h2>AI 报告（${reports.length} 条）</h2>$items</section>';
  }

  static String _field(String label, Object? value) {
    final text = value == null || value.toString().trim().isEmpty
        ? '未提供'
        : value.toString();
    return '<div class="item"><span class="label">${_escape(label)}</span><span class="value">${_escape(text)}</span></div>';
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static List<Map<String, dynamic>> _records(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  static String _walletTransactionTitle(
      Map<String, dynamic> record, int index) {
    final type = {
          'recharge': '充值入账',
          'ai_debit': 'AI 解析扣费',
          'ai_refund': 'AI 解析退款',
          'manual_adjust': '余额调整',
          'registration_bonus': '注册赠送余额',
        }[record['type']] ??
        record['type']?.toString() ??
        '钱包流水';
    return '$type · ${_money(record['amount_cents'])} · ${_dateText(record['created_at'])}';
  }

  static String _rechargeTitle(Map<String, dynamic> record, int index) {
    final provider = record['provider'] == 'alipay' ? '支付宝' : '微信支付';
    return '$provider · ${_money(record['amount_cents'])} · ${_statusText(record['status'])}';
  }

  static String _aiReportTitle(Map<String, dynamic> record, int index) {
    return '${record['report_type'] ?? record['product_id'] ?? 'AI 报告'} · ${_money(record['price_cents'])} · ${_statusText(record['status'])}';
  }

  static String _historyTitle(Map<String, dynamic> record, int index) {
    return '${record['featureName'] ?? record['featureId'] ?? record['title'] ?? '历史记录'} · ${_dateText(record['createdAt'] ?? record['updatedAt'])}';
  }

  static String _profileTitle(Map<String, dynamic> record, int index) {
    return '${record['displayName'] ?? '命盘档案'} · ${_dateText(record['updatedAt'] ?? record['createdAt'])}';
  }

  static String _statusText(Object? raw) {
    return {
          'pending': '处理中',
          'generating': '生成中',
          'completed': '已完成',
          'paid': '已支付',
          'closed': '已关闭',
          'failed': '失败',
          'refunded': '已退款',
        }[raw] ??
        raw?.toString() ??
        '未提供';
  }

  static String _money(Object? cents) {
    final value = cents is num ? cents : num.tryParse(cents?.toString() ?? '');
    if (value == null) return '未提供';
    return '¥${(value / 100).toStringAsFixed(2)}';
  }

  static String _dateText(Object? value) {
    final date =
        value is DateTime ? value : DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return value?.toString() ?? '未提供';
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _escape(Object? value) {
    return (value?.toString() ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}

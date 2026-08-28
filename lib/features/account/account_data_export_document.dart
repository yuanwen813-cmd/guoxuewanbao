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
    h1 { margin: 0; font-size: 28px; } h2 { margin: 0 0 14px; font-size: 20px; } h3 { margin: 0 0 8px; font-size: 16px; }
    .muted, .empty { color: #6f685e; } .notice { margin: 20px 0; padding: 14px 16px; border: 1px solid #ead6bb; border-radius: 8px; background: #fff9eb; color: #67481a; }
    section { margin-top: 18px; padding: 20px; border: 1px solid #e4ded3; border-radius: 8px; background: #fffdfa; box-shadow: 0 1px 2px rgba(57, 45, 28, .04); }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(210px, 1fr)); gap: 12px; }
    .item { min-width: 0; padding: 11px 12px; border-radius: 6px; background: #f8f4ed; } .label { display: block; margin-bottom: 2px; color: #766e63; font-size: 12px; } .value { overflow-wrap: anywhere; font-weight: 600; }
    details { margin-top: 10px; overflow: hidden; border: 1px solid #e9e2d7; border-radius: 6px; background: #fff; } summary { cursor: pointer; padding: 11px 12px; font-weight: 600; } .detail { padding: 0 12px 12px; }
    .report { margin: 0; padding: 12px; border-radius: 5px; background: #f7f5f1; color: #3d3933; white-space: pre-wrap; overflow-wrap: anywhere; }
    footer { margin-top: 24px; color: #766e63; font-size: 13px; }
  </style>
</head>
<body>
  <main>
    <header><h1>国学万宝匣个人数据导出</h1><div class="muted">导出时间：${_escape(_dateText(exported))}</div></header>
    <div class="notice">此文件只包含便于个人查阅的信息，不包含支付链接、支付平台交易号、订单内部标识、AI 提示词或技术快照。文件仍含个人资料，请仅在可信设备保存。</div>
    <section><h2>账号与钱包</h2><div class="grid">
      ${_field('手机号', account['phone'])}${_field('昵称', account['nickname'])}${_field('账户状态', _accountStatus(account['status']))}${_field('账户创建时间', account['createdAt'])}${_field('当前余额', _money(wallet['balanceCents']))}${_field('最近更新时间', wallet['updatedAt'])}
    </div></section>
    ${_walletTransactionsSection(transactions)}
    ${_rechargeOrdersSection(recharges)}
    ${_aiReportsSection(reports)}
    ${_historiesSection(histories)}
    ${_birthProfilesSection(profiles)}
    <section><h2>导出摘要</h2><div class="grid">
      ${_field('钱包流水', '${transactions.length} 条')}${_field('充值订单', '${recharges.length} 条')}${_field('AI 报告', '${reports.length} 条')}${_field('历史记录', '${histories.length} 条')}${_field('命盘档案', '${profiles.length} 条')}
    </div></section>
    <footer>本文件由国学万宝匣生成，用于用户个人数据查阅与留存。</footer>
  </main>
</body>
</html>''';
  }

  static String _walletTransactionsSection(List<Map<String, dynamic>> records) {
    return _section(
      '钱包流水',
      records,
      (record) =>
          '${_transactionType(record['type'])} · ${_money(record['amountCents'])} · ${_dateText(record['createdAt'])}',
      (record) => _grid([
        _field('类型', _transactionType(record['type'])),
        _field('金额', _money(record['amountCents'])),
        _field('变动后余额', _money(record['balanceAfterCents'])),
        _field('发生时间', record['createdAt']),
        if (_hasValue(record['note'])) _field('说明', record['note']),
      ]),
    );
  }

  static String _rechargeOrdersSection(List<Map<String, dynamic>> records) {
    return _section(
      '充值订单',
      records,
      (record) =>
          '${_paymentProvider(record['provider'])} · ${_money(record['amountCents'])} · ${_statusText(record['status'])}',
      (record) => _grid([
        _field('支付方式', _paymentProvider(record['provider'])),
        _field('金额', _money(record['amountCents'])),
        _field('状态', _statusText(record['status'])),
        _field('下单时间', record['createdAt']),
        _field('支付完成时间', record['paidAt']),
      ]),
    );
  }

  static String _aiReportsSection(List<Map<String, dynamic>> records) {
    return _section(
      'AI 报告',
      records,
      (record) =>
          '${_reportType(record['reportType'])} · ${_money(record['priceCents'])} · ${_statusText(record['status'])}',
      (record) {
        final resultText = record['resultText']?.toString().trim() ?? '';
        return '${_grid([
              _field('报告类型', _reportType(record['reportType'])),
              _field('价格', _money(record['priceCents'])),
              _field('状态', _statusText(record['status'])),
              _field('生成时间', record['createdAt']),
            ])}${resultText.isEmpty ? '<p class="empty">该报告暂无可展示内容。</p>' : '<h3 style="margin-top:14px">报告内容</h3><div class="report">${_escape(resultText)}</div>'}';
      },
    );
  }

  static String _historiesSection(List<Map<String, dynamic>> records) {
    return _section(
      '历史记录',
      records,
      (record) =>
          '${record['featureName'] ?? '问事记录'} · ${_dateText(record['createdAt'])}',
      (record) => _grid([
        _field('功能', record['featureName']),
        _field('所问事项', record['question']),
        _field('结果摘要', record['summary']),
        _field('记录时间', record['createdAt']),
        _field('标签', _stringList(record['tags'])),
        _field('收藏状态', record['isFavorite'] == true ? '已收藏' : '未收藏'),
      ]),
    );
  }

  static String _birthProfilesSection(List<Map<String, dynamic>> records) {
    return _section(
      '命盘档案',
      records,
      (record) =>
          '${record['displayName'] ?? '未命名档案'} · ${_dateText(record['updatedAt'] ?? record['createdAt'])}',
      (record) => _grid([
        _field('名称', record['displayName']),
        _field('关系', _relationship(record['relationship'])),
        _field('性别', _gender(record['gender'])),
        _field('公历出生', record['gregorianBirthDateTime']),
        _field('出生时间准确度', _timeAccuracy(record['birthTimeAccuracy'])),
        _field('出生地', record['birthPlaceName']),
        _field('农历出生', record['lunarBirthDateText']),
        if (_hasValue(record['notes'])) _field('备注', record['notes']),
      ]),
    );
  }

  static String _section(
    String title,
    List<Map<String, dynamic>> records,
    String Function(Map<String, dynamic>) summary,
    String Function(Map<String, dynamic>) detail,
  ) {
    if (records.isEmpty) {
      return '<section><h2>$title</h2><p class="empty">暂无可导出的记录。</p></section>';
    }
    final items = records.map((record) {
      return '<details><summary>${_escape(summary(record))}</summary><div class="detail">${detail(record)}</div></details>';
    }).join();
    return '<section><h2>$title（${records.length} 条）</h2>$items</section>';
  }

  static String _grid(List<String> fields) =>
      '<div class="grid">${fields.join()}</div>';

  static String _field(String label, Object? value) {
    final text = _hasValue(value) ? _displayValue(value) : '未提供';
    return '<div class="item"><span class="label">${_escape(label)}</span><span class="value">${_escape(text)}</span></div>';
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  static List<Map<String, dynamic>> _records(Object? value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : const [];

  static bool _hasValue(Object? value) =>
      value != null && value.toString().trim().isNotEmpty;

  static String _displayValue(Object? value) =>
      value is String && DateTime.tryParse(value) != null
          ? _dateText(value)
          : value.toString();

  static String _stringList(Object? value) => value is List && value.isNotEmpty
      ? value.map((item) => item.toString()).join('、')
      : '未提供';

  static String _transactionType(Object? value) =>
      {
        'recharge': '充值入账',
        'ai_debit': 'AI 解析扣费',
        'ai_refund': 'AI 解析退款',
        'manual_adjust': '余额调整',
        'registration_bonus': '注册赠送余额',
      }[value] ??
      '余额变动';

  static String _paymentProvider(Object? value) => value == 'alipay'
      ? '支付宝'
      : value == 'wechat'
          ? '微信支付'
          : '其他方式';

  static String _reportType(Object? value) =>
      {
        'question_brief': '问事简析',
        'question_full': '问事完整解析',
        'bazi_brief': '命盘简析',
        'bazi_basic': '命盘基础报告',
        'bazi_deep': '命盘深度报告',
      }[value] ??
      'AI 解析报告';

  static String _statusText(Object? value) =>
      {
        'pending': '处理中',
        'generating': '生成中',
        'completed': '已完成',
        'paid': '已支付',
        'closed': '已关闭',
        'failed': '失败',
        'refunded': '已退款',
      }[value] ??
      '未提供';

  static String _accountStatus(Object? value) =>
      value == 'active' ? '正常' : '未提供';

  static String _relationship(Object? value) =>
      {
        'self': '本人',
        'family': '家人',
        'friend': '朋友',
        'client': '客户',
        'other': '其他',
      }[value] ??
      '未提供';

  static String _gender(Object? value) =>
      {
        'male': '男',
        'female': '女',
        'other': '其他',
        'undisclosed': '不透露',
      }[value] ??
      '未提供';

  static String _timeAccuracy(Object? value) =>
      {
        'accurate': '准确',
        'approximate': '大致',
        'unknown': '不确定',
      }[value] ??
      '未提供';

  static String _money(Object? cents) {
    final value = cents is num ? cents : num.tryParse(cents?.toString() ?? '');
    return value == null ? '未提供' : '¥${(value / 100).toStringAsFixed(2)}';
  }

  static String _dateText(Object? value) {
    final date =
        value is DateTime ? value : DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? value?.toString() ?? '未提供'
        : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _escape(Object? value) => (value?.toString() ?? '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

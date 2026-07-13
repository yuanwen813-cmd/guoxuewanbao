import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/guoxue_colors.dart';
import 'admin_api.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _api = AdminApi();
  final _session = AdminSessionStore.instance;
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _searchController = TextEditingController();
  final _userIdController = TextEditingController();
  final _adjustUserIdController = TextEditingController();
  final _adjustAmountController = TextEditingController();
  final _adjustReasonController = TextEditingController();

  String? _token;
  Map<String, dynamic>? _admin;
  String _tab = 'dashboard';
  bool _loading = true;
  bool _submitting = false;
  String? _message;
  String? _error;

  Map<String, dynamic>? _dashboard;
  List<dynamic> _users = const [];
  List<dynamic> _transactions = const [];
  List<dynamic> _recharges = const [];
  List<dynamic> _aiReports = const [];
  List<dynamic> _audits = const [];

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _searchController.dispose();
    _userIdController.dispose();
    _adjustUserIdController.dispose();
    _adjustAmountController.dispose();
    _adjustReasonController.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final token = await _session.readToken();
    if (token == null || token.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final data = await _api.me(token);
      setState(() {
        _token = token;
        _admin = data['admin'] as Map<String, dynamic>?;
      });
      await _loadDashboard();
    } catch (_) {
      await _session.clear();
      setState(() {
        _token = null;
        _admin = null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _signedIn => _token != null && _admin != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3E9),
      appBar: AppBar(
        title: const Text('国学万宝匣管理后台'),
        actions: [
          if (_signedIn)
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('退出后台'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _signedIn
              ? _buildConsole()
              : _buildLogin(),
    );
  }

  Widget _buildLogin() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _Panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '后台管理员登录',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '只有配置在后台白名单里的手机号可以登录。',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: '管理员手机号',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '验证码',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _submitting ? null : _sendCode,
                    child: const Text('获取验证码'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submitting ? null : _verifyCode,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('进入管理后台'),
              ),
              _MessageBar(message: _message, error: _error),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsole() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 220,
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFE8DDCC))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _admin?['phone'] as String? ?? '',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _admin?['role'] as String? ?? 'admin',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              _NavButton(
                selected: _tab == 'dashboard',
                icon: Icons.dashboard_outlined,
                label: '概览',
                onTap: () => _switchTab('dashboard'),
              ),
              _NavButton(
                selected: _tab == 'users',
                icon: Icons.people_alt_outlined,
                label: '用户',
                onTap: () => _switchTab('users'),
              ),
              _NavButton(
                selected: _tab == 'transactions',
                icon: Icons.account_balance_wallet_outlined,
                label: '钱包流水',
                onTap: () => _switchTab('transactions'),
              ),
              _NavButton(
                selected: _tab == 'recharges',
                icon: Icons.payments_outlined,
                label: '充值订单',
                onTap: () => _switchTab('recharges'),
              ),
              _NavButton(
                selected: _tab == 'ai',
                icon: Icons.auto_awesome_outlined,
                label: 'AI 报告',
                onTap: () => _switchTab('ai'),
              ),
              _NavButton(
                selected: _tab == 'adjust',
                icon: Icons.tune_outlined,
                label: '手工调账',
                onTap: () => _switchTab('adjust'),
              ),
              _NavButton(
                selected: _tab == 'audit',
                icon: Icons.fact_check_outlined,
                label: '审计日志',
                onTap: () => _switchTab('audit'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _MessageBar(message: _message, error: _error),
              if (_submitting) const LinearProgressIndicator(),
              const SizedBox(height: 12),
              switch (_tab) {
                'users' => _buildUsers(),
                'transactions' => _buildTransactions(),
                'recharges' => _buildRecharges(),
                'ai' => _buildAiReports(),
                'adjust' => _buildAdjust(),
                'audit' => _buildAudits(),
                _ => _buildDashboard(),
              },
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard() {
    final data = _dashboard ?? const <String, dynamic>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '运营概览',
          actionLabel: '刷新',
          onAction: _loadDashboard,
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(label: '用户数', value: '${data['users'] ?? 0}'),
            _MetricCard(
              label: '钱包总余额',
              value: _formatCents(data['totalWalletBalanceCents']),
            ),
            _MetricCard(
              label: '已支付充值',
              value: _formatCents(data['paidRechargeCents']),
            ),
            _MetricCard(
              label: '待支付订单',
              value: '${data['pendingRechargeOrders'] ?? 0}',
            ),
            _MetricCard(
              label: 'AI 完成报告',
              value: '${data['completedAiReports'] ?? 0}',
            ),
            _MetricCard(
              label: 'AI 收入',
              value: _formatCents(data['aiRevenueCents']),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '用户查询',
          actionLabel: '查询',
          onAction: _loadUsers,
        ),
        _FilterRow(
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: '手机号或昵称',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        _DataPanel(
          empty: _users.isEmpty,
          emptyText: '暂无用户数据',
          child: DataTable(
            columns: const [
              DataColumn(label: Text('手机号')),
              DataColumn(label: Text('昵称')),
              DataColumn(label: Text('状态')),
              DataColumn(label: Text('余额')),
              DataColumn(label: Text('注册时间')),
              DataColumn(label: Text('操作')),
            ],
            rows: [
              for (final item in _users)
                DataRow(
                  cells: [
                    DataCell(SelectableText(_text(item, 'phone'))),
                    DataCell(Text(_text(item, 'nickname'))),
                    DataCell(Text(_text(item, 'status'))),
                    DataCell(Text(_formatCents(_wallet(item)['balanceCents']))),
                    DataCell(Text(_shortTime(_text(item, 'createdAt')))),
                    DataCell(
                      TextButton(
                        onPressed: () => _showUserDetail(item),
                        child: const Text('详情'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '钱包流水',
          actionLabel: '查询',
          onAction: _loadTransactions,
        ),
        _FilterRow(
          children: [
            SizedBox(
              width: 360,
              child: TextField(
                controller: _userIdController,
                decoration: const InputDecoration(
                  labelText: '用户 ID，可留空查最近流水',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        _DataPanel(
          empty: _transactions.isEmpty,
          emptyText: '暂无钱包流水',
          child: DataTable(
            columns: const [
              DataColumn(label: Text('类型')),
              DataColumn(label: Text('金额')),
              DataColumn(label: Text('变动后余额')),
              DataColumn(label: Text('备注')),
              DataColumn(label: Text('时间')),
            ],
            rows: [
              for (final item in _transactions)
                DataRow(
                  cells: [
                    DataCell(Text(_transactionType(_text(item, 'type')))),
                    DataCell(Text(_formatCents(item['amountCents']))),
                    DataCell(Text(_formatCents(item['balanceAfterCents']))),
                    DataCell(Text(_text(item, 'note'))),
                    DataCell(Text(_shortTime(_text(item, 'createdAt')))),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecharges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '充值订单',
          actionLabel: '刷新',
          onAction: _loadRecharges,
        ),
        _DataPanel(
          empty: _recharges.isEmpty,
          emptyText: '暂无充值订单',
          child: DataTable(
            columns: const [
              DataColumn(label: Text('手机号')),
              DataColumn(label: Text('渠道')),
              DataColumn(label: Text('金额')),
              DataColumn(label: Text('状态')),
              DataColumn(label: Text('订单号')),
              DataColumn(label: Text('创建时间')),
            ],
            rows: [
              for (final item in _recharges)
                DataRow(
                  cells: [
                    DataCell(Text(_text(item, 'userPhone'))),
                    DataCell(Text(_providerLabel(_text(item, 'provider')))),
                    DataCell(Text(_formatCents(item['amountCents']))),
                    DataCell(Text(_rechargeStatus(_text(item, 'status')))),
                    DataCell(SelectableText(_text(item, 'outTradeNo'))),
                    DataCell(Text(_shortTime(_text(item, 'createdAt')))),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'AI 报告查询',
          actionLabel: '刷新',
          onAction: _loadAiReports,
        ),
        _DataPanel(
          empty: _aiReports.isEmpty,
          emptyText: '暂无 AI 报告',
          child: DataTable(
            columns: const [
              DataColumn(label: Text('手机号')),
              DataColumn(label: Text('产品')),
              DataColumn(label: Text('金额')),
              DataColumn(label: Text('状态')),
              DataColumn(label: Text('时间')),
              DataColumn(label: Text('操作')),
            ],
            rows: [
              for (final item in _aiReports)
                DataRow(
                  cells: [
                    DataCell(Text(_text(item, 'userPhone'))),
                    DataCell(Text(_text(item, 'productId'))),
                    DataCell(Text(_formatCents(item['priceCents']))),
                    DataCell(Text(_aiStatus(_text(item, 'status')))),
                    DataCell(Text(_shortTime(_text(item, 'createdAt')))),
                    DataCell(
                      TextButton(
                        onPressed: () => _showAiReport(item),
                        child: const Text('查看'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdjust() {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '手工余额调整',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            '只用于客服补偿、异常退款或人工修正。所有操作都会写入钱包流水和审计日志。',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _adjustUserIdController,
            decoration: const InputDecoration(
              labelText: '用户 ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adjustAmountController,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: '调整金额，单位元，增加填 10，扣减填 -10',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adjustReasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '调整原因',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submitting ? null : _confirmAdjust,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('确认调整'),
          ),
        ],
      ),
    );
  }

  Widget _buildAudits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '审计日志',
          actionLabel: '刷新',
          onAction: _loadAudits,
        ),
        _DataPanel(
          empty: _audits.isEmpty,
          emptyText: '暂无审计日志',
          child: DataTable(
            columns: const [
              DataColumn(label: Text('管理员')),
              DataColumn(label: Text('动作')),
              DataColumn(label: Text('对象')),
              DataColumn(label: Text('时间')),
            ],
            rows: [
              for (final item in _audits)
                DataRow(
                  cells: [
                    DataCell(Text(_text(item, 'adminPhone'))),
                    DataCell(Text(_text(item, 'action'))),
                    DataCell(Text(
                        '${_text(item, 'targetType')} ${_text(item, 'targetId')}')),
                    DataCell(Text(_shortTime(_text(item, 'createdAt')))),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendCode() async {
    await _run(() async {
      await _api.sendCode(_phoneController.text.trim());
      _message = '验证码已发送';
    });
  }

  Future<void> _verifyCode() async {
    await _run(() async {
      final data = await _api.verifyCode(
        phone: _phoneController.text.trim(),
        code: _codeController.text.trim(),
      );
      final token = data['token'] as String? ?? '';
      if (token.isEmpty) throw StateError('后台令牌为空');
      await _session.saveToken(token);
      _token = token;
      _admin = data['admin'] as Map<String, dynamic>?;
      _message = '后台登录成功';
      await _loadDashboard(silent: true);
    });
  }

  Future<void> _logout() async {
    await _session.clear();
    setState(() {
      _token = null;
      _admin = null;
      _message = '已退出后台';
      _error = null;
    });
  }

  Future<void> _switchTab(String tab) async {
    setState(() => _tab = tab);
    switch (tab) {
      case 'dashboard':
        await _loadDashboard();
      case 'users':
        await _loadUsers();
      case 'transactions':
        await _loadTransactions();
      case 'recharges':
        await _loadRecharges();
      case 'ai':
        await _loadAiReports();
      case 'audit':
        await _loadAudits();
      case 'adjust':
        setState(() {
          _message = null;
          _error = null;
        });
    }
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    await _run(() async {
      final data = await _api.dashboard(_token!);
      _dashboard = data['dashboard'] as Map<String, dynamic>? ?? {};
      if (!silent) _message = '概览已刷新';
    }, silent: silent);
  }

  Future<void> _loadUsers() async {
    await _run(() async {
      final data = await _api.users(_token!, q: _searchController.text);
      _users = data['items'] as List<dynamic>? ?? const [];
      _message = '用户列表已刷新';
    });
  }

  Future<void> _loadTransactions() async {
    await _run(() async {
      final data = await _api.walletTransactions(
        _token!,
        userId: _userIdController.text,
      );
      _transactions = data['items'] as List<dynamic>? ?? const [];
      _message = '钱包流水已刷新';
    });
  }

  Future<void> _loadRecharges() async {
    await _run(() async {
      final data = await _api.rechargeOrders(_token!);
      _recharges = data['items'] as List<dynamic>? ?? const [];
      _message = '充值订单已刷新';
    });
  }

  Future<void> _loadAiReports() async {
    await _run(() async {
      final data = await _api.aiReportOrders(_token!);
      _aiReports = data['items'] as List<dynamic>? ?? const [];
      _message = 'AI 报告已刷新';
    });
  }

  Future<void> _loadAudits() async {
    await _run(() async {
      final data = await _api.auditLogs(_token!);
      _audits = data['items'] as List<dynamic>? ?? const [];
      _message = '审计日志已刷新';
    });
  }

  Future<void> _showUserDetail(Object raw) async {
    final item = raw as Map<String, dynamic>;
    await _run(() async {
      final data = await _api.userDetail(_token!, userId: _text(item, 'id'));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => _JsonDialog(
          title: '用户详情',
          data: data,
        ),
      );
    });
  }

  Future<void> _showAiReport(Object raw) async {
    final item = raw as Map<String, dynamic>;
    await _run(() async {
      final data = await _api.aiReportDetail(
        _token!,
        orderId: _text(item, 'id'),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => _JsonDialog(
          title: 'AI 报告详情',
          data: data,
        ),
      );
    });
  }

  Future<void> _confirmAdjust() async {
    final userId = _adjustUserIdController.text.trim();
    final yuan = double.tryParse(_adjustAmountController.text.trim());
    final reason = _adjustReasonController.text.trim();
    if (userId.isEmpty || yuan == null || yuan == 0 || reason.length < 4) {
      setState(() => _error = '请填写用户 ID、非零调整金额和调整原因');
      return;
    }
    final amountCents = (yuan * 100).round();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认手工调账'),
        content: Text(
          '将为用户 $userId 调整 ${_formatCents(amountCents)}。\n\n原因：$reason\n\n该操作会写入审计日志。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认调整'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(() async {
      await _api.adjustWallet(
        _token!,
        userId: userId,
        amountCents: amountCents,
        reason: reason,
      );
      _adjustAmountController.clear();
      _adjustReasonController.clear();
      _message = '余额调整成功，已写入流水和审计日志';
      await _loadAudits();
    });
  }

  Future<void> _run(
    Future<void> Function() action, {
    bool silent = false,
  }) async {
    if (_token == null && _signedIn) return;
    setState(() {
      _submitting = true;
      if (!silent) {
        _message = null;
        _error = null;
      }
    });
    try {
      await action();
    } catch (error) {
      _error = adminApiError(error);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8DDCC)),
      ),
      child: child,
    );
  }
}

class _MessageBar extends StatelessWidget {
  const _MessageBar({this.message, this.error});

  final String? message;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final text = error ?? message;
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    final isError = error != null;
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFFEBEE) : const Color(0xFFEAF7EA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? const Color(0xFFE57373) : const Color(0xFF81C784),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isError ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(label),
        ),
        style: TextButton.styleFrom(
          backgroundColor:
              selected ? GuoXueColors.primary.withOpacity(0.10) : null,
          foregroundColor: selected ? GuoXueColors.primary : Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

class _DataPanel extends StatelessWidget {
  const _DataPanel({
    required this.empty,
    required this.emptyText,
    required this.child,
  });

  final bool empty;
  final String emptyText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: empty
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Text(emptyText,
                  style: const TextStyle(color: Colors.black54)),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: child,
            ),
    );
  }
}

class _JsonDialog extends StatelessWidget {
  const _JsonDialog({required this.title, required this.data});

  final String title;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final text = data.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n\n');
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: SelectableText(text),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (context.mounted) Navigator.of(context).pop();
          },
          icon: const Icon(Icons.copy),
          label: const Text('复制'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

String _text(Object? item, String key) {
  if (item is! Map<String, dynamic>) return '';
  final value = item[key];
  if (value == null) return '';
  return '$value';
}

Map<String, dynamic> _wallet(Object? item) {
  if (item is! Map<String, dynamic>) return const {};
  final value = item['wallet'];
  return value is Map<String, dynamic> ? value : const {};
}

String _formatCents(Object? raw) {
  final value = raw is int ? raw : int.tryParse('$raw') ?? 0;
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();
  final yuan = abs ~/ 100;
  final cents = abs % 100;
  if (cents == 0) return '$sign¥$yuan';
  return '$sign¥$yuan.${cents.toString().padLeft(2, '0')}';
}

String _shortTime(String raw) {
  if (raw.length <= 16) return raw;
  return raw.replaceFirst('T', ' ').substring(0, 16);
}

String _transactionType(String type) {
  return switch (type) {
    'recharge' => '充值',
    'ai_debit' => 'AI 扣费',
    'ai_refund' => 'AI 退款',
    'manual_adjust' => '手工调账',
    _ => type,
  };
}

String _providerLabel(String provider) {
  return switch (provider) {
    'alipay' => '支付宝',
    'wechat' => '微信',
    _ => provider,
  };
}

String _rechargeStatus(String status) {
  return switch (status) {
    'paid' => '已支付',
    'pending' => '待支付',
    'closed' => '已关闭',
    'failed' => '失败',
    'refunded' => '已退款',
    _ => status,
  };
}

String _aiStatus(String status) {
  return switch (status) {
    'completed' => '已完成',
    'generating' => '生成中',
    'failed' => '失败',
    'refunded' => '已退款',
    'pending' => '待处理',
    _ => status,
  };
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../auth/auth_store.dart';
import 'payment_link_opener.dart';
import 'server_wallet_api.dart';
import 'wallet_store.dart';

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  final _customAmountController = TextEditingController();
  String? _customAmountError;
  String? _pageError;
  bool _customMode = false;
  bool _submitting = false;
  String _provider = 'alipay';
  int? _selectedAmountCents;
  RechargeCreateResult? _latestRecharge;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStoreProvider);
    final wallet = ref.watch(walletStoreProvider);

    ref.listen(authStoreProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        ref.read(walletStoreProvider.notifier).syncFromServer();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('钱包充值')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!auth.initialized)
            const Center(child: CircularProgressIndicator())
          else if (!auth.isAuthenticated)
            _LoginRequiredCard(
              onLogin: () => context.push('/login'),
            )
          else ...[
            _WalletSummaryCard(
              wallet: wallet,
              phone: auth.user?.phone,
              error: _pageError,
            ),
            const SizedBox(height: 18),
            _ProviderSelector(
              provider: _provider,
              submitting: _submitting,
              onChanged: _changeProvider,
            ),
            const SizedBox(height: 18),
            if (!_customMode) ...[
              Text('充值金额', style: GuoXueTypography.h3),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final option in const [
                    _RechargeOption(100, '¥1'),
                    _RechargeOption(390, '¥3.9'),
                    _RechargeOption(690, '¥6.9'),
                    _RechargeOption(1390, '¥13.9'),
                  ])
                    OutlinedButton(
                      key: Key('wallet_recharge_${option.amountCents}'),
                      onPressed: _submitting
                          ? null
                          : () => setState(() {
                                _selectedAmountCents = option.amountCents;
                                _pageError = null;
                              }),
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            _selectedAmountCents == option.amountCents
                                ? GuoXueColors.primary.withOpacity(0.08)
                                : null,
                      ),
                      child: Text(option.label),
                    ),
                  OutlinedButton(
                    key: const Key('wallet_custom_option'),
                    onPressed: _submitting
                        ? null
                        : () => setState(() {
                              _customMode = true;
                              _customAmountError = null;
                              _pageError = null;
                              _selectedAmountCents = null;
                            }),
                    child: const Text('自定义金额'),
                  ),
                ],
              ),
              if (_selectedAmountCents != null) ...[
                const SizedBox(height: 12),
                _RechargeConfirmCard(
                  amountCents: _selectedAmountCents!,
                  provider: _provider,
                  submitting: _submitting,
                  onConfirm: () => _createRecharge(_selectedAmountCents!),
                ),
              ],
            ],
            if (_customMode) ...[
              Text('自定义金额', style: GuoXueTypography.h3),
              const SizedBox(height: 10),
              TextField(
                key: const Key('wallet_custom_amount'),
                controller: _customAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: '输入充值金额',
                  suffixText: '元',
                  errorText: _customAmountError,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                key: const Key('wallet_custom_recharge'),
                onPressed: _submitting ? null : _rechargeCustom,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_card_outlined),
                label: Text(_submitting ? '正在创建订单' : '确认充值'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('wallet_fixed_options'),
                  onPressed: _submitting
                      ? null
                      : () => setState(() {
                            _customMode = false;
                            _customAmountError = null;
                            _pageError = null;
                            _selectedAmountCents = null;
                            _customAmountController.clear();
                          }),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('返回固定档位'),
                ),
              ),
            ],
            if (_latestRecharge != null) ...[
              const SizedBox(height: 18),
              _RechargeStatusCard(
                result: _latestRecharge!,
                onRefresh: _refreshLatestRecharge,
                onCancel: _cancelLatestRecharge,
              ),
            ],
            const SizedBox(height: 22),
            Text('最近流水', style: GuoXueTypography.h3),
            const SizedBox(height: 10),
            if (wallet.transactions.isEmpty)
              Text(
                '暂无流水',
                style: GuoXueTypography.body.copyWith(
                  color: GuoXueColors.inkGray,
                  letterSpacing: 0,
                ),
              )
            else
              for (final tx in wallet.transactions.take(20))
                _WalletTransactionTile(transaction: tx),
          ],
        ],
      ),
    );
  }

  Future<void> _rechargeCustom() async {
    final text = _customAmountController.text.trim();
    final yuan = int.tryParse(text);
    if (yuan == null || yuan < 1) {
      setState(() => _customAmountError = '充值金额必须是不低于 1 元的整数');
      return;
    }
    if (yuan > 999) {
      setState(() => _customAmountError = '单次自定义充值不能超过 999 元');
      return;
    }
    setState(() => _customAmountError = null);
    await _createRecharge(yuan * 100);
    _customAmountController.clear();
    if (mounted) {
      setState(() => _customMode = false);
    }
  }

  void _changeProvider(String provider) {
    if (provider == _provider) return;
    _pollTimer?.cancel();
    setState(() {
      _provider = provider;
      _latestRecharge = null;
      _pageError = null;
    });
  }

  Future<void> _createRecharge(int amountCents) async {
    setState(() {
      _submitting = true;
      _pageError = null;
    });
    try {
      final result =
          await ref.read(walletStoreProvider.notifier).createRecharge(
                amountCents: amountCents,
                provider: _provider,
                tradeType: _provider == 'wechat' ? 'web_native' : 'web_pc',
              );
      if (!mounted) return;
      setState(() => _latestRecharge = result);
      _startPolling(result.order);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('充值订单已创建，请完成支付后等待到账')),
      );
    } on ServerWalletException catch (error) {
      if (!mounted) return;
      setState(() => _pageError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _pageError = '充值订单创建失败，请稍后再试。');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _startPolling(RechargeOrder order) {
    _pollTimer?.cancel();
    var count = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      count += 1;
      if (count > 20 || order.outTradeNo.isEmpty) {
        timer.cancel();
        return;
      }
      await _refreshLatestRecharge();
      final latest = _latestRecharge?.order.status;
      if (latest == 'paid' || latest == 'closed' || latest == 'failed') {
        timer.cancel();
      }
    });
  }

  Future<void> _refreshLatestRecharge() async {
    final current = _latestRecharge;
    if (current == null) return;
    try {
      final order =
          await ref.read(walletStoreProvider.notifier).refreshRechargeStatus(
                orderId: current.order.id,
                outTradeNo: current.order.outTradeNo,
              );
      if (!mounted) return;
      if (_latestRecharge?.order.id != current.order.id) return;
      if (order.status == 'closed') {
        setState(() => _latestRecharge = null);
        return;
      }
      setState(() {
        _latestRecharge = RechargeCreateResult(
          order: order,
          payment: current.payment,
          wallet: ref.read(walletStoreProvider),
        );
      });
    } catch (_) {
      // 轮询失败不打断页面，用户可以手动刷新支付结果。
    }
  }

  Future<void> _cancelLatestRecharge() async {
    final current = _latestRecharge;
    if (current == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消待支付订单'),
        content: Text(
          '确定取消这笔 ${_providerLabel(current.order.provider)} '
          '${formatWalletCents(current.order.amountCents)} 订单吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续保留'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认取消'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _pollTimer?.cancel();
    setState(() {
      _submitting = true;
      _pageError = null;
      _latestRecharge = null;
    });
    try {
      await ref.read(walletStoreProvider.notifier).cancelRecharge(
            orderId: current.order.id,
            outTradeNo: current.order.outTradeNo,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('待支付订单已取消')),
      );
    } on ServerWalletException catch (error) {
      if (!mounted) return;
      setState(() {
        _latestRecharge = current;
        _pageError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _latestRecharge = current;
        _pageError = '取消订单失败，请稍后再试。';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _RechargeOption {
  final int amountCents;
  final String label;

  const _RechargeOption(this.amountCents, this.label);
}

String _providerLabel(String provider) {
  return switch (provider) {
    'alipay' => '支付宝充值',
    'wechat' => '微信充值',
    _ => '充值',
  };
}

class _RechargeConfirmCard extends StatelessWidget {
  final int amountCents;
  final String provider;
  final bool submitting;
  final VoidCallback onConfirm;

  const _RechargeConfirmCard({
    required this.amountCents,
    required this.provider,
    required this.submitting,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('wallet_recharge_confirm_card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('确认充值信息', style: GuoXueTypography.h3),
          const SizedBox(height: 8),
          Text(
            '支付方式：${_providerLabel(provider)}\n充值金额：${formatWalletCents(amountCents)}',
            style: GuoXueTypography.caption.copyWith(
              color: GuoXueColors.inkGray,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('wallet_confirm_recharge'),
            onPressed: submitting ? null : onConfirm,
            icon: submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              submitting
                  ? '正在创建订单'
                  : '确认创建 ${formatWalletCents(amountCents)} 充值订单',
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginRequiredCard extends StatelessWidget {
  final VoidCallback onLogin;

  const _LoginRequiredCard({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('请先登录', style: GuoXueTypography.h2),
          const SizedBox(height: 8),
          Text(
            '登录后才能查看服务端钱包余额、创建充值订单和生成 AI 报告。',
            style: GuoXueTypography.caption.copyWith(
              color: GuoXueColors.inkGray,
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onLogin,
            icon: const Icon(Icons.login),
            label: const Text('手机号登录'),
          ),
        ],
      ),
    );
  }
}

class _WalletSummaryCard extends StatelessWidget {
  final WalletState wallet;
  final String? phone;
  final String? error;

  const _WalletSummaryCard({
    required this.wallet,
    this.phone,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            phone == null ? '当前钱包余额' : '当前钱包余额 · $phone',
            style: GuoXueTypography.caption.copyWith(
              color: GuoXueColors.inkGray,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatWalletCents(wallet.balanceCents),
            key: const Key('wallet_balance_text'),
            style: GuoXueTypography.h1.copyWith(
              color: GuoXueColors.primary,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '余额用于 AI 解析扣费。支付完成后以支付宝异步回调入账为准，前端支付成功不会直接增加余额。',
            style: GuoXueTypography.caption.copyWith(
              color: GuoXueColors.inkGray,
              height: 1.4,
              letterSpacing: 0,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.error,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProviderSelector extends StatelessWidget {
  final String provider;
  final bool submitting;
  final ValueChanged<String> onChanged;

  const _ProviderSelector({
    required this.provider,
    required this.submitting,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('充值方式', style: GuoXueTypography.h3),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            ChoiceChip(
              key: const Key('wallet_provider_alipay'),
              selected: provider == 'alipay',
              onSelected: submitting ? null : (_) => onChanged('alipay'),
              label: const Text('支付宝充值'),
            ),
          ],
        ),
      ],
    );
  }
}

class _RechargeStatusCard extends StatelessWidget {
  final RechargeCreateResult result;
  final VoidCallback onRefresh;
  final VoidCallback onCancel;

  const _RechargeStatusCard({
    required this.result,
    required this.onRefresh,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final payment = result.payment;
    final order = result.order;
    final paymentText = payment.codeUrl ?? payment.payUrl;
    final paid = order.status == 'paid';
    return Container(
      key: const Key('wallet_recharge_status'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: paid
            ? GuoXueColors.success.withOpacity(0.08)
            : GuoXueColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: paid
              ? GuoXueColors.success.withOpacity(0.18)
              : GuoXueColors.primary.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                paid ? Icons.check_circle_outline : Icons.payments_outlined,
                size: 20,
                color: paid ? GuoXueColors.success : GuoXueColors.primary,
              ),
              const SizedBox(width: 8),
              Text(paid ? '支付已完成' : '等待支付', style: GuoXueTypography.h3),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '支付方式：${_providerLabel(order.provider)}\n'
            '订单号：${order.outTradeNo}\n'
            '金额：${formatWalletCents(order.amountCents)}\n'
            '状态：${_statusLabel(order.status)}',
            style: GuoXueTypography.caption.copyWith(
              color: GuoXueColors.inkGray,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
          if (!paid) ...[
            const SizedBox(height: 12),
            _PaymentInstruction(payment: payment, paymentText: paymentText),
          ],
          if (paymentText != null && !paid) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (payment.payUrl != null || payment.provider == 'alipay')
                  FilledButton.icon(
                    key: const Key('wallet_open_pay_url'),
                    onPressed: () => _openPayment(context, paymentText),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('打开支付页面'),
                  ),
                OutlinedButton.icon(
                  key: const Key('wallet_copy_pay_url'),
                  onPressed: () => _copyPaymentText(context, paymentText),
                  icon: const Icon(Icons.copy),
                  label: const Text('复制支付信息'),
                ),
              ],
            ),
          ],
          if (payment.provider == 'wechat' &&
              payment.codeUrl != null &&
              !paid) ...[
            const SizedBox(height: 12),
            Container(
              key: const Key('wallet_wechat_pay_code'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.72),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: GuoXueColors.gold.withOpacity(0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '微信支付链接',
                    style: GuoXueTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    payment.codeUrl!,
                    style: GuoXueTypography.caption.copyWith(
                      color: GuoXueColors.primary,
                      height: 1.4,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '微信 Native 支付会返回扫码链接。当前页面先提供复制入口，支付完成后余额会自动刷新，也可以手动刷新支付结果。',
                    style: GuoXueTypography.caption.copyWith(
                      color: GuoXueColors.inkGray,
                      height: 1.4,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (payment.message != null) ...[
            const SizedBox(height: 12),
            Text(
              payment.message!,
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.inkGray,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('刷新支付结果'),
              ),
              if (!paid)
                TextButton.icon(
                  key: const Key('wallet_cancel_recharge'),
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                  label: const Text('取消订单'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'paid' => '已支付，余额已刷新',
      'closed' => '已关闭',
      'failed' => '支付失败',
      'refunded' => '已退款',
      _ => '等待支付回调',
    };
  }

  Future<void> _openPayment(BuildContext context, String url) async {
    if (Uri.tryParse(url) == null) {
      _showMessage(context, '支付链接无效，请复制支付信息后重试');
      return;
    }
    final opened = await openPaymentLink(url);
    if (!opened && context.mounted) {
      _showMessage(context, '当前环境无法直接打开支付页，请复制支付信息后重试');
    }
  }

  Future<void> _copyPaymentText(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      _showMessage(context, '支付信息已复制');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _PaymentInstruction extends StatelessWidget {
  final RechargePayment payment;
  final String? paymentText;

  const _PaymentInstruction({
    required this.payment,
    required this.paymentText,
  });

  @override
  Widget build(BuildContext context) {
    final text = _instructionText();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _icon(),
            color: GuoXueColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.inkGray,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon() {
    if (!payment.paymentReady || paymentText == null) {
      return Icons.info_outline;
    }
    return payment.provider == 'wechat' ? Icons.qr_code_2 : Icons.open_in_new;
  }

  String _instructionText() {
    if (!payment.paymentReady || paymentText == null) {
      return '支付订单已创建，但当前支付参数未返回。请检查服务端微信或支付宝配置。';
    }
    if (payment.provider == 'wechat') {
      return '微信充值请扫码支付。到账只以微信支付异步回调为准，前端不会直接增加余额。';
    }
    if (payment.provider == 'alipay') {
      return '支付宝充值会打开新的支付页面。付款成功后请关闭支付宝页面，回到本页查看到账状态；到账只以支付宝异步通知为准。';
    }
    return '请完成支付后等待服务端回调入账。';
  }
}

class _WalletTransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const _WalletTransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.amountCents > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(
            isIncome ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: isIncome ? GuoXueColors.success : GuoXueColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              transaction.title,
              style: GuoXueTypography.body.copyWith(letterSpacing: 0),
            ),
          ),
          Text(
            formatWalletCents(transaction.amountCents),
            style: GuoXueTypography.body.copyWith(
              color: isIncome ? GuoXueColors.success : GuoXueColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

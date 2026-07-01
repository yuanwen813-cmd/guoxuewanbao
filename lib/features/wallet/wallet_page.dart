import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../auth/auth_store.dart';
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
  String _provider = 'wechat';
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
              onChanged: (value) => setState(() => _provider = value),
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
                          : () => _createRecharge(option.amountCents),
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
                            }),
                    child: const Text('自定义'),
                  ),
                ],
              ),
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
                label: Text(_submitting ? '创建订单中' : '确认充值'),
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
      setState(() {
        _latestRecharge = RechargeCreateResult(
          order: order,
          payment: current.payment,
          wallet: ref.read(walletStoreProvider),
        );
      });
    } catch (_) {
      // Polling failure should not interrupt the page; the user can refresh again.
    }
  }
}

class _RechargeOption {
  final int amountCents;
  final String label;

  const _RechargeOption(this.amountCents, this.label);
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
            phone == null ? '服务端钱包余额' : '服务端钱包余额 · $phone',
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
            '余额由服务端钱包和流水记录。支付完成后以微信或支付宝异步回调入账为准，前端支付成功不会直接增加余额。',
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
              key: const Key('wallet_provider_wechat'),
              selected: provider == 'wechat',
              onSelected: submitting ? null : (_) => onChanged('wechat'),
              label: const Text('微信充值'),
            ),
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

  const _RechargeStatusCard({
    required this.result,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final payment = result.payment;
    final order = result.order;
    return Container(
      key: const Key('wallet_recharge_status'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GuoXueColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('支付中', style: GuoXueTypography.h3),
          const SizedBox(height: 8),
          Text(
            '订单号：${order.outTradeNo}\n金额：${formatWalletCents(order.amountCents)}\n状态：${_statusLabel(order.status)}',
            style: GuoXueTypography.caption.copyWith(
              color: GuoXueColors.inkGray,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
          if (payment.codeUrl != null || payment.payUrl != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              payment.codeUrl ?? payment.payUrl!,
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.primary,
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
          ],
          if (payment.message != null) ...[
            const SizedBox(height: 8),
            Text(
              payment.message!,
              style: GuoXueTypography.caption.copyWith(
                color: GuoXueColors.inkGray,
                letterSpacing: 0,
              ),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('刷新支付结果'),
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

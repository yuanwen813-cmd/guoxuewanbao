import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import '../auth/auth_store.dart';
import '../wallet/wallet_store.dart';
import 'feature_catalog_v2.dart';
import 'v2_page_scaffold.dart';

class MineHomePage extends ConsumerWidget {
  const MineHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStoreProvider);
    final wallet = ref.watch(walletStoreProvider);

    ref.listen(authStoreProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        ref.read(walletStoreProvider.notifier).syncFromServer();
      }
    });

    return V2PageScaffold(
      title: '我的',
      subtitle: '管理问事记录、命盘档案、报告和钱包余额。',
      icon: Icons.person_outline,
      children: [
        _WalletBalanceCard(
          isAuthenticated: auth.isAuthenticated,
          phone: auth.user?.phone,
          balanceCents: wallet.balanceCents,
          onOpenWallet: () => context.push('/wallet'),
          onLogin: () => context.push('/login'),
          onLogout: () => _confirmLogout(context, ref),
        ),
        const SizedBox(height: 10),
        const V2SectionTitle(title: '我的资产'),
        const V2FeatureList(entries: FeatureCatalogV2.mineFeatures),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text(
          '确定退出当前账号吗？退出后不会删除你的余额、订单和 AI 报告，重新登录同一手机号仍可查看。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authStoreProvider.notifier).logout();
    await ref.read(walletStoreProvider.notifier).clearLocalSession();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已退出登录')),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  final bool isAuthenticated;
  final String? phone;
  final int balanceCents;
  final VoidCallback onOpenWallet;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  const _WalletBalanceCard({
    required this.isAuthenticated,
    required this.phone,
    required this.balanceCents,
    required this.onOpenWallet,
    required this.onLogin,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GuoXueColors.ricePaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GuoXueColors.gold.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: GuoXueColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: GuoXueColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAuthenticated ? '钱包余额' : '登录后查看钱包余额',
                      style: GuoXueTypography.body.copyWith(
                        color: GuoXueColors.inkBlack,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAuthenticated
                          ? '${formatWalletCents(balanceCents)}${phone == null ? '' : ' · $phone'}'
                          : '余额用于 AI 解析扣费，可随时充值。',
                      style: GuoXueTypography.caption.copyWith(
                        color: isAuthenticated
                            ? GuoXueColors.primary
                            : GuoXueColors.inkGray,
                        fontWeight:
                            isAuthenticated ? FontWeight.w700 : FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: isAuthenticated ? onOpenWallet : onLogin,
                child: Text(isAuthenticated ? '充值' : '登录'),
              ),
            ],
          ),
          if (isAuthenticated) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('退出登录'),
                style: TextButton.styleFrom(
                  foregroundColor: GuoXueColors.inkGray,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

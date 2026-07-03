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
        ),
        const SizedBox(height: 10),
        const V2SectionTitle(title: '我的资产'),
        const V2FeatureList(entries: FeatureCatalogV2.mineFeatures),
      ],
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  final bool isAuthenticated;
  final String? phone;
  final int balanceCents;
  final VoidCallback onOpenWallet;
  final VoidCallback onLogin;

  const _WalletBalanceCard({
    required this.isAuthenticated,
    required this.phone,
    required this.balanceCents,
    required this.onOpenWallet,
    required this.onLogin,
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
      child: Row(
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
    );
  }
}

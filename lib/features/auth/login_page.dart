import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import 'auth_store.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStoreProvider);
    ref.listen(authStoreProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/mine');
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('手机号登录')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: GuoXueColors.ricePaper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GuoXueColors.gold.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('账户登录', style: GuoXueTypography.h2),
                const SizedBox(height: 8),
                Text(
                  '登录仅用于识别钱包归属、充值订单和 AI 报告归属。',
                  style: GuoXueTypography.caption.copyWith(
                    color: GuoXueColors.inkGray,
                    height: 1.4,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  key: const Key('login_phone'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: const InputDecoration(
                    labelText: '手机号码',
                    hintText: '请输入 11 位手机号',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('login_send_code'),
                  onPressed: auth.loading ? null : _sendCode,
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('获取验证码'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('login_code'),
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: const InputDecoration(
                    labelText: '短信验证码',
                    hintText: '请输入验证码',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('login_verify_code'),
                  onPressed: auth.loading ? null : _verifyCode,
                  icon: auth.loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(auth.loading ? '处理中' : '登录 / 注册'),
                ),
                if (auth.message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    auth.message!,
                    style: GuoXueTypography.caption.copyWith(
                      color: GuoXueColors.success,
                      letterSpacing: 0,
                    ),
                  ),
                ],
                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    auth.error!,
                    style: GuoXueTypography.caption.copyWith(
                      color: GuoXueColors.error,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCode() async {
    await ref.read(authStoreProvider.notifier).sendCode(
          _phoneController.text.trim(),
        );
  }

  Future<void> _verifyCode() async {
    await ref.read(authStoreProvider.notifier).verifyCode(
          phone: _phoneController.text.trim(),
          code: _codeController.text.trim(),
        );
  }
}

import 'package:flutter/material.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';
import 'guoxue_button.dart';

/// 通用错误页面/组件
class ErrorView extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 64,
              color: GuoXueColors.inkLight,
            ),
            const SizedBox(height: 16),
            Text(message, style: GuoXueTypography.body, textAlign: TextAlign.center),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: GuoXueTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              GuoXueButton(
                label: '重试',
                icon: Icons.refresh,
                primary: false,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

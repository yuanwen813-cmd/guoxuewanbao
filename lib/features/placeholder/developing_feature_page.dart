import 'package:flutter/material.dart';
import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';

/// 开发中 / 即将开放 统一占位页
class DevelopingFeaturePage extends StatelessWidget {
  final String title;
  final String status; // developing | planned
  final String? description;

  const DevelopingFeaturePage({
    super.key,
    required this.title,
    required this.status,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isDeveloping = status == 'beta' || status == 'developing';
    return Scaffold(
      backgroundColor: const Color(0xFF1A1410),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1410),
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDeveloping ? Icons.engineering : Icons.schedule,
                size: 64,
                color: GuoXueColors.gold.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: GuoXueTypography.h2.copyWith(color: GuoXueColors.gold),
              ),
              const SizedBox(height: 12),
              Text(
                isDeveloping ? '功能开发中，即将开放' : '功能规划中，敬请期待',
                style: GuoXueTypography.body.copyWith(color: Colors.white54),
              ),
              if (description != null) ...[
                const SizedBox(height: 16),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: GuoXueTypography.caption.copyWith(color: Colors.white38),
                ),
              ],
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: GuoXueColors.gold.withOpacity(0.3)),
                ),
                child: Text('返回', style: TextStyle(color: GuoXueColors.goldLight)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

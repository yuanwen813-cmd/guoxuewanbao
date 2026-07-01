import 'package:flutter/material.dart';

import '../../app/theme/guoxue_colors.dart';
import '../../app/theme/guoxue_typography.dart';

/// 古风按钮
class GuoXueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;

  const GuoXueButton({
    super.key,
    required this.label,
    this.onPressed,
    this.primary = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final style = primary ? _primaryStyle : _secondaryStyle;

    return ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(label, style: GuoXueTypography.bodyLarge.copyWith(
            color: primary ? GuoXueColors.ricePaper : GuoXueColors.primary,
          )),
        ],
      ),
    );
  }

  static final _primaryStyle = ElevatedButton.styleFrom(
    backgroundColor: GuoXueColors.primary,
    foregroundColor: GuoXueColors.ricePaper,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static final _secondaryStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: GuoXueColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: GuoXueColors.primary),
    ),
  );
}

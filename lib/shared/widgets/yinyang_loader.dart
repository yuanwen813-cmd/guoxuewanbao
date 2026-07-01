import 'package:flutter/material.dart';

import '../../app/theme/guoxue_colors.dart';

/// 阴阳旋转加载动画
class YinYangLoader extends StatefulWidget {
  final double size;

  const YinYangLoader({super.key, this.size = 48});

  @override
  State<YinYangLoader> createState() => _YinYangLoaderState();
}

class _YinYangLoaderState extends State<YinYangLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.rotate(
        angle: _controller.value * 3.14159 * 2,
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _YinYangPainter(),
        ),
      ),
    );
  }
}

class _YinYangPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 外圆
    final bgPaint = Paint()
      ..color = GuoXueColors.inkBlack
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 白色半圆（阴）
    final whitePaint = Paint()..color = GuoXueColors.ricePaper;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14159 / 2, 3.14159, true, whitePaint,
    );

    // 小圆点
    canvas.drawCircle(Offset(center.dx, center.dy - radius / 2), radius / 6,
      Paint()..color = GuoXueColors.ricePaper);
    canvas.drawCircle(Offset(center.dx, center.dy + radius / 2), radius / 6,
      Paint()..color = GuoXueColors.inkBlack);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

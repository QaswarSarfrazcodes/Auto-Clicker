import 'package:flutter/material.dart';

/// Paints the faint dotted grid seen behind the click-point overlay
/// (screen 9). Spacing/opacity are constructor params so this stays easy
/// to retune without touching the paint logic.
class DotGridPainter extends CustomPainter {
  const DotGridPainter({
    this.spacing = 24,
    this.dotRadius = 1.1,
    this.dotColor = const Color(0x33FFFFFF),
  });

  final double spacing;
  final double dotRadius;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) =>
      oldDelegate.spacing != spacing ||
      oldDelegate.dotRadius != dotRadius ||
      oldDelegate.dotColor != dotColor;
}

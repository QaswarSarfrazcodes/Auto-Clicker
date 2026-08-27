import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Live preview canvas for swipe parameters screen (§14).
/// Renders a phone-shaped frame containing a directional arrow
/// from [start] to [end], updating in real time as the user types coordinates.
class SwipePreviewCanvas extends StatelessWidget {
  const SwipePreviewCanvas({
    super.key,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    this.durationMs = 300,
  });

  /// Raw pixel coordinates in "script space" (device screen resolution).
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final int durationMs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Phone silhouette guide lines
          Center(
            child: Container(
              width: 90,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGray, width: 2),
              ),
            ),
          ),
          // Swipe path painter
          CustomPaint(
            size: const Size(double.infinity, 200),
            painter: _SwipePainter(
              startX: startX,
              startY: startY,
              endX: endX,
              endY: endY,
            ),
          ),
          // Duration label
          Positioned(
            bottom: 8,
            right: 12,
            child: Text(
              '${durationMs}ms',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipePainter extends CustomPainter {
  const _SwipePainter({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });

  final double startX;
  final double startY;
  final double endX;
  final double endY;

  // Reference coordinate space — matches typical Android device resolution.
  static const double _refW = 1080;
  static const double _refH = 2400;

  @override
  void paint(Canvas canvas, Size size) {
    // Map script coords into the canvas bounds.
    final scaleX = size.width / _refW;
    final scaleY = size.height / _refH;

    final p1 = Offset(startX * scaleX, startY * scaleY);
    final p2 = Offset(endX * scaleX, endY * scaleY);

    final linePaint = Paint()
      ..color = AppColors.primaryBlue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startDotPaint = Paint()..color = AppColors.primaryBlue;
    final endDotPaint = Paint()..color = AppColors.accentOrange;

    // Gradient dashed line
    canvas.drawLine(p1, p2, linePaint);

    // Start dot
    canvas.drawCircle(p1, 7, startDotPaint);

    // Arrowhead at end
    if ((p2 - p1).distance > 8) {
      final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
      const arrowLen = 12.0;
      const arrowAngle = 0.45;

      final arrowPath = Path()
        ..moveTo(p2.dx, p2.dy)
        ..lineTo(
          p2.dx - arrowLen * math.cos(angle - arrowAngle),
          p2.dy - arrowLen * math.sin(angle - arrowAngle),
        )
        ..moveTo(p2.dx, p2.dy)
        ..lineTo(
          p2.dx - arrowLen * math.cos(angle + arrowAngle),
          p2.dy - arrowLen * math.sin(angle + arrowAngle),
        );

      canvas.drawPath(arrowPath, linePaint);
    }

    // End dot
    canvas.drawCircle(p2, 6, endDotPaint);
  }

  @override
  bool shouldRepaint(covariant _SwipePainter old) =>
      old.startX != startX ||
      old.startY != startY ||
      old.endX != endX ||
      old.endY != endY;
}

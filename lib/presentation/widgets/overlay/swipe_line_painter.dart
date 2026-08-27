import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Paints an interactive line between the start and end swipe points.
/// Adds arrow heads to show direction.
class SwipeLinePainter extends CustomPainter {
  SwipeLinePainter({
    required this.startPoint,
    this.endPoint,
    this.animationValue = 1.0,
  });

  final Offset startPoint;
  final Offset? endPoint;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (endPoint == null) return;

    final paint = Paint()
      ..color = AppColors.primaryBlue.withValues(alpha: 0.6)
      ..strokeWidth = 40
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);
    
    // Draw the line with animation
    final currentEnd = Offset(
      startPoint.dx + (endPoint!.dx - startPoint.dx) * animationValue,
      startPoint.dy + (endPoint!.dy - startPoint.dy) * animationValue,
    );
    path.lineTo(currentEnd.dx, currentEnd.dy);

    canvas.drawPath(path, paint);

    // Draw directional arrows
    _drawArrows(canvas, startPoint, currentEnd);
  }

  void _drawArrows(Canvas canvas, Offset start, Offset end) {
    final distance = (end - start).distance;
    if (distance < 60) return; // Too short for arrows

    final arrowPaint = Paint()
      ..color = AppColors.primaryBlue.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..style = PaintingStyle.fill;

    // Place an arrow in the middle
    final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    
    canvas.save();
    canvas.translate(midPoint.dx, midPoint.dy);
    
    // Calculate rotation angle properly
    final rotAngle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    canvas.rotate(rotAngle);

    final arrowPath = Path();
    arrowPath.moveTo(10, 0);
    arrowPath.lineTo(-10, 10);
    arrowPath.lineTo(-5, 0);
    arrowPath.lineTo(-10, -10);
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SwipeLinePainter oldDelegate) {
    return startPoint != oldDelegate.startPoint ||
        endPoint != oldDelegate.endPoint ||
        animationValue != oldDelegate.animationValue;
  }
}

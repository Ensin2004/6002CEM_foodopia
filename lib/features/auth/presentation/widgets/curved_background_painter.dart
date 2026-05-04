import 'package:flutter/material.dart';

/// Defines behavior for curved background painter.
class CurvedBackgroundPainter extends CustomPainter {
  final Color backgroundColor;
  final Color curveColor;

  /// Creates a curved background painter instance.
  const CurvedBackgroundPainter({
    required this.backgroundColor,
    required this.curveColor,
  });

  /// Handles the paint operation.
  @override
  void paint(Canvas canvas, Size size) {
    // Paint for the solid background
    final bgPaint = Paint()..color = backgroundColor;

    // Paint for the curved shape
    final curvePaint = Paint()..color = curveColor;

    // Draw the full background rectangle
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Define the path for the curve
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height,
      0,
      size.height * 0.75,
    );
    path.close();

    // Draw the curved shape
    canvas.drawPath(path, curvePaint);
  }

  /// Handles the should repaint operation.
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

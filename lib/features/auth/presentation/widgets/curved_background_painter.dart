import 'package:flutter/material.dart';

/// Defines behavior for curved background painter.
/// Draws a solid background with a curved bottom shape overlay.
class CurvedBackgroundPainter extends CustomPainter {
  /// Background color of the top section.
  final Color backgroundColor;

  /// Color of the curved bottom section.
  final Color curveColor;

  /// Creates a curved background painter instance.
  const CurvedBackgroundPainter({
    required this.backgroundColor,
    required this.curveColor,
  });

  /// Handles the paint operation.
  @override
  void paint(Canvas canvas, Size size) {
    // Paint for the solid background.
    final bgPaint = Paint()..color = backgroundColor;

    // Paint for the curved shape.
    final curvePaint = Paint()..color = curveColor;

    // Draw the full background rectangle.
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Define the path for the curve.
    final path = Path();

    // Start from top-left.
    path.moveTo(0, 0);

    // Draw top edge to top-right.
    path.lineTo(size.width, 0);

    // Draw right edge down to the curve start point.
    path.lineTo(size.width, size.height * 0.75);

    // Draw the quadratic bezier curve to bottom-left.
    path.quadraticBezierTo(
      size.width * 0.5,   // Control point at half width, full height.
      size.height,        // Control point y at full height.
      0,                  // End point x at 0.
      size.height * 0.75, // End point y at 75% height.
    );

    // Close the path back to top-left.
    path.close();

    // Draw the curved shape.
    canvas.drawPath(path, curvePaint);
  }

  /// Handles the should repaint operation.
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
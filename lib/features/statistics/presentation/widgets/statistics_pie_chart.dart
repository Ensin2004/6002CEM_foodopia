import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';

class StatisticsPieChartSegment {
  final String label;
  final int value;
  final Color color;

  const StatisticsPieChartSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

class StatisticsPieChart extends StatelessWidget {
  final List<StatisticsPieChartSegment> segments;
  final String centerTitle;
  final String centerValue;
  final double size;

  const StatisticsPieChart({
    super.key,
    required this.segments,
    required this.centerTitle,
    required this.centerValue,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _StatisticsPieChartPainter(segments: segments),
          ),
          Container(
            width: size * 0.36,
            height: size * 0.36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerTitle,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    centerValue,
                    style: context.text.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsPieChartPainter extends CustomPainter {
  final List<StatisticsPieChartSegment> segments;

  _StatisticsPieChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.value);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.29;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final segmentPaint = Paint()..style = PaintingStyle.fill;
    final dividerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * math.pi * 2;
      segmentPaint.color = segment.color;
      canvas.drawArc(rect, startAngle, sweepAngle, true, segmentPaint);
      canvas.drawArc(rect, startAngle, sweepAngle, true, dividerPaint);

      final midAngle = startAngle + sweepAngle / 2;
      _drawLeader(
        canvas: canvas,
        size: size,
        center: center,
        radius: radius,
        angle: midAngle,
        color: segment.color,
        label: segment.label,
      );

      startAngle += sweepAngle;
    }
  }

  void _drawLeader({
    required Canvas canvas,
    required Size size,
    required Offset center,
    required double radius,
    required double angle,
    required Color color,
    required String label,
  }) {
    final isRight = math.cos(angle) >= 0;
    final leaderPaint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final pointOnArc = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    final outerPoint = Offset(
      center.dx + math.cos(angle) * (radius + 19),
      center.dy + math.sin(angle) * (radius + 19),
    );
    final endPoint = Offset(isRight ? size.width - 31 : 31, outerPoint.dy);

    canvas.drawLine(pointOnArc, outerPoint, leaderPaint);
    canvas.drawLine(outerPoint, endPoint, leaderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label.replaceFirst(' ', '\n'),
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 8,
          height: 1.05,
          fontWeight: FontWeight.w500,
        ),
      ),
      textAlign: isRight ? TextAlign.left : TextAlign.right,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: 46);

    final labelOffset = Offset(
      isRight ? endPoint.dx + 4 : endPoint.dx - textPainter.width - 4,
      endPoint.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(covariant _StatisticsPieChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

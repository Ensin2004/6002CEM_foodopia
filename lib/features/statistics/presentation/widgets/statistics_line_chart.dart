import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';

class StatisticsLineChartPoint {
  final String label;
  final int value;

  const StatisticsLineChartPoint({required this.label, required this.value});
}

class StatisticsLineChart extends StatelessWidget {
  final List<StatisticsLineChartPoint> points;
  final int? maxValue;
  final double height;
  final Color color;

  const StatisticsLineChart({
    super.key,
    required this.points,
    this.maxValue,
    this.height = 220,
    this.color = const Color(0xFF65C8F4),
  });

  @override
  Widget build(BuildContext context) {
    final highestValue = maxValue ?? _niceMaxValue(points);
    final gridValues = _gridValues(highestValue);

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: gridValues
                        .map(
                          (value) => Text(
                            value.toString(),
                            style: context.text.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomPaint(
                    painter: _StatisticsLineChartPainter(
                      points: points,
                      maxValue: highestValue,
                      gridValues: gridValues,
                      color: color,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 36),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: points
                      .map(
                        (point) => Expanded(
                          child: Text(
                            point.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _niceMaxValue(List<StatisticsLineChartPoint> points) {
    final maxPointValue = points.fold<int>(
      0,
      (max, point) => math.max(max, point.value),
    );
    if (maxPointValue <= 0) return 4;
    if (maxPointValue <= 4) return 4;
    if (maxPointValue <= 10) return 10;
    if (maxPointValue <= 20) return 20;
    if (maxPointValue <= 40) return 40;
    if (maxPointValue <= 100) return 100;
    return ((maxPointValue / 50).ceil()) * 50;
  }

  List<int> _gridValues(int highestValue) {
    final step = (highestValue / 4).round();
    return List.generate(5, (index) => highestValue - (step * index));
  }
}

class _StatisticsLineChartPainter extends CustomPainter {
  final List<StatisticsLineChartPoint> points;
  final int maxValue;
  final List<int> gridValues;
  final Color color;

  _StatisticsLineChartPainter({
    required this.points,
    required this.maxValue,
    required this.gridValues,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || maxValue <= 0) return;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    for (var index = 0; index < gridValues.length; index++) {
      final y = size.height * index / (gridValues.length - 1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final pointOffsets = <Offset>[];
    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * index / (points.length - 1);
      final y = size.height - (points[index].value / maxValue) * size.height;
      pointOffsets.add(Offset(x, y.clamp(2.0, size.height - 2)));
    }

    final linePath = _smoothPath(pointOffsets);
    final fillPath = Path.from(linePath)
      ..lineTo(pointOffsets.last.dx, size.height)
      ..lineTo(pointOffsets.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 0; index < points.length - 1; index++) {
      final current = points[index];
      final next = points[index + 1];
      final controlOffset = (next.dx - current.dx) * 0.45;
      path.cubicTo(
        current.dx + controlOffset,
        current.dy,
        next.dx - controlOffset,
        next.dy,
        next.dx,
        next.dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _StatisticsLineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.color != color;
  }
}

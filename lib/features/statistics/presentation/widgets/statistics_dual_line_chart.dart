// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';

/// One x-axis point with two values to compare.
// Handles StatisticsDualLinePoint for this part of the statistics page.
class StatisticsDualLinePoint {
  final String label;
  final int firstValue;
  final int secondValue;

  // Handles StatisticsDualLinePoint for this part of the statistics page.
  const StatisticsDualLinePoint({
    required this.label,
    required this.firstValue,
    required this.secondValue,
  });
}

/// One named line used by the multi-line chart.
// Handles StatisticsLineChartSeries for this part of the statistics page.
class StatisticsLineChartSeries {
  final String label;
  final Color color;
  final List<int> values;

  // Handles StatisticsLineChartSeries for this part of the statistics page.
  const StatisticsLineChartSeries({
    required this.label,
    required this.color,
    required this.values,
  });
}

/// Draws several data lines on the same chart for comparison.
// Handles StatisticsMultiLineChart for this part of the statistics page.
class StatisticsMultiLineChart extends StatelessWidget {
  final List<String> labels;
  final List<StatisticsLineChartSeries> series;
  final double height;

  // Handles StatisticsMultiLineChart for this part of the statistics page.
  const StatisticsMultiLineChart({
    super.key,
    required this.labels,
    required this.series,
    this.height = 220,
  });

  // Handles build for this part of the statistics page.
  @override
  Widget build(BuildContext context) {
    final maxValue = _niceMaxValue(series);
    final gridValues = _gridValues(maxValue);

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 34,
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
                // Handles SizedBox for this part of the statistics page.
                const SizedBox(width: 8),
                Expanded(
                  child: CustomPaint(
                    painter: _StatisticsMultiLineChartPainter(
                      labels: labels,
                      series: series,
                      maxValue: maxValue,
                      gridValues: gridValues,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 42),
              Expanded(
                child: Row(
                  children: labels
                      .map(
                        (label) => Expanded(
                          child: Text(
                            label,
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

  // Handles _niceMaxValue for this part of the statistics page.
  int _niceMaxValue(List<StatisticsLineChartSeries> series) {
    final maxPointValue = series.fold<int>(0, (max, item) {
      final seriesMax = item.values.fold<int>(
        0,
        (current, value) => math.max(current, value),
      );
      return math.max(max, seriesMax);
    });
    if (maxPointValue <= 10) return 10;
    if (maxPointValue <= 100) return 100;
    if (maxPointValue <= 500) return 500;
    if (maxPointValue <= 1000) return 1000;
    return ((maxPointValue / 500).ceil()) * 500;
  }

  // Handles _gridValues for this part of the statistics page.
  List<int> _gridValues(int highestValue) {
    final step = (highestValue / 4).round();
    return List.generate(5, (index) => highestValue - (step * index));
  }
}

/// Convenience chart for comparing exactly two related values.
// Handles StatisticsDualLineChart for this part of the statistics page.
class StatisticsDualLineChart extends StatelessWidget {
  final List<StatisticsDualLinePoint> points;
  final Color firstColor;
  final Color secondColor;
  final double height;

  // Handles StatisticsDualLineChart for this part of the statistics page.
  const StatisticsDualLineChart({
    super.key,
    required this.points,
    required this.firstColor,
    required this.secondColor,
    this.height = 220,
  });

  // Handles build for this part of the statistics page.
  @override
  Widget build(BuildContext context) {
    final maxValue = _niceMaxValue(points);
    final gridValues = _gridValues(maxValue);

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 34,
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
                // Handles SizedBox for this part of the statistics page.
                const SizedBox(width: 8),
                Expanded(
                  child: CustomPaint(
                    painter: _StatisticsDualLineChartPainter(
                      points: points,
                      maxValue: maxValue,
                      gridValues: gridValues,
                      firstColor: firstColor,
                      secondColor: secondColor,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 42),
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

  // Handles _niceMaxValue for this part of the statistics page.
  int _niceMaxValue(List<StatisticsDualLinePoint> points) {
    final maxPointValue = points.fold<int>(
      0,
      (max, point) =>
          math.max(max, math.max(point.firstValue, point.secondValue)),
    );
    if (maxPointValue <= 10) return 10;
    if (maxPointValue <= 100) return 100;
    if (maxPointValue <= 500) return 500;
    if (maxPointValue <= 1000) return 1000;
    return ((maxPointValue / 500).ceil()) * 500;
  }

  // Handles _gridValues for this part of the statistics page.
  List<int> _gridValues(int highestValue) {
    final step = (highestValue / 4).round();
    return List.generate(5, (index) => highestValue - (step * index));
  }
}

// Handles _StatisticsMultiLineChartPainter for this part of the statistics page.
class _StatisticsMultiLineChartPainter extends CustomPainter {
  final List<String> labels;
  final List<StatisticsLineChartSeries> series;
  final int maxValue;
  final List<int> gridValues;

  _StatisticsMultiLineChartPainter({
    required this.labels,
    required this.series,
    required this.maxValue,
    required this.gridValues,
  });

  // Handles paint for this part of the statistics page.
  @override
  void paint(Canvas canvas, Size size) {
    if (labels.isEmpty || series.isEmpty || maxValue <= 0) return;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    for (var index = 0; index < gridValues.length; index++) {
      final y = size.height * index / (gridValues.length - 1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (final item in series) {
      _drawSeries(
        canvas: canvas,
        size: size,
        values: item.values,
        color: item.color,
      );
    }
  }

  // Handles _drawSeries for this part of the statistics page.
  void _drawSeries({
    required Canvas canvas,
    required Size size,
    required List<int> values,
    required Color color,
  }) {
    if (values.isEmpty) return;
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final offsets = <Offset>[];
    for (var index = 0; index < labels.length; index++) {
      final x = labels.length == 1
          ? size.width / 2
          : size.width * index / (labels.length - 1);
      final value = index < values.length ? values[index] : 0;
      final y = size.height - (value / maxValue) * size.height;
      offsets.add(Offset(x, y.clamp(0.0, size.height)));
    }

    final path = _smoothPath(offsets);
    canvas.drawPath(path, linePaint);
    for (final offset in offsets) {
      canvas.drawCircle(offset, 3, dotPaint);
    }
  }

  // Handles _smoothPath for this part of the statistics page.
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

  // Handles shouldRepaint for this part of the statistics page.
  @override
  bool shouldRepaint(covariant _StatisticsMultiLineChartPainter oldDelegate) {
    return oldDelegate.labels != labels ||
        oldDelegate.series != series ||
        oldDelegate.maxValue != maxValue;
  }
}

// Handles _StatisticsDualLineChartPainter for this part of the statistics page.
class _StatisticsDualLineChartPainter extends CustomPainter {
  final List<StatisticsDualLinePoint> points;
  final int maxValue;
  final List<int> gridValues;
  final Color firstColor;
  final Color secondColor;

  _StatisticsDualLineChartPainter({
    required this.points,
    required this.maxValue,
    required this.gridValues,
    required this.firstColor,
    required this.secondColor,
  });

  // Handles paint for this part of the statistics page.
  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || maxValue <= 0) return;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    for (var index = 0; index < gridValues.length; index++) {
      final y = size.height * index / (gridValues.length - 1);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawSeries(
      canvas: canvas,
      size: size,
      values: points.map((point) => point.firstValue).toList(),
      color: firstColor,
    );
    _drawSeries(
      canvas: canvas,
      size: size,
      values: points.map((point) => point.secondValue).toList(),
      color: secondColor,
    );
  }

  // Handles _drawSeries for this part of the statistics page.
  void _drawSeries({
    required Canvas canvas,
    required Size size,
    required List<int> values,
    required Color color,
  }) {
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final offsets = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final y = size.height - (values[index] / maxValue) * size.height;
      offsets.add(Offset(x, y.clamp(0.0, size.height)));
    }

    final path = _smoothPath(offsets);
    canvas.drawPath(path, linePaint);
    for (final offset in offsets) {
      canvas.drawCircle(offset, 3.5, dotPaint);
    }
  }

  // Handles _smoothPath for this part of the statistics page.
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

  // Handles shouldRepaint for this part of the statistics page.
  @override
  bool shouldRepaint(covariant _StatisticsDualLineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.firstColor != firstColor ||
        oldDelegate.secondColor != secondColor;
  }
}

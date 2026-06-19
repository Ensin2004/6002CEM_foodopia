// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';
import 'statistics_recipe_media_thumbnail.dart';

/// One value displayed by [StatisticsBarChart].
// Handles StatisticsBarChartItem for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class StatisticsBarChartItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String? imageUrl;
  final String? markerText;
  final Color? markerIconColor;

  // Handles StatisticsBarChartItem for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const StatisticsBarChartItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.imageUrl,
    this.markerText,
    this.markerIconColor,
  });
}

/// Small reusable bar chart used by the statistics detail pages.
// Handles StatisticsBarChart for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class StatisticsBarChart extends StatelessWidget {
  final List<StatisticsBarChartItem> items;
  final int? maxValue;
  final double height;

  // Handles StatisticsBarChart for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const StatisticsBarChart({
    super.key,
    required this.items,
    this.maxValue,
    this.height = 190,
  });

  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Widget build(BuildContext context) {
    // BAR CHART BUILDING STARTS HERE.
    // Unlike the pie and line charts, this chart does not use CustomPainter.
    // It creates each bar from normal Flutter Row, Column, and Container widgets.
    // Keep the chart readable on phones by showing at most five bars.
    final visibleItems = _visibleItems(items);
    // Round the highest value so the vertical labels are easy to read.
    final highestValue = maxValue ?? _niceMaxValue(visibleItems);
    final gridValues = _gridValues(highestValue);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const iconRowHeight = 38.0;
          const iconGap = 8.0;
          final plotHeight = constraints.maxHeight - iconRowHeight - iconGap;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    SizedBox(
                      height: plotHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: gridValues
                            .map(
                              (value) => Text(
                                value.toString(),
                                style: context.text.bodySmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    // Handles SizedBox for this part of the statistics page.
                    // This makes the purpose clearer when reading or updating the code.
                    const SizedBox(height: iconGap),
                    const SizedBox(height: iconRowHeight),
                  ],
                ),
              ),
              // Handles SizedBox for this part of the statistics page.
              // This makes the purpose clearer when reading or updating the code.
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: plotHeight,
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              gridValues.length,
                              (_) =>
                                  Container(height: 1, color: AppColors.border),
                            ),
                          ),
                          // EACH VERTICAL BAR STARTS HERE.
                          // Every visible item becomes one Expanded column.
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: visibleItems.map((item) {
                              final ratio = highestValue == 0
                                  ? 0.0
                                  : item.value / highestValue;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: FractionallySizedBox(
                                          heightFactor: ratio.clamp(0.0, 1.0),
                                          alignment: Alignment.bottomCenter,
                                          // This Container is the coloured bar.
                                          // Its height is based on value / highestValue.
                                          child: Container(
                                            width: 30,
                                            decoration: BoxDecoration(
                                              color: item.color,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(8),
                                                    topRight: Radius.circular(
                                                      8,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    // Handles SizedBox for this part of the statistics page.
                    // This makes the purpose clearer when reading or updating the code.
                    const SizedBox(height: iconGap),
                    SizedBox(
                      height: iconRowHeight,
                      child: Row(
                        children: visibleItems
                            .map(
                              (item) => Expanded(
                                child: Tooltip(
                                  message: item.label,
                                  child: Center(
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECE7CF),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFD7C98D),
                                        ),
                                      ),
                                      child: _ChartMarkerContent(item: item),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Handles _niceMaxValue for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  int _niceMaxValue(List<StatisticsBarChartItem> items) {
    // Pick a clean chart limit instead of ending at an uneven value.
    final maxItemValue = items.fold<int>(
      0,
      (max, item) => item.value > max ? item.value : max,
    );
    if (maxItemValue <= 10) return 10;
    if (maxItemValue <= 20) return 20;
    if (maxItemValue <= 40) return 40;
    return ((maxItemValue / 10).ceil()) * 10;
  }

  // Handles _visibleItems for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  List<StatisticsBarChartItem> _visibleItems(
    List<StatisticsBarChartItem> source,
  ) {
    return source.take(5).toList(growable: false);
  }

  // Handles _gridValues for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  List<int> _gridValues(int highestValue) {
    if (highestValue <= 0) return List.filled(5, 0);

    return List.generate(5, (index) {
      final value = highestValue - ((highestValue * index) / 4).round();
      return value.clamp(0, highestValue);
    });
  }
}

// Handles _ChartMarkerContent for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _ChartMarkerContent extends StatelessWidget {
  final StatisticsBarChartItem item;

  const _ChartMarkerContent({required this.item});

  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Widget build(BuildContext context) {
    if (item.imageUrl?.isNotEmpty == true) {
      return StatisticsRecipeMediaThumbnail(
        mediaPath: item.imageUrl,
        fallbackIcon: item.icon,
        size: 34,
        backgroundColor: const Color(0xFFECE7CF),
        iconColor: const Color(0xFF6D642C),
      );
    }

    final text = _markerText(item.markerText);
    if (text.isNotEmpty) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: context.text.bodySmall?.copyWith(
            color: const Color(0xFF6D642C),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Icon(
      item.icon,
      size: 17,
      color: item.markerIconColor ?? const Color(0xFF6D642C),
    );
  }

  // Handles _markerText for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  String _markerText(String? value) {
    final words = value
        ?.trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words == null || words.isEmpty) return '';
    if (words.length == 1) {
      final word = words.first;
      return word.length <= 2
          ? word.toUpperCase()
          : word.substring(0, 2).toUpperCase();
    }
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';

class StatisticsBarChartItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String? imageUrl;
  final String? markerText;

  const StatisticsBarChartItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.imageUrl,
    this.markerText,
  });
}

class StatisticsBarChart extends StatelessWidget {
  final List<StatisticsBarChartItem> items;
  final int? maxValue;
  final double height;

  const StatisticsBarChart({
    super.key,
    required this.items,
    this.maxValue,
    this.height = 190,
  });

  @override
  Widget build(BuildContext context) {
    final highestValue = maxValue ?? _niceMaxValue(items);
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
                    const SizedBox(height: iconGap),
                    const SizedBox(height: iconRowHeight),
                  ],
                ),
              ),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: items.map((item) {
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
                    const SizedBox(height: iconGap),
                    SizedBox(
                      height: iconRowHeight,
                      child: Row(
                        children: items
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

  int _niceMaxValue(List<StatisticsBarChartItem> items) {
    final maxItemValue = items.fold<int>(
      0,
      (max, item) => item.value > max ? item.value : max,
    );
    if (maxItemValue <= 10) return 10;
    if (maxItemValue <= 20) return 20;
    if (maxItemValue <= 40) return 40;
    return ((maxItemValue / 10).ceil()) * 10;
  }

  List<int> _gridValues(int highestValue) {
    if (highestValue <= 0) return List.filled(5, 0);

    return List.generate(5, (index) {
      final value = highestValue - ((highestValue * index) / 4).round();
      return value.clamp(0, highestValue);
    });
  }
}

class _ChartMarkerContent extends StatelessWidget {
  final StatisticsBarChartItem item;

  const _ChartMarkerContent({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.imageUrl?.isNotEmpty == true) {
      return ClipOval(
        child: Image.network(
          item.imageUrl!,
          width: 34,
          height: 34,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) =>
              Icon(item.icon, size: 17, color: const Color(0xFF6D642C)),
        ),
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

    return Icon(item.icon, size: 17, color: const Color(0xFF6D642C));
  }

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

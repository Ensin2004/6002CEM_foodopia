import 'package:flutter/material.dart';

enum StatisticsSortOrder { most, least }

enum FoodAnalyticChartType {
  mealPlanned,
  preparedIngredient,
  categoryMealPrepared,
}

class FoodAnalyticStatistics {
  final String dateRange;
  final int totalDish;
  final int totalMeals;
  final List<FoodAnalyticChart> charts;

  const FoodAnalyticStatistics({
    required this.dateRange,
    required this.totalDish,
    required this.totalMeals,
    required this.charts,
  });
}

class FoodAnalyticChart {
  final String title;
  final FoodAnalyticChartType type;
  final String summaryTitle;
  final int summaryValue;
  final String highlightTitle;
  final String highlightValue;
  final List<FoodAnalyticBarItem> items;

  const FoodAnalyticChart({
    required this.title,
    required this.type,
    required this.summaryTitle,
    required this.summaryValue,
    required this.highlightTitle,
    required this.highlightValue,
    required this.items,
  });

  FoodAnalyticChart sorted(StatisticsSortOrder order) {
    final sortedItems = [...items]
      ..sort(
        (left, right) => order == StatisticsSortOrder.most
            ? right.value.compareTo(left.value)
            : left.value.compareTo(right.value),
      );

    return FoodAnalyticChart(
      title: title,
      type: type,
      summaryTitle: summaryTitle,
      summaryValue: summaryValue,
      highlightTitle: highlightTitle,
      highlightValue: highlightValue,
      items: sortedItems,
    );
  }
}

class FoodAnalyticBarItem {
  final String label;
  final int value;
  final double percent;
  final IconData icon;
  final Color color;
  final String? imageUrl;
  final List<FoodAnalyticDetailItem> details;

  const FoodAnalyticBarItem({
    required this.label,
    required this.value,
    required this.percent,
    required this.icon,
    required this.color,
    this.imageUrl,
    this.details = const [],
  });
}

class FoodAnalyticDetailItem {
  final String name;
  final int quantity;
  final IconData icon;
  final String? imageUrl;

  const FoodAnalyticDetailItem({
    required this.name,
    required this.quantity,
    required this.icon,
    this.imageUrl,
  });
}

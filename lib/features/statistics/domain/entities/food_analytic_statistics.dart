// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';

// Handles StatisticsSortOrder for this part of the statistics page.
enum StatisticsSortOrder { most, least }

enum FoodAnalyticChartType {
  mealPlanned,
  preparedIngredient,
  categoryMealPrepared,
}

// Handles FoodAnalyticStatistics for this part of the statistics page.
class FoodAnalyticStatistics {
  final String dateRange;
  final int totalDish;
  final int totalMeals;
  final List<FoodAnalyticChart> charts;

  // Handles FoodAnalyticStatistics for this part of the statistics page.
  const FoodAnalyticStatistics({
    required this.dateRange,
    required this.totalDish,
    required this.totalMeals,
    required this.charts,
  });
}

// Handles FoodAnalyticChart for this part of the statistics page.
class FoodAnalyticChart {
  final String title;
  final FoodAnalyticChartType type;
  final String summaryTitle;
  final int summaryValue;
  final String highlightTitle;
  final String highlightValue;
  final List<FoodAnalyticBarItem> items;

  // Handles FoodAnalyticChart for this part of the statistics page.
  const FoodAnalyticChart({
    required this.title,
    required this.type,
    required this.summaryTitle,
    required this.summaryValue,
    required this.highlightTitle,
    required this.highlightValue,
    required this.items,
  });

  // Handles sorted for this part of the statistics page.
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

// Handles FoodAnalyticBarItem for this part of the statistics page.
class FoodAnalyticBarItem {
  final String? recipeId;
  final String label;
  final int value;
  final double percent;
  final IconData icon;
  final Color color;
  final String? imageUrl;
  final List<FoodAnalyticDetailItem> details;

  // Handles FoodAnalyticBarItem for this part of the statistics page.
  const FoodAnalyticBarItem({
    this.recipeId,
    required this.label,
    required this.value,
    required this.percent,
    required this.icon,
    required this.color,
    this.imageUrl,
    this.details = const [],
  });
}

// Handles FoodAnalyticDetailItem for this part of the statistics page.
class FoodAnalyticDetailItem {
  final String? recipeId;
  final String name;
  final int quantity;
  final IconData icon;
  final String? imageUrl;

  // Handles FoodAnalyticDetailItem for this part of the statistics page.
  const FoodAnalyticDetailItem({
    this.recipeId,
    required this.name,
    required this.quantity,
    required this.icon,
    this.imageUrl,
  });
}

// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';

// Handles MostCookedRecipeSortOrder for this part of the statistics page.
enum MostCookedRecipeSortOrder { highest, lowest }

class MostCookedRecipeStatistics {
  final String dateRange;
  final int totalUsersPlanToCook;
  final String topPlanToCook;
  final List<MostCookedRecipeItem> recipes;
  final List<MostCookedRecipeDay> days;

  // Handles MostCookedRecipeStatistics for this part of the statistics page.
  const MostCookedRecipeStatistics({
    required this.dateRange,
    required this.totalUsersPlanToCook,
    required this.topPlanToCook,
    required this.recipes,
    this.days = const [],
  });
}

// Handles MostCookedRecipeDay for this part of the statistics page.
class MostCookedRecipeDay {
  final DateTime date;
  final int totalQuantity;
  final List<MostCookedRecipeDayItem> recipes;

  // Handles MostCookedRecipeDay for this part of the statistics page.
  const MostCookedRecipeDay({
    required this.date,
    required this.totalQuantity,
    required this.recipes,
  });
}

// Handles MostCookedRecipeDayItem for this part of the statistics page.
class MostCookedRecipeDayItem {
  final String dishName;
  final int quantity;
  final IconData icon;
  final String? imageUrl;

  // Handles MostCookedRecipeDayItem for this part of the statistics page.
  const MostCookedRecipeDayItem({
    required this.dishName,
    required this.quantity,
    required this.icon,
    this.imageUrl,
  });
}

// Handles MostCookedRecipeItem for this part of the statistics page.
class MostCookedRecipeItem {
  final String dishName;
  final int quantity;
  final IconData icon;
  final Color color;
  final String? imageUrl;
  final List<MostCookedRecipePlanDate> plannedDates;

  // Handles MostCookedRecipeItem for this part of the statistics page.
  const MostCookedRecipeItem({
    required this.dishName,
    required this.quantity,
    required this.icon,
    required this.color,
    this.imageUrl,
    required this.plannedDates,
  });
}

// Handles MostCookedRecipePlanDate for this part of the statistics page.
class MostCookedRecipePlanDate {
  final DateTime date;
  final int plannedTimes;

  // Handles MostCookedRecipePlanDate for this part of the statistics page.
  const MostCookedRecipePlanDate({
    required this.date,
    required this.plannedTimes,
  });
}

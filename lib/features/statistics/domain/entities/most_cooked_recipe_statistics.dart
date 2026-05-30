import 'package:flutter/material.dart';

enum MostCookedRecipeSortOrder { highest, lowest }

class MostCookedRecipeStatistics {
  final String dateRange;
  final int totalUsersPlanToCook;
  final String topPlanToCook;
  final List<MostCookedRecipeItem> recipes;
  final List<MostCookedRecipeDay> days;

  const MostCookedRecipeStatistics({
    required this.dateRange,
    required this.totalUsersPlanToCook,
    required this.topPlanToCook,
    required this.recipes,
    this.days = const [],
  });
}

class MostCookedRecipeDay {
  final DateTime date;
  final int totalQuantity;
  final List<MostCookedRecipeDayItem> recipes;

  const MostCookedRecipeDay({
    required this.date,
    required this.totalQuantity,
    required this.recipes,
  });
}

class MostCookedRecipeDayItem {
  final String dishName;
  final int quantity;
  final IconData icon;
  final String? imageUrl;

  const MostCookedRecipeDayItem({
    required this.dishName,
    required this.quantity,
    required this.icon,
    this.imageUrl,
  });
}

class MostCookedRecipeItem {
  final String dishName;
  final int quantity;
  final IconData icon;
  final Color color;
  final String? imageUrl;
  final List<MostCookedRecipePlanDate> plannedDates;

  const MostCookedRecipeItem({
    required this.dishName,
    required this.quantity,
    required this.icon,
    required this.color,
    this.imageUrl,
    required this.plannedDates,
  });
}

class MostCookedRecipePlanDate {
  final DateTime date;
  final int plannedTimes;

  const MostCookedRecipePlanDate({
    required this.date,
    required this.plannedTimes,
  });
}

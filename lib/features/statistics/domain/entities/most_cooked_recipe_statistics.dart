import 'package:flutter/material.dart';

enum MostCookedRecipeSortOrder { highest, lowest }

class MostCookedRecipeStatistics {
  final String dateRange;
  final int totalUsersPlanToCook;
  final String topPlanToCook;
  final List<MostCookedRecipeItem> recipes;

  const MostCookedRecipeStatistics({
    required this.dateRange,
    required this.totalUsersPlanToCook,
    required this.topPlanToCook,
    required this.recipes,
  });
}

class MostCookedRecipeItem {
  final String dishName;
  final int quantity;
  final IconData icon;
  final Color color;
  final List<MostCookedRecipePlanDate> plannedDates;

  const MostCookedRecipeItem({
    required this.dishName,
    required this.quantity,
    required this.icon,
    required this.color,
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

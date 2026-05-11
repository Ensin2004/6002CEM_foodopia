import 'package:flutter/material.dart';

class AddGroceryListPlan {
  final List<GroceryIconOption> iconOptions;
  final List<GroceryMealDayPlan> mealDays;

  const AddGroceryListPlan({required this.iconOptions, required this.mealDays});
}

class GroceryIconOption {
  final String id;
  final IconData icon;

  const GroceryIconOption({required this.id, required this.icon});
}

class GroceryMealDayPlan {
  final DateTime date;
  final List<GroceryMealSectionPlan> sections;

  const GroceryMealDayPlan({required this.date, required this.sections});
}

class GroceryMealSectionPlan {
  final String title;
  final List<GroceryMealPlanItem> meals;

  const GroceryMealSectionPlan({required this.title, required this.meals});
}

class GroceryMealPlanItem {
  final String id;
  final String title;
  final String imagePath;

  const GroceryMealPlanItem({
    required this.id,
    required this.title,
    required this.imagePath,
  });
}

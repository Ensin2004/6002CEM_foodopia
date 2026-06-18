import 'package:flutter/material.dart';

/// Represents the plan for creating a new grocery list.
/// Contains icon options and meal days with their sections.
class AddGroceryListPlan {
  /// List of available icon options for the grocery list.
  final List<GroceryIconOption> iconOptions;

  /// List of meal days with their associated meals.
  final List<GroceryMealDayPlan> mealDays;

  /// Creates a new grocery list plan instance.
  const AddGroceryListPlan({required this.iconOptions, required this.mealDays});
}

/// Request object for creating a new grocery list.
/// Contains all parameters needed to create a custom grocery list.
class CreateGroceryListRequest {
  /// Unique identifier of the user creating the list.
  final String userId;

  /// Display title of the grocery list.
  final String title;

  /// Identifier of the selected icon for the list.
  final String iconId;

  /// Start date of the grocery list's date range.
  final DateTime startDate;

  /// End date of the grocery list's date range.
  final DateTime endDate;

  /// List of dates to exclude from the grocery list.
  final List<DateTime> excludedDays;

  /// List of meal plan IDs to include in the grocery list.
  final List<String> mealPlanIds;

  /// Creates a new grocery list creation request.
  const CreateGroceryListRequest({
    required this.userId,
    required this.title,
    required this.iconId,
    required this.startDate,
    required this.endDate,
    required this.excludedDays,
    required this.mealPlanIds,
  });
}

/// Represents an icon option for a grocery list.
/// Contains an identifier and the associated icon data.
class GroceryIconOption {
  /// Unique identifier for the icon option.
  final String id;

  /// The icon data to display.
  final IconData icon;

  /// Creates a new grocery icon option.
  const GroceryIconOption({required this.id, required this.icon});
}

/// Represents a day in the grocery meal plan.
/// Contains a date and list of meal sections for that day.
class GroceryMealDayPlan {
  /// The date of this meal day plan.
  final DateTime date;

  /// List of meal sections for this day.
  final List<GroceryMealSectionPlan> sections;

  /// Creates a new grocery meal day plan.
  const GroceryMealDayPlan({required this.date, required this.sections});
}

/// Represents a section of meals within a day.
/// Contains a title and list of meals in that section.
class GroceryMealSectionPlan {
  /// Display title of the meal section.
  final String title;

  /// List of meals in this section.
  final List<GroceryMealPlanItem> meals;

  /// Creates a new grocery meal section plan.
  const GroceryMealSectionPlan({required this.title, required this.meals});
}

/// Represents a single meal item in the grocery plan.
/// Contains the meal ID, title, and image path.
class GroceryMealPlanItem {
  /// Unique identifier of the meal.
  final String id;

  /// Display title of the meal.
  final String title;

  /// Path to the meal's image asset.
  final String imagePath;

  /// Creates a new grocery meal plan item.
  const GroceryMealPlanItem({
    required this.id,
    required this.title,
    required this.imagePath,
  });
}
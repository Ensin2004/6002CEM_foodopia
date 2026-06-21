import '../../domain/entities/meal_plan_dashboard.dart';

/// Model class for meal plan dashboard data.
/// Extends the domain entity with additional serialization capabilities.
class MealPlanDashboardModel extends MealPlanDashboard {
  /// Creates a new dashboard model instance.
  const MealPlanDashboardModel({
    required super.selectedDate,
    required super.weather,
    required super.summary,
    required super.monthDays,
    required super.sections,
    required super.inspirations,
    required super.quickInspirations,
    required super.groceryLists,
    required super.groceryGroups,
  });
}

/// Model class for meal plan weather data.
/// Extends the domain weather entity.
class MealPlanWeatherModel extends MealPlanWeather {
  /// Creates a new weather model instance.
  const MealPlanWeatherModel({
    required super.currentTemp,
    required super.condition,
    required super.summary,
  });
}

/// Model class for meal plan preference summary.
/// Extends the domain preference entity with factory constructors.
class MealPlanPreferenceSummaryModel extends MealPlanPreferenceSummary {
  /// Creates a new preference summary model instance.
  const MealPlanPreferenceSummaryModel({
    required super.diet,
    required super.allergies,
    required super.dislikes,
    super.targetCalories,
    super.calorieUnit,
    super.calorieTargetEnabled,
  });

  /// Creates an empty preference summary with default values.
  factory MealPlanPreferenceSummaryModel.empty() {
    return const MealPlanPreferenceSummaryModel(
      diet: 'Not set',
      allergies: [],
      dislikes: [],
      targetCalories: null,
      calorieUnit: 'kcal',
      calorieTargetEnabled: false,
    );
  }

  /// Creates a preference summary from a JSON map.
  factory MealPlanPreferenceSummaryModel.fromJson(Map<String, dynamic> json) {
    return MealPlanPreferenceSummaryModel(
      diet: json['diet']?.toString() ?? 'Not set',
      allergies: _stringList(json['allergies']),
      dislikes: _stringList(json['dislikes']),
      targetCalories: _intValue(json['targetCalories']),
      calorieUnit: json['calorieUnit']?.toString() ?? 'kcal',
      calorieTargetEnabled: json['calorieTargetEnabled'] == true,
    );
  }

  /// Converts a dynamic value to an integer.
  static int? _intValue(dynamic value) {
    // Numeric Firestore values can arrive as int or double.
    if (value is num) return value.round();

    // String values are accepted for older saved preference documents.
    return int.tryParse(value?.toString() ?? '');
  }

  /// Converts a dynamic value to a list of non-empty strings.
  static List<String> _stringList(dynamic value) {
    // Return empty list if the value is not a list.
    if (value is! List) return const [];

    // Filter out empty strings after trimming.
    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
}

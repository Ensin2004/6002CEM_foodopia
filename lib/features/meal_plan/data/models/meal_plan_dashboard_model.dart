import '../../domain/entities/meal_plan_dashboard.dart';

class MealPlanDashboardModel extends MealPlanDashboard {
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

class MealPlanWeatherModel extends MealPlanWeather {
  const MealPlanWeatherModel({
    required super.currentTemp,
    required super.condition,
    required super.summary,
  });
}

class MealPlanPreferenceSummaryModel extends MealPlanPreferenceSummary {
  const MealPlanPreferenceSummaryModel({
    required super.diet,
    required super.allergies,
    required super.dislikes,
  });

  factory MealPlanPreferenceSummaryModel.empty() {
    return const MealPlanPreferenceSummaryModel(
      diet: 'Not set',
      allergies: [],
      dislikes: [],
    );
  }

  factory MealPlanPreferenceSummaryModel.fromJson(Map<String, dynamic> json) {
    return MealPlanPreferenceSummaryModel(
      diet: json['diet']?.toString() ?? 'Not set',
      allergies: _stringList(json['allergies']),
      dislikes: _stringList(json['dislikes']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
}

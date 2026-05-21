class MealPlanDashboard {
  final DateTime selectedDate;
  final MealPlanWeather? weather;
  final MealPlanSummary summary;
  final List<MealPlanDay> monthDays;
  final List<MealPlanSection> sections;
  final List<MealPlanInspiration> inspirations;
  final List<MealPlanQuickInspiration> quickInspirations;
  final List<GroceryListSummary> groceryLists;
  final List<GroceryListGroup> groceryGroups;

  const MealPlanDashboard({
    required this.selectedDate,
    required this.weather,
    required this.summary,
    required this.monthDays,
    required this.sections,
    required this.inspirations,
    required this.quickInspirations,
    required this.groceryLists,
    required this.groceryGroups,
  });

  MealPlanDashboard copyWith({MealPlanWeather? weather}) {
    return MealPlanDashboard(
      selectedDate: selectedDate,
      weather: weather ?? this.weather,
      summary: summary,
      monthDays: monthDays,
      sections: sections,
      inspirations: inspirations,
      quickInspirations: quickInspirations,
      groceryLists: groceryLists,
      groceryGroups: groceryGroups,
    );
  }
}

class MealPlanWeather {
  final int currentTemp;
  final String condition;
  final String summary;

  const MealPlanWeather({
    required this.currentTemp,
    required this.condition,
    required this.summary,
  });
}

class MealPlanSummary {
  final int pastCount;
  final int todayCount;
  final int futureCount;

  const MealPlanSummary({
    required this.pastCount,
    required this.todayCount,
    required this.futureCount,
  });
}

class MealPlanDay {
  final DateTime date;
  final bool isCurrentMonth;
  final bool hasMeals;

  const MealPlanDay({
    required this.date,
    required this.isCurrentMonth,
    required this.hasMeals,
  });
}

class MealPlanSection {
  final String mealType;
  final List<MealPlanMeal> meals;

  const MealPlanSection({required this.mealType, required this.meals});
}

class MealPlanMeal {
  final String title;
  final String servingLabel;
  final String durationLabel;
  final String imagePath;

  const MealPlanMeal({
    required this.title,
    required this.servingLabel,
    required this.durationLabel,
    required this.imagePath,
  });
}

class MealPlanInspiration {
  final String title;
  final String subtitle;
  final String imagePath;

  const MealPlanInspiration({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}

class MealPlanQuickInspiration {
  final String title;
  final String subtitle;
  final String imagePath;

  const MealPlanQuickInspiration({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}

class MealPlanPreferenceSummary {
  final String diet;
  final List<String> allergies;
  final List<String> dislikes;

  const MealPlanPreferenceSummary({
    required this.diet,
    required this.allergies,
    required this.dislikes,
  });

  String get shortLabel {
    final labels = <String>[];
    if (diet.trim().isNotEmpty) labels.add(diet);
    labels.addAll(allergies.take(2));
    labels.addAll(dislikes.take(1));
    if (labels.isEmpty) return 'Not set';
    return labels.join(', ');
  }
}

class GroceryListGroup {
  final String title;
  final List<String> items;

  const GroceryListGroup({required this.title, required this.items});
}

enum GroceryListStatus { active, past }

class GroceryListSummary {
  final String id;
  final String title;
  final int itemCount;
  final DateTime startDate;
  final DateTime endDate;
  final GroceryListStatus status;
  final bool isDefault;
  final List<String> categories;
  final int extraCategoryCount;

  const GroceryListSummary({
    required this.id,
    required this.title,
    required this.itemCount,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.isDefault = false,
    this.categories = const [],
    this.extraCategoryCount = 0,
  });
}

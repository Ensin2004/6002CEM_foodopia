/// Main dashboard entity for the meal planning screen.
/// Contains all data needed to display the meal plan dashboard.
class MealPlanDashboard {
  /// The currently selected date in the dashboard.
  final DateTime selectedDate;

  /// Weather information for the selected date (optional).
  final MealPlanWeather? weather;

  /// Summary counts for meal plans by date category.
  final MealPlanSummary summary;

  /// List of days in the month for the calendar view.
  final List<MealPlanDay> monthDays;

  /// List of meal sections grouped by meal type.
  final List<MealPlanSection> sections;

  /// List of inspirational meal ideas.
  final List<MealPlanInspiration> inspirations;

  /// List of quick inspirational meal ideas.
  final List<MealPlanQuickInspiration> quickInspirations;

  /// Summary of grocery lists for the user.
  final List<GroceryListSummary> groceryLists;

  /// Groups of grocery lists by category.
  final List<GroceryListGroup> groceryGroups;

  /// Creates a new meal plan dashboard instance.
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

  /// Creates a copy of this dashboard with optional field updates.
  MealPlanDashboard copyWith({
    DateTime? selectedDate,
    MealPlanWeather? weather,
    MealPlanSummary? summary,
    List<MealPlanDay>? monthDays,
    List<MealPlanSection>? sections,
    List<MealPlanInspiration>? inspirations,
    List<MealPlanQuickInspiration>? quickInspirations,
    List<GroceryListSummary>? groceryLists,
    List<GroceryListGroup>? groceryGroups,
  }) {
    return MealPlanDashboard(
      selectedDate: selectedDate ?? this.selectedDate,
      weather: weather ?? this.weather,
      summary: summary ?? this.summary,
      monthDays: monthDays ?? this.monthDays,
      sections: sections ?? this.sections,
      inspirations: inspirations ?? this.inspirations,
      quickInspirations: quickInspirations ?? this.quickInspirations,
      groceryLists: groceryLists ?? this.groceryLists,
      groceryGroups: groceryGroups ?? this.groceryGroups,
    );
  }
}

/// Represents weather information for the meal plan dashboard.
/// Contains temperature, condition, and summary description.
class MealPlanWeather {
  /// Current temperature in degrees Celsius.
  final int currentTemp;

  /// Weather condition description (e.g., sunny, cloudy).
  final String condition;

  /// Human-readable weather summary.
  final String summary;

  /// Creates a new meal plan weather instance.
  const MealPlanWeather({
    required this.currentTemp,
    required this.condition,
    required this.summary,
  });
}

/// Summary statistics for meal plans.
/// Contains counts of past, today's, and future meal plans.
class MealPlanSummary {
  /// Number of meal plans from past dates.
  final int pastCount;

  /// Number of meal plans for today.
  final int todayCount;

  /// Number of meal plans for future dates.
  final int futureCount;

  /// Creates a new meal plan summary instance.
  const MealPlanSummary({
    required this.pastCount,
    required this.todayCount,
    required this.futureCount,
  });
}

/// Represents a single day in the meal plan calendar.
/// Contains date information and whether it has meals.
class MealPlanDay {
  /// Date of this calendar day.
  final DateTime date;

  /// Whether this day belongs to the current month.
  final bool isCurrentMonth;

  /// Whether there are meal plans on this day.
  final bool hasMeals;

  /// Creates a new meal plan day instance.
  const MealPlanDay({
    required this.date,
    required this.isCurrentMonth,
    required this.hasMeals,
  });
}

/// Represents a section of meals grouped by meal type.
/// Contains the meal type and list of meals in that section.
class MealPlanSection {
  /// Display name of the meal type (e.g., Breakfast).
  final String mealType;

  /// Category ID of the meal type.
  final String mealCategoryId;

  /// List of meals in this section.
  final List<MealPlanMeal> meals;

  /// Creates a new meal plan section instance.
  const MealPlanSection({
    required this.mealType,
    this.mealCategoryId = '',
    required this.meals,
  });
}

/// Represents a single meal in the meal plan.
/// Contains basic meal information for display.
class MealPlanMeal {
  /// Unique identifier of the meal plan entry.
  final String id;

  /// ID of the recipe used for this meal.
  final String recipeId;

  /// Source of the meal (e.g., user, AI, saved).
  final String source;

  /// Display title of the meal.
  final String title;

  /// Label showing serving size information.
  final String servingLabel;

  /// Label showing preparation duration.
  final String durationLabel;

  /// Path to the meal's image asset.
  final String imagePath;

  /// Creates a new meal plan meal instance.
  const MealPlanMeal({
    this.id = '',
    this.recipeId = '',
    this.source = '',
    required this.title,
    required this.servingLabel,
    required this.durationLabel,
    required this.imagePath,
  });
}

/// Represents an inspirational meal idea.
/// Contains title, subtitle, and image path.
class MealPlanInspiration {
  /// Display title of the inspiration.
  final String title;

  /// Subtitle or description of the inspiration.
  final String subtitle;

  /// Path to the inspiration's image asset.
  final String imagePath;

  /// Creates a new meal plan inspiration instance.
  const MealPlanInspiration({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}

/// Represents a quick inspirational meal idea.
/// Contains title, subtitle, and image path.
class MealPlanQuickInspiration {
  /// Display title of the quick inspiration.
  final String title;

  /// Subtitle or description of the quick inspiration.
  final String subtitle;

  /// Path to the quick inspiration's image asset.
  final String imagePath;

  /// Creates a new quick inspiration instance.
  const MealPlanQuickInspiration({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}

/// Summary of user's meal preferences.
/// Contains diet type, allergies, and disliked ingredients.
class MealPlanPreferenceSummary {
  /// Diet type (e.g., vegetarian, keto, none).
  final String diet;

  /// List of food allergies.
  final List<String> allergies;

  /// List of disliked ingredients.
  final List<String> dislikes;

  /// Creates a new preference summary instance.
  const MealPlanPreferenceSummary({
    required this.diet,
    required this.allergies,
    required this.dislikes,
  });

  /// Returns a short label summarizing preferences.
  String get shortLabel {
    final labels = <String>[];
    // Add diet if set.
    if (diet.trim().isNotEmpty) labels.add(diet);

    // Add first two allergies.
    labels.addAll(allergies.take(2));

    // Add first disliked item.
    labels.addAll(dislikes.take(1));

    // Return default if no preferences.
    if (labels.isEmpty) return 'Not set';

    // Join labels with comma separator.
    return labels.join(', ');
  }
}

/// Represents a group of grocery lists.
/// Contains a title and list of items in the group.
class GroceryListGroup {
  /// Display title of the group.
  final String title;

  /// List of items in this group.
  final List<String> items;

  /// Creates a new grocery list group instance.
  const GroceryListGroup({required this.title, required this.items});
}

/// Status of a grocery list.
enum GroceryListStatus {
  /// List is currently active and ongoing.
  active,

  /// List has ended and is in the past.
  past,
}

/// Type of grocery list.
enum GroceryListType {
  /// Weekly recurring list.
  weekly,

  /// Custom one-time list.
  custom,
}

/// Summary information for a grocery list.
/// Contains basic list information for display in lists.
class GroceryListSummary {
  /// Unique identifier of the grocery list.
  final String id;

  /// Display title of the list.
  final String title;

  /// Number of items in the list.
  final int itemCount;

  /// Start date of the list's date range.
  final DateTime startDate;

  /// End date of the list's date range.
  final DateTime endDate;

  /// Current status of the list.
  final GroceryListStatus status;

  /// Type of the grocery list.
  final GroceryListType type;

  /// Day of the week the weekly list starts on.
  final String weekStartDay;

  /// Whether this is a default/weekly list.
  final bool isDefault;

  /// List of category names in the list.
  final List<String> categories;

  /// Count of additional categories beyond the main ones.
  final int extraCategoryCount;

  /// Creates a new grocery list summary instance.
  const GroceryListSummary({
    required this.id,
    required this.title,
    required this.itemCount,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.type = GroceryListType.custom,
    this.weekStartDay = 'monday',
    this.isDefault = false,
    this.categories = const [],
    this.extraCategoryCount = 0,
  });

  /// Whether this is a weekly list.
  bool get isWeekly => type == GroceryListType.weekly;
}
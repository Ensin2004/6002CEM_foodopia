class AddMealAiPlan {
  final DateTime planningDate;
  final String mealType;
  final AddMealWeather weather;
  final AddMealPreferenceSnapshot preferences;
  final List<String> ingredientsToInclude;
  final List<String> ingredientsToAvoid;
  final List<String> dishPreferences;
  final List<AddMealAiRecipe> topMatches;
  final List<AddMealAiRecipe> aiIdeas;

  const AddMealAiPlan({
    required this.planningDate,
    required this.mealType,
    required this.weather,
    required this.preferences,
    required this.ingredientsToInclude,
    required this.ingredientsToAvoid,
    required this.dishPreferences,
    required this.topMatches,
    required this.aiIdeas,
  });
}

class AddMealWeather {
  final int temperature;
  final String condition;
  final String summary;

  const AddMealWeather({
    required this.temperature,
    required this.condition,
    required this.summary,
  });
}

class AddMealPreferenceSnapshot {
  final String diet;
  final List<String> allergies;
  final List<String> dislikes;

  const AddMealPreferenceSnapshot({
    required this.diet,
    required this.allergies,
    required this.dislikes,
  });

  bool get hasDiet => diet.trim().isNotEmpty;
  bool get hasDislikes => dislikes.isNotEmpty;
}

class AddMealAiRecipe {
  final String id;
  final String title;
  final String durationLabel;
  final String difficultyLabel;
  final String servingLabel;
  final String imagePath;
  final String description;
  final List<String> reasons;

  const AddMealAiRecipe({
    required this.id,
    required this.title,
    required this.durationLabel,
    required this.difficultyLabel,
    required this.servingLabel,
    required this.imagePath,
    required this.description,
    required this.reasons,
  });
}

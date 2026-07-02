enum AiLifestylePeriod { daily, weekly, monthly }

class AiLifestyleInsight {
  final AiLifestylePeriod period;
  final String dateRangeLabel;
  final String mealPreferenceLabel;
  final int score;
  final int mealCount;
  final int plannedDays;
  final int expectedDays;
  final double totalCalories;
  final double averageDailyCalories;
  final double targetCalories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double fiberGrams;
  final int plantForwardMeals;
  final int higherImpactMeals;
  final String summary;
  final String calorieStatus;
  final String nutritionStatus;
  final String sustainabilityStatus;
  final List<String> recommendations;
  final List<AiLifestyleMealSnapshot> meals;

  const AiLifestyleInsight({
    required this.period,
    required this.dateRangeLabel,
    required this.mealPreferenceLabel,
    required this.score,
    required this.mealCount,
    required this.plannedDays,
    required this.expectedDays,
    required this.totalCalories,
    required this.averageDailyCalories,
    required this.targetCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.fiberGrams,
    required this.plantForwardMeals,
    required this.higherImpactMeals,
    required this.summary,
    required this.calorieStatus,
    required this.nutritionStatus,
    required this.sustainabilityStatus,
    required this.recommendations,
    required this.meals,
  });

  bool get hasMealData => mealCount > 0;

  double get calorieProgress {
    if (targetCalories <= 0) return 0;
    return (averageDailyCalories / targetCalories).clamp(0.0, 1.4);
  }

  double get planningConsistency {
    if (expectedDays <= 0) return 0;
    return (plannedDays / expectedDays).clamp(0.0, 1.0);
  }

  double get sustainabilityProgress {
    if (mealCount <= 0) return 0;
    return (plantForwardMeals / mealCount).clamp(0.0, 1.0);
  }
}

class AiLifestyleMealSnapshot {
  final String title;
  final DateTime date;
  final double servings;
  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final bool plantForward;
  final bool higherImpact;

  const AiLifestyleMealSnapshot({
    required this.title,
    required this.date,
    required this.servings,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.plantForward,
    required this.higherImpact,
  });
}

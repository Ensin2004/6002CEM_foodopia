/// Calorie guidance state for a candidate meal.
enum MealCalorieGuidanceStatus {
  /// No calorie information is available.
  unknown,

  /// Candidate meal fits within the remaining daily target.
  fits,

  /// Candidate meal fits but leaves little remaining budget.
  nearTarget,

  /// Candidate meal exceeds the daily target.
  exceeds,
}

/// Daily calorie budget for meal selection flows.
class MealCalorieBudget {
  /// Calories already planned for the selected day.
  final int plannedCalories;

  /// Daily calorie target.
  final int? targetCalories;

  /// Display unit for calorie values.
  final String calorieUnit;

  /// Whether daily target guidance is enabled.
  final bool targetEnabled;

  /// Creates a new calorie budget snapshot.
  const MealCalorieBudget({
    required this.plannedCalories,
    required this.targetCalories,
    this.calorieUnit = 'kcal',
    this.targetEnabled = false,
  });

  /// Empty budget used when target data is unavailable.
  const MealCalorieBudget.empty()
    : plannedCalories = 0,
      targetCalories = null,
      calorieUnit = 'kcal',
      targetEnabled = false;

  /// Whether an enabled daily target exists.
  bool get hasTarget => targetEnabled && targetCalories != null;
}

/// Guidance details for one candidate meal.
class MealCalorieGuidance {
  /// Guidance status.
  final MealCalorieGuidanceStatus status;

  /// Candidate meal calories in display unit.
  final int mealCalories;

  /// Planned calories before adding the candidate.
  final int plannedCalories;

  /// Planned calories after adding the candidate.
  final int afterAddCalories;

  /// Daily target calories.
  final int? targetCalories;

  /// Remaining calories before adding the candidate.
  final int? remainingCalories;

  /// Calories above target after adding the candidate.
  final int? exceededByCalories;

  /// Display unit for calorie values.
  final String calorieUnit;

  /// Creates a new calorie guidance result.
  const MealCalorieGuidance({
    required this.status,
    required this.mealCalories,
    required this.plannedCalories,
    required this.afterAddCalories,
    required this.targetCalories,
    required this.remainingCalories,
    required this.exceededByCalories,
    required this.calorieUnit,
  });

  /// Short badge label for meal cards.
  String get badgeLabel {
    switch (status) {
      case MealCalorieGuidanceStatus.unknown:
        return 'No calorie data';
      case MealCalorieGuidanceStatus.fits:
        return 'Fits today';
      case MealCalorieGuidanceStatus.nearTarget:
        return 'Near target';
      case MealCalorieGuidanceStatus.exceeds:
        return 'Exceeds by ${exceededByCalories ?? 0} $calorieUnit';
    }
  }

  /// Longer helper text for dialogs and summaries.
  String get helperText {
    switch (status) {
      case MealCalorieGuidanceStatus.unknown:
        return 'Calorie data is missing for this meal.';
      case MealCalorieGuidanceStatus.fits:
        return 'Adding this meal keeps the day within target.';
      case MealCalorieGuidanceStatus.nearTarget:
        return 'Adding this meal fits, with little daily budget left.';
      case MealCalorieGuidanceStatus.exceeds:
        return 'Adding this meal puts the day above target.';
    }
  }
}

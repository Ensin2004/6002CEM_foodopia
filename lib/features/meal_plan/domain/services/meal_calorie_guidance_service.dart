import '../entities/meal_calorie_guidance.dart';

/// Shared calorie guidance rules for meal planning choices.
class MealCalorieGuidanceService {
  /// Near-target threshold as a remaining daily budget ratio.
  static const double nearTargetRemainingRatio = 0.15;

  /// Builds guidance for a candidate meal.
  MealCalorieGuidance evaluate({
    required MealCalorieBudget budget,
    required int mealCalories,
  }) {
    /*
     * Calorie values are compared in the display unit carried by the budget.
     * Stored recipe nutrition is kcal, so conversion happens before evaluation.
     */
    final unit = budget.calorieUnit;
    final displayMealCalories = _displayCalories(mealCalories, unit);
    final displayPlannedCalories = _displayCalories(
      budget.plannedCalories,
      unit,
    );
    final targetCalories = budget.hasTarget ? budget.targetCalories : null;
    final afterAddCalories = displayPlannedCalories + displayMealCalories;

    // Missing candidate calories cannot produce a target decision.
    if (displayMealCalories <= 0) {
      return MealCalorieGuidance(
        status: MealCalorieGuidanceStatus.unknown,
        mealCalories: displayMealCalories,
        plannedCalories: displayPlannedCalories,
        afterAddCalories: afterAddCalories,
        targetCalories: targetCalories,
        remainingCalories: targetCalories == null
            ? null
            : (targetCalories - displayPlannedCalories).clamp(0, 1 << 31),
        exceededByCalories: null,
        calorieUnit: unit,
      );
    }

    // Disabled target still allows calories to be displayed.
    if (targetCalories == null || targetCalories <= 0) {
      return MealCalorieGuidance(
        status: MealCalorieGuidanceStatus.unknown,
        mealCalories: displayMealCalories,
        plannedCalories: displayPlannedCalories,
        afterAddCalories: afterAddCalories,
        targetCalories: null,
        remainingCalories: null,
        exceededByCalories: null,
        calorieUnit: unit,
      );
    }

    // Over-target candidates receive an exceeds badge.
    if (afterAddCalories > targetCalories) {
      return MealCalorieGuidance(
        status: MealCalorieGuidanceStatus.exceeds,
        mealCalories: displayMealCalories,
        plannedCalories: displayPlannedCalories,
        afterAddCalories: afterAddCalories,
        targetCalories: targetCalories,
        remainingCalories: 0,
        exceededByCalories: afterAddCalories - targetCalories,
        calorieUnit: unit,
      );
    }

    final remaining = targetCalories - afterAddCalories;
    final nearThreshold = (targetCalories * nearTargetRemainingRatio).round();
    final status = remaining <= nearThreshold
        ? MealCalorieGuidanceStatus.nearTarget
        : MealCalorieGuidanceStatus.fits;

    return MealCalorieGuidance(
      status: status,
      mealCalories: displayMealCalories,
      plannedCalories: displayPlannedCalories,
      afterAddCalories: afterAddCalories,
      targetCalories: targetCalories,
      remainingCalories: remaining,
      exceededByCalories: null,
      calorieUnit: unit,
    );
  }

  /// Converts stored kcal into the selected display unit.
  int _displayCalories(int kcal, String unit) {
    if (unit.toLowerCase() == 'kj') return (kcal * 4.184).round();
    return kcal;
  }
}

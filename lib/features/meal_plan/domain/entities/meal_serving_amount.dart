/// Helpers for meal-plan serving amounts.
class MealServingAmount {
  /// Smallest serving amount a user can plan.
  static const double min = 0.125;

  /// Largest serving amount a user can plan.
  static const double max = 99;

  /// Common quick-pick serving amounts for shared plates and bigger portions.
  static const List<double> presets = [
    1 / 8,
    1 / 7,
    1 / 6,
    1 / 5,
    1 / 4,
    1 / 3,
    1 / 2,
    1,
    1.5,
    2,
  ];

  const MealServingAmount._();

  /// Keeps a serving amount within the supported planning range.
  static double normalize(double value) {
    if (value.isNaN || value.isInfinite || value <= 0) return 1;
    return value.clamp(min, max).toDouble();
  }

  /// Returns the recipe calories scaled to the selected planned serving amount.
  static int scaledCalories({
    required int recipeCalories,
    required num recipeServings,
    required double plannedServings,
  }) {
    if (recipeCalories <= 0) return 0;
    final baseServings = recipeServings <= 0 ? 1 : recipeServings;
    final scale = normalize(plannedServings) / baseServings;
    return (recipeCalories * scale).round();
  }

  /// Formats a serving amount for compact UI labels.
  static String format(double value) {
    final normalized = normalize(value);
    const tolerance = 0.001;
    if ((normalized - (1 / 8)).abs() < tolerance) return '1/8 serving';
    if ((normalized - (1 / 7)).abs() < tolerance) return '1/7 serving';
    if ((normalized - (1 / 6)).abs() < tolerance) return '1/6 serving';
    if ((normalized - (1 / 5)).abs() < tolerance) return '1/5 serving';
    if ((normalized - (1 / 4)).abs() < tolerance) return '1/4 serving';
    if ((normalized - (1 / 3)).abs() < tolerance) return '1/3 serving';
    if ((normalized - 0.5).abs() < tolerance) return '1/2 serving';
    if ((normalized - normalized.round()).abs() < tolerance) {
      final whole = normalized.round();
      return whole == 1 ? '1 serving' : '$whole servings';
    }
    final text = normalized.toStringAsFixed(1);
    return '$text servings';
  }

  /// Formats a serving amount for Firestore/list display labels.
  static String paxLabel(double value) => '${format(value)} pax';

  /// Returns the next smaller preset/half-step serving amount.
  static double stepDown(double value) {
    final normalized = normalize(value);
    for (final preset in presets.reversed) {
      if (preset < normalized - 0.001) return preset;
    }
    return min;
  }

  /// Returns the next larger preset/half-step serving amount.
  static double stepUp(double value) {
    final normalized = normalize(value);
    for (final preset in presets) {
      if (preset > normalized + 0.001) return preset;
    }
    return normalize(normalized + 0.5);
  }
}

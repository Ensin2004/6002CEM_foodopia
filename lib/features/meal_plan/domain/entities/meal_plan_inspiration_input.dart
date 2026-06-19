/// Represents an ingredient used in meal plan inspiration.
/// Contains identification, name, and source information.
class MealPlanInspirationIngredient {
  /// Unique identifier of the ingredient.
  final String id;

  /// Display name of the ingredient.
  final String name;

  /// USDA food database ID (optional, for standard ingredients).
  final int? usdaId;

  /// Whether this is a custom ingredient added by the user.
  final bool isCustom;

  /// Creates a new inspiration ingredient instance.
  const MealPlanInspirationIngredient({
    required this.id,
    required this.name,
    this.usdaId,
    this.isCustom = false,
  });
}

/// Represents a preference option for meal planning.
/// Contains an identifier and display name.
class MealPlanPreferenceOption {
  /// Unique identifier of the preference option.
  final String id;

  /// Display name of the preference option.
  final String name;

  /// Creates a new preference option instance.
  const MealPlanPreferenceOption({required this.id, required this.name});
}
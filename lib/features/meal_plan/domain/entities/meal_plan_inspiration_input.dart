class MealPlanInspirationIngredient {
  final String id;
  final String name;
  final int? usdaId;
  final bool isCustom;

  const MealPlanInspirationIngredient({
    required this.id,
    required this.name,
    this.usdaId,
    this.isCustom = false,
  });
}

class MealPlanPreferenceOption {
  final String id;
  final String name;

  const MealPlanPreferenceOption({required this.id, required this.name});
}

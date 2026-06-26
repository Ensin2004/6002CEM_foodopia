part of '../../view/planning/generate_ai_meal_page.dart';

/// Recipe result and review card widgets.
///
/// Recipe visuals, macros, badges, reasons, and thumbnails are grouped together.
class _RecipeResultCard extends StatelessWidget {
  /// Recipe data.
  final AddMealAiRecipe recipe;

  /// Creates a new recipe result card instance.
  const _RecipeResultCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Check if recipe is selected.
    final selected = viewModel.isRecipeSelected(recipe.id);

    // Build calorie target guidance for this candidate.
    final guidance = viewModel.calorieGuidanceFor(recipe);

    // Determine border color.
    final borderColor = selected ? AppColors.primary : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFFAF1) : Colors.white,
        border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Recipe header.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _RecipeThumb(recipe: recipe, size: 68),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.title, style: context.text.titleMedium),
                    Text(
                      '${recipe.durationLabel}   ${recipe.difficultyLabel}',
                      style: context.text.bodySmall,
                    ),
                    Text(
                      _nutritionSummary(recipe),
                      style: context.text.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (guidance.status !=
                        MealCalorieGuidanceStatus.unknown) ...[
                      const SizedBox(height: 5),
                      _CalorieGuidanceBadge(guidance: guidance),
                      const SizedBox(height: 5),
                    ],
                    Text(recipe.description, style: context.text.bodySmall),
                  ],
                ),
              ),
              if (selected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Recommendation reasons.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFAF1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why we recommend this:',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ...recipe.reasons.map(
                  (reason) => Text(
                    '- $reason',
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Ingredient alternatives.
          _IngredientAlternativesPreview(recipe: recipe),
          const SizedBox(height: AppSpacing.sm),

          // Select button.
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  onPressed: () {
                    context.read<GenerateAiMealViewModel>().toggleRecipe(
                      recipe.id,
                    );
                  },
                  text: selected ? 'Selected' : 'Select',
                  verticalPadding: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Calorie guidance badge for AI recipe cards.
class _CalorieGuidanceBadge extends StatelessWidget {
  /// Guidance details for the recipe.
  final MealCalorieGuidance guidance;

  /// Creates a new calorie guidance badge instance.
  const _CalorieGuidanceBadge({required this.guidance});

  @override
  Widget build(BuildContext context) {
    if (guidance.status == MealCalorieGuidanceStatus.unknown) {
      return const SizedBox.shrink();
    }

    // Badge color follows the target guidance status.
    final color = switch (guidance.status) {
      MealCalorieGuidanceStatus.exceeds => const Color(0xFFE2762D),
      MealCalorieGuidanceStatus.nearTarget => AppColors.secondary,
      MealCalorieGuidanceStatus.fits => AppColors.primary,
      MealCalorieGuidanceStatus.unknown => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        guidance.badgeLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Review recipe card widget.
class _ReviewRecipeCard extends StatelessWidget {
  /// Recipe data.
  final AddMealAiRecipe recipe;

  /// Creates a new review recipe card instance.
  const _ReviewRecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    // Define macro stats.
    final macros = [
      _MacroStat(
        label: 'Carbs',
        value: recipe.carbohydrates,
        color: AppColors.primary,
      ),
      _MacroStat(label: 'Protein', value: recipe.protein, color: Colors.blue),
      _MacroStat(label: 'Fat', value: recipe.fat, color: AppColors.secondary),
    ];

    // Calculate total macros.
    final totalMacros = macros.fold<double>(0, (sum, item) => sum + item.value);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe image.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: _RecipeThumb(recipe: recipe, size: double.infinity),
                ),
                Positioned(
                  left: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: _ReviewBadge(
                    icon: Icons.local_fire_department_outlined,
                    label: '${recipe.calories} kcal',
                    emphasized: true,
                  ),
                ),
                Positioned(
                  right: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: _CalorieGuidanceBadge(
                    guidance: context
                        .read<GenerateAiMealViewModel>()
                        .calorieGuidanceFor(recipe),
                  ),
                ),
              ],
            ),
          ),

          // Recipe details.
          Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  recipe.title,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  recipe.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(height: 1.35),
                ),
                const SizedBox(height: AppSpacing.md),

                // Badges.
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _ReviewBadge(
                      icon: Icons.schedule,
                      label: recipe.durationLabel,
                    ),
                    _ReviewBadge(
                      icon: Icons.signal_cellular_alt,
                      label: recipe.difficultyLabel,
                    ),
                    _ReviewBadge(
                      icon: Icons.room_service_outlined,
                      label: recipe.servingLabel,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Macro summary.
                Row(
                  children: [
                    for (final macro in macros) ...[
                      Expanded(
                        child: _MacroSummaryItem(
                          label: macro.label,
                          value: macro.value,
                          color: macro.color,
                        ),
                      ),
                      if (macro != macros.last)
                        const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Macro progress bar.
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Row(
                    children: [
                      for (final macro in macros)
                        Expanded(
                          flex: totalMacros <= 0
                              ? 1
                              : (macro.value / totalMacros * 100).round().clamp(
                                  1,
                                  100,
                                ),
                          child: Container(height: 8, color: macro.color),
                        ),
                    ],
                  ),
                ),

                // Reasons.
                if (recipe.reasons.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Why this fits',
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final reason in recipe.reasons.take(3))
                        _ReasonChip(reason: reason),
                    ],
                  ),
                ],
                if (_hasAlternatives(recipe)) ...[
                  const SizedBox(height: AppSpacing.md),
                  _IngredientAlternativesPreview(recipe: recipe),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ingredient alternatives preview widget.
class _IngredientAlternativesPreview extends StatelessWidget {
  /// Recipe data.
  final AddMealAiRecipe recipe;

  /// Creates a new ingredient alternatives preview instance.
  const _IngredientAlternativesPreview({required this.recipe});

  @override
  Widget build(BuildContext context) {
    // Keep only ingredients with actual alternative values.
    final ingredients = recipe.ingredients
        .where((item) => item.alternatives.isNotEmpty)
        .take(3)
        .toList();

    if (ingredients.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingredient alternatives',
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final ingredient in ingredients)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${ingredient.name}: ${ingredient.alternatives.join(', ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Checks whether a recipe contains ingredient alternatives.
bool _hasAlternatives(AddMealAiRecipe recipe) {
  return recipe.ingredients.any((item) => item.alternatives.isNotEmpty);
}

/// Macro stat data class.
class _MacroStat {
  /// Label text.
  final String label;

  /// Value.
  final double value;

  /// Color.
  final Color color;

  /// Creates a new macro stat instance.
  const _MacroStat({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Review badge widget.
class _ReviewBadge extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Label text.
  final String label;

  /// Whether to emphasize the badge.
  final bool emphasized;

  /// Creates a new review badge instance.
  const _ReviewBadge({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine foreground color.
    final foreground = emphasized ? Colors.white : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized ? AppColors.primary : const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(8),
        border: emphasized ? null : Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Macro summary item widget.
class _MacroSummaryItem extends StatelessWidget {
  /// Label text.
  final String label;

  /// Value.
  final double value;

  /// Color.
  final Color color;

  /// Creates a new macro summary item instance.
  const _MacroSummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_macroValue(value)}g',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reason chip widget.
class _ReasonChip extends StatelessWidget {
  /// Reason text.
  final String reason;

  /// Creates a new reason chip instance.
  const _ReasonChip({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
      ),
      child: Text(
        reason,
        style: context.text.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Builds a nutrition summary string.
String _nutritionSummary(AddMealAiRecipe recipe) {
  final macros = [
    '${recipe.calories} kcal',
    'C ${_macroValue(recipe.carbohydrates)}g',
    'P ${_macroValue(recipe.protein)}g',
    'F ${_macroValue(recipe.fat)}g',
  ];
  return macros.join(' | ');
}

/// Formats a macro value with appropriate decimal places.
String _macroValue(double value) {
  return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
}

/// Date scroller widget.

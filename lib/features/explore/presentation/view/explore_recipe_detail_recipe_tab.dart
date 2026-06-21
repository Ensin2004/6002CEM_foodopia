part of 'explore_recipe_detail_page.dart';

/// Tab widget that displays the recipe details including description,
/// other names, category, allergen info, and the ingredients/instructions sections.
class _RecipeTab extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final VoidCallback onComingSoonTap;
  final VoidCallback onPlanMeal;
  final bool showPlanMeal;
  final MealCalorieGuidance? calorieGuidance;

  const _RecipeTab({
    required this.viewModel,
    required this.recipe,
    required this.onComingSoonTap,
    required this.onPlanMeal,
    required this.showPlanMeal,
    required this.calorieGuidance,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe description section.
        Text('About This Recipe', style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(recipe.description, style: textTheme.bodyMedium),
        const SizedBox(height: 14),
        // Other names section.
        Text('Other Names', style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          recipe.otherNames.isEmpty ? 'None' : recipe.otherNames.join(', '),
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        // Category section.
        Text('Category', style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(recipe.category, style: textTheme.bodyMedium),
        const SizedBox(height: 14),
        // Allergen info section with warning icon.
        Row(
          children: [
            Text('Allergen Info', style: textTheme.titleMedium),
            const SizedBox(width: 4),
            const Icon(Icons.warning_amber, size: 15, color: AppColors.error),
          ],
        ),
        const SizedBox(height: 6),
        Text(recipe.allergenInfo, style: textTheme.bodyMedium),
        const SizedBox(height: 14),
        // Segmented control for switching between ingredients and instructions.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPillSegmentedControl(
              labels: const ['Ingredients', 'Instructions'],
              selectedIndex: ExploreRecipeMethodTab.values.indexOf(
                viewModel.selectedMethodTab,
              ),
              onChanged: (index) => viewModel.selectMethodTab(
                ExploreRecipeMethodTab.values[index],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Render the appropriate content based on the selected method tab.
        if (viewModel.selectedMethodTab == ExploreRecipeMethodTab.ingredients)
          _IngredientsList(
            recipe: recipe,
            unitSystem: viewModel.selectedUnitSystem,
            onUnitSystemChanged: viewModel.selectUnitSystem,
            onPlanMeal: onPlanMeal,
            showPlanMeal: showPlanMeal,
            calorieGuidance: calorieGuidance,
          )
        else
          _InstructionsList(recipe: recipe),
      ],
    );
  }
}

/// Widget that displays the ingredients list with category grouping,
/// unit system selection, and meal plan button.
class _IngredientsList extends StatelessWidget {
  final ExploreRecipe recipe;
  final ExploreRecipeUnitSystem unitSystem;
  final ValueChanged<ExploreRecipeUnitSystem> onUnitSystemChanged;
  final VoidCallback onPlanMeal;
  final bool showPlanMeal;
  final MealCalorieGuidance? calorieGuidance;

  const _IngredientsList({
    required this.recipe,
    required this.unitSystem,
    required this.onUnitSystemChanged,
    required this.onPlanMeal,
    required this.showPlanMeal,
    required this.calorieGuidance,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final colors = context.colors;
    // Group ingredients by their category for organized display.
    final ingredientGroups = _groupIngredientsByCategory(recipe.ingredients);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row with title and unit system dropdown.
        Row(
          children: [
            Expanded(
              child: Text('Ingredients List', style: textTheme.titleMedium),
            ),
            const SizedBox(width: 12),
            _UnitSystemDropdown(
              selectedUnitSystem: unitSystem,
              onChanged: onUnitSystemChanged,
            ),
          ],
        ),
        Text('${recipe.ingredients.length} items', style: textTheme.bodyMedium),
        const SizedBox(height: 10),
        // Render ingredient groups with category headers.
        ...ingredientGroups.expand(
          (group) => <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 8),
              child: Text(
                group.name,
                style: textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ...group.ingredients.map(
              (ingredient) => _IngredientListItem(
                ingredient: ingredient,
                unitSystem: unitSystem,
              ),
            ),
          ],
        ),
        if (showPlanMeal || calorieGuidance != null) ...[
          const SizedBox(height: 18),
          if (calorieGuidance != null) ...[
            _ExploreCalorieGuidanceBox(guidance: calorieGuidance!),
            const SizedBox(height: 10),
          ],
          if (showPlanMeal)
            PrimaryButton(
              onPressed: onPlanMeal,
              text:
                  'Plan a meal (Total Calorie: ${recipe.nutrition.calories} kcal)',
              verticalPadding: 14,
            ),
        ],
      ],
    );
  }
}

/// Widget that displays the step-by-step cooking instructions
/// with timeline markers and step thumbnails.
class _InstructionsList extends StatelessWidget {
  final ExploreRecipe recipe;

  const _InstructionsList({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recipe.instructionSections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section title.
              Text(
                section.title,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              // Render each step with timeline marker.
              ...section.steps.asMap().entries.map((entry) {
                final stepIndex = entry.key;
                final step = entry.value;
                final isLast = stepIndex == section.steps.length - 1;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: stepIndex == section.steps.length - 1 ? 0 : 10,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vertical timeline dot and line.
                        _InstructionTimelineMarker(showLine: !isLast),
                        const SizedBox(width: 12),
                        // Step content card with thumbnail and text.
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _RecipeDetailThumbnail(
                                    imagePath: step.imagePath,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step.title,
                                        style: textTheme.labelLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        step.description,
                                        style: textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Timeline marker widget with a circle and optional dotted line
/// connecting to the next step.
/// Calorie guidance box for existing recipe planning.
class _ExploreCalorieGuidanceBox extends StatelessWidget {
  /// Guidance details for the selected recipe.
  final MealCalorieGuidance guidance;

  /// Creates a new explore calorie guidance box instance.
  const _ExploreCalorieGuidanceBox({required this.guidance});

  @override
  Widget build(BuildContext context) {
    // Guidance color matches the candidate status.
    final color = switch (guidance.status) {
      MealCalorieGuidanceStatus.exceeds => const Color(0xFFE2762D),
      MealCalorieGuidanceStatus.nearTarget => AppColors.secondary,
      MealCalorieGuidanceStatus.fits => AppColors.primary,
      MealCalorieGuidanceStatus.unknown => AppColors.textSecondary,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_outlined, color: color, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${guidance.mealCalories} ${guidance.calorieUnit} - '
              '${guidance.badgeLabel}',
              style: context.text.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionTimelineMarker extends StatelessWidget {
  final bool showLine;

  const _InstructionTimelineMarker({required this.showLine});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 24,
      child: Column(
        children: [
          CircleAvatar(radius: 11, backgroundColor: colors.primary),
          if (showLine) const Expanded(child: _DottedTimelineLine()),
        ],
      ),
    );
  }
}

/// Custom painter that draws a dotted vertical line for the timeline.
class _DottedTimelineLine extends StatelessWidget {
  const _DottedTimelineLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedTimelineLinePainter(color: context.colors.primary),
      child: const SizedBox(width: 1, height: double.infinity),
    );
  }
}

/// Painter implementation for the dotted timeline line.
class _DottedTimelineLinePainter extends CustomPainter {
  final Color color;

  const _DottedTimelineLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const dashHeight = 3.0;
    const gap = 4.0;
    final x = size.width / 2;

    double y = 4;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), paint);
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedTimelineLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Thumbnail widget for recipe images that shows a full-screen
/// image dialog when tapped.
class _RecipeDetailThumbnail extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final BoxFit fit;

  const _RecipeDetailThumbnail({
    required this.imagePath,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showRecipeMediaDialog(context, imagePath),
      child: AppRemoteOrAssetImage(
        imagePath: imagePath,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}

/// Dropdown widget for selecting the unit system (Original, Metric, Imperial).
class _UnitSystemDropdown extends StatelessWidget {
  final ExploreRecipeUnitSystem selectedUnitSystem;
  final ValueChanged<ExploreRecipeUnitSystem> onChanged;

  const _UnitSystemDropdown({
    required this.selectedUnitSystem,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return SizedBox(
      width: 116,
      child: DropdownButtonFormField<ExploreRecipeUnitSystem>(
        initialValue: selectedUnitSystem,
        dropdownColor: Colors.white,
        focusColor: Colors.transparent,
        isDense: true,
        decoration: InputDecoration(
          hintText: 'Units',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        style: textTheme.bodySmall,
        items: ExploreRecipeUnitSystem.values.map((system) {
          return DropdownMenuItem(
            value: system,
            child: Text(_unitSystemLabel(system)),
          );
        }).toList(),
        onChanged: (system) {
          if (system != null) onChanged(system);
        },
      ),
    );
  }

  /// Returns the display label for each unit system option.
  String _unitSystemLabel(ExploreRecipeUnitSystem system) {
    return switch (system) {
      ExploreRecipeUnitSystem.original => 'Original',
      ExploreRecipeUnitSystem.metric => 'Metric',
      ExploreRecipeUnitSystem.imperial => 'Imperial',
    };
  }
}

/// Individual ingredient list item with image, name, calories, and amount.
class _IngredientListItem extends StatelessWidget {
  final ExploreIngredient ingredient;
  final ExploreRecipeUnitSystem unitSystem;

  const _IngredientListItem({
    required this.ingredient,
    required this.unitSystem,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ingredient thumbnail.
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: _RecipeDetailThumbnail(
              imagePath: ingredient.imagePath,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          // Ingredient name and calories.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge,
                ),
                Text(ingredient.calories, style: textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Amount badge with unit conversion.
          SizedBox(
            width: 112,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.secondary),
              ),
              child: Text(
                _formatIngredientAmount(ingredient.amount, unitSystem),
                maxLines: 3,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFF3A518),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats the ingredient amount based on the selected unit system.
/// Converts between imperial and metric units as needed.
String _formatIngredientAmount(
  String amount,
  ExploreRecipeUnitSystem unitSystem,
) {
  if (unitSystem == ExploreRecipeUnitSystem.original) return amount;

  final trimmed = amount.trim();
  final match = RegExp(
    r'^([0-9]+(?:\.[0-9]+)?)(?:\s*(.+))?$',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (match == null) return amount;

  final value = double.tryParse(match.group(1) ?? '');
  final unit = match.group(2)?.trim() ?? '';
  if (value == null || unit.isEmpty) return amount;

  final converted = unitSystem == ExploreRecipeUnitSystem.metric
      ? _toMetric(value, unit)
      : _toImperial(value, unit);

  return converted ?? amount;
}

/// Converts imperial units to metric units.
String? _toMetric(double value, String unit) {
  final normalized = _normalizeUnit(unit);
  switch (normalized) {
    case 'oz':
    case 'ounce':
    case 'ounces':
      return '${_formatUnitAmount(value * 28.3495)} g';
    case 'lb':
    case 'lbs':
    case 'pound':
    case 'pounds':
      return '${_formatUnitAmount(value * 453.592)} g';
    case 'fl oz':
    case 'fluid ounce':
    case 'fluid ounces':
      return '${_formatUnitAmount(value * 29.5735)} mL';
    case 'cup':
    case 'cups':
      return '${_formatUnitAmount(value * 236.588)} mL';
    case 'pint':
    case 'pints':
      return '${_formatUnitAmount(value * 473.176)} mL';
    case 'quart':
    case 'quarts':
      return '${_formatUnitAmount(value * 946.353)} mL';
    case 'gallon':
    case 'gallons':
      return '${_formatUnitAmount(value * 3.78541)} L';
    default:
      return null;
  }
}

/// Converts metric units to imperial units.
String? _toImperial(double value, String unit) {
  final normalized = _normalizeUnit(unit);
  switch (normalized) {
    case 'g':
    case 'gram':
    case 'grams':
      if (value >= 453.592) {
        return '${_formatUnitAmount(value / 453.592)} lb';
      }
      return '${_formatUnitAmount(value / 28.3495)} oz';
    case 'kg':
    case 'kilogram':
    case 'kilograms':
      return '${_formatUnitAmount(value * 2.20462)} lb';
    case 'ml':
    case 'milliliter':
    case 'milliliters':
    case 'millilitre':
    case 'millilitres':
      return _formatCupLabel(value / 236.588);
    case 'l':
    case 'liter':
    case 'liters':
    case 'litre':
    case 'litres':
      return _formatCupLabel(value * 4.22675);
    default:
      return null;
  }
}

/// Normalizes unit strings by lowercasing and trimming.
String _normalizeUnit(String unit) {
  return unit.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Formats a unit amount with appropriate decimal precision.
String _formatUnitAmount(double value) {
  final rounded = value.roundToDouble();
  if ((value - rounded).abs() < 0.05) return rounded.toInt().toString();
  if (value >= 10) return value.toStringAsFixed(1);
  return value.toStringAsFixed(2);
}

/// Formats a cup measurement with proper fraction symbols.
String _formatCupAmount(double value) {
  final whole = value.floor();
  final remainder = value - whole;
  const fractions = <_CookingFraction>[
    _CookingFraction(0, ''),
    _CookingFraction(1 / 4, '¼'),
    _CookingFraction(1 / 3, '⅓'),
    _CookingFraction(1 / 2, '½'),
    _CookingFraction(2 / 3, '⅔'),
    _CookingFraction(3 / 4, '¾'),
    _CookingFraction(1, ''),
  ];

  // Find the closest fraction approximation.
  var closest = fractions.first;
  var smallestDistance = (remainder - closest.value).abs();
  for (final fraction in fractions.skip(1)) {
    final distance = (remainder - fraction.value).abs();
    if (distance < smallestDistance) {
      smallestDistance = distance;
      closest = fraction;
    }
  }

  var roundedWhole = whole;
  // Handle rounding up when the fraction equals one.
  if (closest.value == 1) {
    roundedWhole += 1;
    closest = fractions.first;
  }

  // Ensure a fraction is shown for values between 0 and 1.
  if (roundedWhole == 0 && closest.value == 0 && value > 0) {
    closest = fractions[1];
  }

  if (roundedWhole == 0) return closest.label;
  if (closest.value == 0) return roundedWhole.toString();
  return '$roundedWhole ${closest.label}';
}

/// Formats a cup measurement with proper pluralization.
String _formatCupLabel(double value) {
  final amount = _formatCupAmount(value);
  final isSingular = amount == '1' || !amount.contains(RegExp(r'[0-9]'));
  return '$amount ${isSingular ? 'cup' : 'cups'}';
}

/// Helper class for cooking fraction values and their display labels.
class _CookingFraction {
  final double value;
  final String label;

  const _CookingFraction(this.value, this.label);
}

/// Groups ingredients by their category for organized display.
List<_IngredientCategoryGroup> _groupIngredientsByCategory(
  List<ExploreIngredient> ingredients,
) {
  final groups = <String, _IngredientCategoryGroup>{};

  // Categorize each ingredient.
  for (final ingredient in ingredients) {
    final name = ingredient.ingredientCategoryName.trim().isEmpty
        ? 'Uncategorized'
        : ingredient.ingredientCategoryName.trim();
    groups.putIfAbsent(name, () => _IngredientCategoryGroup(name, []));
    groups[name]!.ingredients.add(ingredient);
  }

  // Sort ingredients within each group alphabetically.
  for (final group in groups.values) {
    group.ingredients.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );
  }

  return groups.values.toList();
}

/// Internal class for grouping ingredients by category.
class _IngredientCategoryGroup {
  final String name;
  final List<ExploreIngredient> ingredients;

  const _IngredientCategoryGroup(this.name, this.ingredients);
}

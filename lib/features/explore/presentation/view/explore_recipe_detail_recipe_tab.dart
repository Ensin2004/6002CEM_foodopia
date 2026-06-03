part of 'explore_recipe_detail_page.dart';

class _RecipeTab extends StatelessWidget {
  final ExploreRecipeDetailViewModel viewModel;
  final ExploreRecipe recipe;
  final VoidCallback onComingSoonTap;
  final VoidCallback onPlanMeal;
  final bool showPlanMeal;

  const _RecipeTab({
    required this.viewModel,
    required this.recipe,
    required this.onComingSoonTap,
    required this.onPlanMeal,
    required this.showPlanMeal,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About This Recipe', style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(recipe.description, style: textTheme.bodyMedium),
        const SizedBox(height: 14),
        Text('Other Names', style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          recipe.otherNames.isEmpty ? 'None' : recipe.otherNames.join(', '),
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        Text('Category', style: textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(recipe.category, style: textTheme.bodyMedium),
        const SizedBox(height: 14),
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
        AppPillSegmentedControl(
          labels: const ['Ingredients', 'Instructions'],
          selectedIndex: ExploreRecipeMethodTab.values.indexOf(
            viewModel.selectedMethodTab,
          ),
          onChanged: (index) =>
              viewModel.selectMethodTab(ExploreRecipeMethodTab.values[index]),
        ),
        const SizedBox(height: 16),
        if (viewModel.selectedMethodTab == ExploreRecipeMethodTab.ingredients)
          _IngredientsList(
            recipe: recipe,
            onPlanMeal: onPlanMeal,
            showPlanMeal: showPlanMeal,
          )
        else
          _InstructionsList(recipe: recipe),
      ],
    );
  }
}

class _IngredientsList extends StatelessWidget {
  final ExploreRecipe recipe;
  final VoidCallback onPlanMeal;
  final bool showPlanMeal;

  const _IngredientsList({
    required this.recipe,
    required this.onPlanMeal,
    required this.showPlanMeal,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final colors = context.colors;
    final ingredientGroups = _groupIngredientsByCategory(recipe.ingredients);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingredients List', style: textTheme.titleMedium),
        Text('${recipe.ingredients.length} items', style: textTheme.bodyMedium),
        const SizedBox(height: 10),
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
              (ingredient) => _IngredientListItem(ingredient: ingredient),
            ),
          ],
        ),
        if (showPlanMeal) ...[
          const SizedBox(height: 18),
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
              Text(
                section.title,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
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
                        _InstructionTimelineMarker(showLine: !isLast),
                        const SizedBox(width: 12),
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

enum _NutritionSummaryMode { total, serving }

enum _IngredientMacroCategory { carbohydrates, protein, fats }


class _IngredientListItem extends StatelessWidget {
  final ExploreIngredient ingredient;

  const _IngredientListItem({required this.ingredient});

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
          SizedBox(
            width: 112,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                ingredient.amount,
                maxLines: 3,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<_IngredientCategoryGroup> _groupIngredientsByCategory(
  List<ExploreIngredient> ingredients,
) {
  final groups = <String, _IngredientCategoryGroup>{};

  for (final ingredient in ingredients) {
    final name = ingredient.ingredientCategoryName.trim().isEmpty
        ? 'Uncategorized'
        : ingredient.ingredientCategoryName.trim();
    groups.putIfAbsent(name, () => _IngredientCategoryGroup(name, []));
    groups[name]!.ingredients.add(ingredient);
  }

  for (final group in groups.values) {
    group.ingredients.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );
  }

  return groups.values.toList();
}

class _IngredientCategoryGroup {
  final String name;
  final List<ExploreIngredient> ingredients;

  const _IngredientCategoryGroup(this.name, this.ingredients);
}


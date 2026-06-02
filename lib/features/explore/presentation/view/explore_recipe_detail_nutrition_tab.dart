part of 'explore_recipe_detail_page.dart';

class _NutritionTab extends StatefulWidget {
  final ExploreRecipe recipe;
  final VoidCallback onServingTap;

  const _NutritionTab({required this.recipe, required this.onServingTap});

  @override
  State<_NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<_NutritionTab> {
  _NutritionSummaryMode _summaryMode = _NutritionSummaryMode.serving;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final recipe = widget.recipe;
    final displayNutrition = _nutritionForMode(recipe, _summaryMode);
    final totalMacroGrams =
        displayNutrition.carbsGrams +
        displayNutrition.proteinGrams +
        displayNutrition.fatGrams;
    final servings = recipe.servings <= 0 ? 1 : recipe.servings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NutritionPanel(
          child: Column(
            children: [
              Row(
                children: [
                  Text('Nutrition Summary', style: textTheme.titleMedium),
                  const Spacer(),
                  PopupMenuButton<_NutritionSummaryMode>(
                    initialValue: _summaryMode,
                    onSelected: (mode) => setState(() => _summaryMode = mode),
                    itemBuilder: (context) =>
                        _NutritionSummaryMode.values.map((mode) {
                          return PopupMenuItem(
                            value: mode,
                            child: Text(_nutritionModeLabel(mode)),
                          );
                        }).toList(),
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _nutritionModeLabel(_summaryMode),
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 118,
                    height: 118,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size.square(118),
                          painter: _MacroRingPainter(
                            carbs: displayNutrition.carbsGrams,
                            protein: displayNutrition.proteinGrams,
                            fat: displayNutrition.fatGrams,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${displayNutrition.calories}',
                              style: textTheme.headlineSmall,
                            ),
                            Text('kcal', style: textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        _MacroRow(
                          label: 'Carbohydrate',
                          grams: displayNutrition.carbsGrams,
                          totalGrams: totalMacroGrams,
                          color: AppColors.primary,
                        ),
                        _MacroRow(
                          label: 'Protein',
                          grams: displayNutrition.proteinGrams,
                          totalGrams: totalMacroGrams,
                          color: AppColors.error,
                        ),
                        _MacroRow(
                          label: 'Fat',
                          grams: displayNutrition.fatGrams,
                          totalGrams: totalMacroGrams,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _NutritionPanel(
          child: Column(
            children: [
              Row(
                children: [
                  Text('Ingredients Breakdown', style: textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 10),
              _IngredientMacroPager(
                key: ValueKey(_summaryMode),
                ingredients: recipe.ingredients,
                totalNutrition: displayNutrition,
                servings: servings,
                summaryMode: _summaryMode,
                onSeeAll: (category, totalGrams) =>
                    _showIngredientBreakdownDialog(
                      context,
                      category,
                      totalGrams,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showIngredientBreakdownDialog(
    BuildContext context,
    _IngredientMacroCategory category,
    double totalGrams,
  ) {
    final ingredients = _sortedIngredientsByMacro(
      widget.recipe.ingredients,
      category,
      summaryMode: _summaryMode,
      servings: widget.recipe.servings <= 0 ? 1 : widget.recipe.servings,
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 36,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_ingredientMacroLabel(category)} Breakdown',
                        style: context.text.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: ingredients
                          .map(
                            (ingredient) => _IngredientNutritionRow(
                              ingredient: ingredient,
                              category: category,
                              color: _ingredientMacroColor(category),
                              totalGrams: totalGrams,
                              servings: widget.recipe.servings <= 0
                                  ? 1
                                  : widget.recipe.servings,
                              summaryMode: _summaryMode,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _nutritionModeLabel(_NutritionSummaryMode mode) {
    switch (mode) {
      case _NutritionSummaryMode.serving:
        return 'Per serving';
      case _NutritionSummaryMode.total:
        return 'Total serving';
    }
  }

  static ExploreNutrition _nutritionForMode(
    ExploreRecipe recipe,
    _NutritionSummaryMode mode,
  ) {
    if (mode == _NutritionSummaryMode.total) return recipe.nutrition;

    final servings = recipe.servings <= 0 ? 1 : recipe.servings;
    return ExploreNutrition(
      calories: (recipe.nutrition.calories / servings).round(),
      carbsGrams: (recipe.nutrition.carbsGrams / servings).round(),
      proteinGrams: (recipe.nutrition.proteinGrams / servings).round(),
      fatGrams: (recipe.nutrition.fatGrams / servings).round(),
    );
  }

  static double _ingredientMacroValue(
    ExploreIngredient ingredient,
    _IngredientMacroCategory category, {
    required _NutritionSummaryMode summaryMode,
    required int servings,
  }) {
    final totalValue = switch (category) {
      _IngredientMacroCategory.carbohydrates => ingredient.carbsGrams,
      _IngredientMacroCategory.protein => ingredient.proteinGrams,
      _IngredientMacroCategory.fats => ingredient.fatGrams,
    };
    if (summaryMode == _NutritionSummaryMode.total) return totalValue;
    return totalValue / (servings <= 0 ? 1 : servings);
  }

  static List<ExploreIngredient> _sortedIngredientsByMacro(
    List<ExploreIngredient> ingredients,
    _IngredientMacroCategory category, {
    required _NutritionSummaryMode summaryMode,
    required int servings,
  }) {
    return [...ingredients]..sort((first, second) {
      final firstValue = _ingredientMacroValue(
        first,
        category,
        summaryMode: summaryMode,
        servings: servings,
      );
      final secondValue = _ingredientMacroValue(
        second,
        category,
        summaryMode: summaryMode,
        servings: servings,
      );
      final valueCompare = secondValue.compareTo(firstValue);
      if (valueCompare != 0) return valueCompare;
      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });
  }

  static String _ingredientMacroLabel(_IngredientMacroCategory category) {
    switch (category) {
      case _IngredientMacroCategory.carbohydrates:
        return 'Carbohydrates';
      case _IngredientMacroCategory.protein:
        return 'Protein';
      case _IngredientMacroCategory.fats:
        return 'Fats';
    }
  }

  static Color _ingredientMacroColor(_IngredientMacroCategory category) {
    switch (category) {
      case _IngredientMacroCategory.carbohydrates:
        return AppColors.primary;
      case _IngredientMacroCategory.protein:
        return AppColors.error;
      case _IngredientMacroCategory.fats:
        return AppColors.secondary;
    }
  }
}

class _IngredientMacroPager extends StatefulWidget {
  final List<ExploreIngredient> ingredients;
  final ExploreNutrition totalNutrition;
  final int servings;
  final _NutritionSummaryMode summaryMode;
  final void Function(_IngredientMacroCategory category, double totalGrams)
  onSeeAll;

  const _IngredientMacroPager({
    super.key,
    required this.ingredients,
    required this.totalNutrition,
    required this.servings,
    required this.summaryMode,
    required this.onSeeAll,
  });

  @override
  State<_IngredientMacroPager> createState() => _IngredientMacroPagerState();
}

class _IngredientMacroPagerState extends State<_IngredientMacroPager> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const _categories = [
    _IngredientMacroCategory.carbohydrates,
    _IngredientMacroCategory.protein,
    _IngredientMacroCategory.fats,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCategory = _categories[_currentPage];

    return Column(
      children: [
        SizedBox(
          height: _pageHeightFor(currentCategory),
          child: PageView.builder(
            controller: _pageController,
            itemCount: _categories.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _IngredientMacroPage(
                key: ValueKey('${widget.summaryMode}-$category'),
                category: category,
                color: _NutritionTabState._ingredientMacroColor(category),
                ingredients: widget.ingredients,
                totalGrams: _totalGramsFor(category),
                servings: widget.servings,
                summaryMode: widget.summaryMode,
                onSeeAll: () =>
                    widget.onSeeAll(category, _totalGramsFor(category)),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_categories.length, (index) {
            final isSelected = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isSelected ? 18 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isSelected ? context.colors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }

  double _totalGramsFor(_IngredientMacroCategory category) {
    switch (category) {
      case _IngredientMacroCategory.carbohydrates:
        return widget.totalNutrition.carbsGrams.toDouble();
      case _IngredientMacroCategory.protein:
        return widget.totalNutrition.proteinGrams.toDouble();
      case _IngredientMacroCategory.fats:
        return widget.totalNutrition.fatGrams.toDouble();
    }
  }

  double _pageHeightFor(_IngredientMacroCategory category) {
    final visibleCount = _NutritionTabState
        ._sortedIngredientsByMacro(
          widget.ingredients,
          category,
          summaryMode: widget.summaryMode,
          servings: widget.servings,
        )
        .take(5)
        .length;

    if (visibleCount == 0) return 74;
    return 42 + (visibleCount * 59);
  }
}

class _IngredientMacroPage extends StatelessWidget {
  final _IngredientMacroCategory category;
  final Color color;
  final List<ExploreIngredient> ingredients;
  final double totalGrams;
  final int servings;
  final _NutritionSummaryMode summaryMode;
  final VoidCallback onSeeAll;

  const _IngredientMacroPage({
    super.key,
    required this.category,
    required this.color,
    required this.ingredients,
    required this.totalGrams,
    required this.servings,
    required this.summaryMode,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final sortedIngredients = _NutritionTabState._sortedIngredientsByMacro(
      ingredients,
      category,
      summaryMode: summaryMode,
      servings: servings,
    );
    final visibleIngredients = sortedIngredients.take(5).toList();
    final totalLabel = _formatMacroGramValue(totalGrams);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _NutritionTabState._ingredientMacroLabel(category),
              style: context.text.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${_NutritionTabState._nutritionModeLabel(summaryMode)} - ${totalLabel}g',
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'See all',
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (visibleIngredients.isEmpty)
          Text('No ingredients yet.', style: context.text.bodySmall)
        else
          ...visibleIngredients.map(
            (ingredient) => _IngredientNutritionRow(
              ingredient: ingredient,
              category: category,
              color: color,
              totalGrams: totalGrams,
              servings: servings,
              summaryMode: summaryMode,
            ),
          ),
      ],
    );
  }

  static String _formatMacroGramValue(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }
}


class _NutritionPanel extends StatelessWidget {
  final Widget child;

  const _NutritionPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final int grams;
  final int totalGrams;
  final Color color;

  const _MacroRow({
    required this.label,
    required this.grams,
    required this.totalGrams,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final value = totalGrams <= 0 ? 0.0 : (grams / totalGrams).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: value,
                  color: color,
                  backgroundColor: AppColors.background,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 44,
                child: Text(
                  '${(value * 100).round()}%',
                  style: textTheme.bodySmall,
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '${grams}g',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroRingPainter extends CustomPainter {
  final int carbs;
  final int protein;
  final int fat;

  const _MacroRingPainter({
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0;
    final rect = Offset.zero & size;
    final total = (carbs + protein + fat).toDouble();
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.background;

    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -1.5708,
      6.2832,
      false,
      backgroundPaint,
    );

    if (total <= 0) return;

    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    var startAngle = -1.5708;
    const gapAngle = 0.08;
    final segments = [
      _MacroRingSegment(value: carbs, color: AppColors.primary),
      _MacroRingSegment(value: protein, color: AppColors.error),
      _MacroRingSegment(value: fat, color: AppColors.secondary),
    ];

    for (final segment in segments) {
      final sweep = (segment.value / total) * 6.2832;
      segmentPaint.color = segment.color;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        (sweep - gapAngle).clamp(0.0, 6.2832).toDouble(),
        false,
        segmentPaint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter oldDelegate) {
    return oldDelegate.carbs != carbs ||
        oldDelegate.protein != protein ||
        oldDelegate.fat != fat;
  }
}

class _MacroRingSegment {
  final int value;
  final Color color;

  const _MacroRingSegment({required this.value, required this.color});
}

class _IngredientNutritionRow extends StatelessWidget {
  final ExploreIngredient ingredient;
  final _IngredientMacroCategory category;
  final Color color;
  final double totalGrams;
  final int servings;
  final _NutritionSummaryMode summaryMode;

  const _IngredientNutritionRow({
    required this.ingredient,
    required this.category,
    required this.color,
    required this.totalGrams,
    required this.servings,
    required this.summaryMode,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final value = _NutritionTabState._ingredientMacroValue(
      ingredient,
      category,
      summaryMode: summaryMode,
      servings: servings,
    );
    final valueLabel = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    final percent = totalGrams <= 0
        ? 0
        : ((value / totalGrams).clamp(0.0, 1.0) * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _RecipeDetailThumbnail(
              imagePath: ingredient.imagePath,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ingredient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$percent%',
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: textTheme.bodySmall,
                        ),
                        Text(
                          '${valueLabel}g',
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: totalGrams <= 0
                      ? 0
                      : (value / totalGrams).clamp(0.0, 1.0),
                  color: color,
                  backgroundColor: AppColors.background,
                  minHeight: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


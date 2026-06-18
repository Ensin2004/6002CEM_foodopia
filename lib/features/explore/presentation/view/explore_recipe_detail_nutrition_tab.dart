part of 'explore_recipe_detail_page.dart';

class _NutritionTab extends StatefulWidget {
  final ExploreRecipe recipe;
  final VoidCallback onServingTap;

  const _NutritionTab({required this.recipe, required this.onServingTap});

  @override
  State<_NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<_NutritionTab> {
  late int _selectedServings;

  @override
  void initState() {
    super.initState();
    _selectedServings = _baseServings(widget.recipe);
  }

  @override
  void didUpdateWidget(covariant _NutritionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipe.id != widget.recipe.id) {
      _selectedServings = _baseServings(widget.recipe);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final recipe = widget.recipe;
    final servings = _baseServings(recipe);
    final displayNutrition = _nutritionForServings(recipe, _selectedServings);
    final totalMacroGrams =
        displayNutrition.proteinGrams +
        displayNutrition.carbsGrams +
        displayNutrition.fatGrams +
        displayNutrition.fiberGrams +
        displayNutrition.waterGrams;
    final micronutrients = [
      ...displayNutrition.vitamins,
      ...displayNutrition.minerals,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NutritionPanel(
          child: Column(
            children: [
              Row(
                children: [
                  Text('Macronutrients', style: textTheme.titleMedium),
                  const Spacer(),
                  _ServingStepper(
                    value: _selectedServings,
                    onDecrease: _selectedServings <= 1
                        ? null
                        : () => setState(() => _selectedServings -= 1),
                    onIncrease: _selectedServings >= 99
                        ? null
                        : () => setState(() => _selectedServings += 1),
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
                          label: 'Protein',
                          grams: displayNutrition.proteinGrams,
                          totalGrams: totalMacroGrams,
                          color: AppColors.error,
                        ),
                        _MacroRow(
                          label: 'Carbohydrates',
                          grams: displayNutrition.carbsGrams,
                          totalGrams: totalMacroGrams,
                          color: AppColors.primary,
                        ),
                        _MacroRow(
                          label: 'Fat',
                          grams: displayNutrition.fatGrams,
                          totalGrams: totalMacroGrams,
                          color: AppColors.secondary,
                        ),
                        _MacroRow(
                          label: 'Fiber',
                          grams: displayNutrition.fiberGrams,
                          totalGrams: totalMacroGrams,
                          color: Colors.green,
                        ),
                        _MacroRow(
                          label: 'Water',
                          grams: displayNutrition.waterGrams,
                          totalGrams: totalMacroGrams,
                          color: Colors.lightBlue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (micronutrients.isNotEmpty) ...[
          const SizedBox(height: 16),
          _NutritionPanel(
            child: _MicronutrientSummary(
              calories: displayNutrition.calories,
              nutrients: micronutrients,
              onSeeAll: () =>
                  _showMicronutrientsDialog(context, micronutrients),
            ),
          ),
        ],
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
                key: ValueKey(_selectedServings),
                ingredients: recipe.ingredients,
                totalNutrition: displayNutrition,
                baseServings: servings,
                selectedServings: _selectedServings,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMicronutrientsDialog(
    BuildContext context,
    List<ExploreNutrientAmount> nutrients,
  ) {
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
                      Text('Micronutrients', style: context.text.titleMedium),
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
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.15,
                      children: nutrients
                          .map((nutrient) => _MicronutrientCard(nutrient))
                          .toList(growable: false),
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

  static int _baseServings(ExploreRecipe recipe) {
    return recipe.servings <= 0 ? 1 : recipe.servings;
  }

  static ExploreNutrition _nutritionForServings(
    ExploreRecipe recipe,
    int selectedServings,
  ) {
    final servings = _baseServings(recipe);
    final factor = selectedServings / servings;
    return ExploreNutrition(
      calories: (recipe.nutrition.calories * factor).round(),
      proteinGrams: (recipe.nutrition.proteinGrams * factor).round(),
      carbsGrams: (recipe.nutrition.carbsGrams * factor).round(),
      fatGrams: (recipe.nutrition.fatGrams * factor).round(),
      fiberGrams: (recipe.nutrition.fiberGrams * factor).round(),
      waterGrams: (recipe.nutrition.waterGrams * factor).round(),
      vitamins: _nutrientsForFactor(recipe.nutrition.vitamins, factor),
      minerals: _nutrientsForFactor(recipe.nutrition.minerals, factor),
    );
  }

  static List<ExploreNutrientAmount> _nutrientsForFactor(
    List<ExploreNutrientAmount> nutrients,
    double factor,
  ) {
    return nutrients
        .map(
          (nutrient) => ExploreNutrientAmount(
            key: nutrient.key,
            label: nutrient.label,
            amount: nutrient.amount * factor,
            unit: nutrient.unit,
            dailyValue: nutrient.dailyValue,
          ),
        )
        .toList(growable: false);
  }

}

class _IngredientMacroPager extends StatefulWidget {
  final List<ExploreIngredient> ingredients;
  final ExploreNutrition totalNutrition;
  final int baseServings;
  final int selectedServings;

  const _IngredientMacroPager({
    super.key,
    required this.ingredients,
    required this.totalNutrition,
    required this.baseServings,
    required this.selectedServings,
  });

  @override
  State<_IngredientMacroPager> createState() => _IngredientMacroPagerState();
}

class _IngredientMacroPagerState extends State<_IngredientMacroPager> {
  late final PageController _pageController;
  int _currentPage = 0;

  List<_IngredientNutrientPageSpec> get _pages {
    final pages = [
      _IngredientNutrientPageSpec.macro(
        key: 'protein',
        label: 'Protein',
        unit: 'g',
        color: AppColors.error,
        valueForIngredient: (ingredient) => ingredient.proteinGrams,
        totalValue: widget.totalNutrition.proteinGrams.toDouble(),
      ),
      _IngredientNutrientPageSpec.macro(
        key: 'carbohydrates',
        label: 'Carbohydrates',
        unit: 'g',
        color: AppColors.primary,
        valueForIngredient: (ingredient) => ingredient.carbsGrams,
        totalValue: widget.totalNutrition.carbsGrams.toDouble(),
      ),
      _IngredientNutrientPageSpec.macro(
        key: 'fat',
        label: 'Fat',
        unit: 'g',
        color: AppColors.secondary,
        valueForIngredient: (ingredient) => ingredient.fatGrams,
        totalValue: widget.totalNutrition.fatGrams.toDouble(),
      ),
      _IngredientNutrientPageSpec.macro(
        key: 'fiber',
        label: 'Fiber',
        unit: 'g',
        color: Colors.green,
        valueForIngredient: (ingredient) => ingredient.fiberGrams,
        totalValue: widget.totalNutrition.fiberGrams.toDouble(),
      ),
      _IngredientNutrientPageSpec.macro(
        key: 'water',
        label: 'Water',
        unit: 'g',
        color: Colors.lightBlue,
        valueForIngredient: (ingredient) => ingredient.waterGrams,
        totalValue: widget.totalNutrition.waterGrams.toDouble(),
      ),
      ...[
        ...widget.totalNutrition.vitamins,
        ...widget.totalNutrition.minerals,
      ].where((nutrient) => nutrient.amount > 0).map(
            (nutrient) => _IngredientNutrientPageSpec.micro(
              nutrient: nutrient,
              color: _MicronutrientCard._colorForNutrient(nutrient.key),
            ),
          ),
    ];
    return pages
        .where(
          (page) => widget.ingredients.any(
            (ingredient) => page.valueForIngredient(ingredient) > 0,
          ),
        )
        .toList(growable: false);
  }

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
    final pages = _pages;
    final pageCount = pages.isEmpty ? 1 : pages.length;
    final currentPage = _currentPage.clamp(0, pageCount - 1);

    return Column(
      children: [
        SizedBox(
          height: _pageHeightFor(),
          child: PageView.builder(
            controller: _pageController,
            itemCount: pageCount,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              if (pages.isEmpty) {
                return Text(
                  'No ingredients yet.',
                  style: context.text.bodySmall,
                );
              }
              final page = pages[index];
              return _IngredientNutrientBreakdownPage(
                key: ValueKey('${widget.selectedServings}-${page.key}'),
                page: page,
                ingredients: widget.ingredients,
                baseServings: widget.baseServings,
                selectedServings: widget.selectedServings,
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageCount, (index) {
              final isSelected = index == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isSelected ? 18 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  double _pageHeightFor() {
    final pages = _pages;
    final page = pages.isEmpty
        ? null
        : pages[_currentPage.clamp(0, pages.length - 1)];
    final visibleCount = page == null
        ? 0
        : widget.ingredients
            .where((ingredient) => page.valueForIngredient(ingredient) > 0)
            .length;
    if (visibleCount == 0) return 116;
    return 190;
  }
}

class _ServingStepper extends StatelessWidget {
  final int value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _ServingStepper({
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ServingStepperButton(
            icon: Icons.remove_rounded,
            onPressed: onDecrease,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 74, maxWidth: 90),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              value == 1 ? '1 serving' : '$value servings',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _ServingStepperButton(
            icon: Icons.add_rounded,
            onPressed: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _ServingStepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _ServingStepperButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 30, height: 32),
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      color: onPressed == null
          ? AppColors.textSecondary.withValues(alpha: 0.4)
          : AppColors.textPrimary,
    );
  }
}

class _IngredientNutrientPageSpec {
  final String key;
  final String label;
  final String unit;
  final Color color;
  final double totalValue;
  final double Function(ExploreIngredient ingredient) valueForIngredient;

  const _IngredientNutrientPageSpec({
    required this.key,
    required this.label,
    required this.unit,
    required this.color,
    required this.totalValue,
    required this.valueForIngredient,
  });

  factory _IngredientNutrientPageSpec.macro({
    required String key,
    required String label,
    required String unit,
    required Color color,
    required double totalValue,
    required double Function(ExploreIngredient ingredient) valueForIngredient,
  }) {
    return _IngredientNutrientPageSpec(
      key: key,
      label: label,
      unit: unit,
      color: color,
      totalValue: totalValue,
      valueForIngredient: valueForIngredient,
    );
  }

  factory _IngredientNutrientPageSpec.micro({
    required ExploreNutrientAmount nutrient,
    required Color color,
  }) {
    return _IngredientNutrientPageSpec(
      key: nutrient.key,
      label: nutrient.label,
      unit: nutrient.unit,
      color: color,
      totalValue: nutrient.amount,
      valueForIngredient: (ingredient) {
        for (final item in [...ingredient.vitamins, ...ingredient.minerals]) {
          if (item.key == nutrient.key) return item.amount;
        }
        return 0;
      },
    );
  }
}

class _IngredientNutrientBreakdownPage extends StatelessWidget {
  final _IngredientNutrientPageSpec page;
  final List<ExploreIngredient> ingredients;
  final int baseServings;
  final int selectedServings;

  const _IngredientNutrientBreakdownPage({
    super.key,
    required this.page,
    required this.ingredients,
    required this.baseServings,
    required this.selectedServings,
  });

  @override
  Widget build(BuildContext context) {
    final allVisibleIngredients = ingredients
        .where((ingredient) => page.valueForIngredient(ingredient) > 0)
        .toList();
    final visibleIngredients = allVisibleIngredients.take(2).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Row(
          children: [
            Text(
              page.label,
              style: context.text.labelLarge?.copyWith(
                color: page.color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: allVisibleIngredients.isEmpty
                  ? null
                  : () => _showAllIngredients(context, allVisibleIngredients),
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
                  fontWeight: FontWeight.w800,
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
            (ingredient) => _IngredientNutrientBreakdownRow(
              page: page,
              ingredient: ingredient,
              baseServings: baseServings,
              selectedServings: selectedServings,
            ),
          ),
      ],
    );
  }

  void _showAllIngredients(
    BuildContext context,
    List<ExploreIngredient> visibleIngredients,
  ) {
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
                      Expanded(
                        child: Text(
                          '${page.label} Breakdown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleMedium,
                        ),
                      ),
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
                      children: visibleIngredients
                          .map(
                            (ingredient) => _IngredientNutrientBreakdownRow(
                              page: page,
                              ingredient: ingredient,
                              baseServings: baseServings,
                              selectedServings: selectedServings,
                            ),
                          )
                          .toList(growable: false),
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
}

class _MicronutrientSummary extends StatelessWidget {
  final int calories;
  final List<ExploreNutrientAmount> nutrients;
  final VoidCallback onSeeAll;

  const _MicronutrientSummary({
    required this.calories,
    required this.nutrients,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('Micronutrients', style: context.text.titleMedium),
            const Spacer(),
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
                  fontWeight: FontWeight.w800,
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
                    painter: _MicronutrientRingPainter(nutrients: nutrients),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$calories',
                        style: context.text.headlineSmall,
                      ),
                      Text('kcal', style: context.text.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: SizedBox(
                height: 118,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: nutrients
                      .map(
                        (nutrient) => _NutrientPercentRow(
                          nutrient: nutrient,
                          color: _MicronutrientCard._colorForNutrient(
                            nutrient.key,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MicronutrientCards(nutrients: nutrients),
      ],
    );
  }
}

class _NutrientPercentRow extends StatelessWidget {
  final ExploreNutrientAmount nutrient;
  final Color color;

  const _NutrientPercentRow({
    required this.nutrient,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final value = nutrient.dailyValue <= 0
        ? 0.0
        : (nutrient.amount / nutrient.dailyValue).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nutrient.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: context.text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _MicronutrientCard._formatNutrientAmount(nutrient),
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            color: color,
            backgroundColor: AppColors.background,
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }
}

class _IngredientNutrientBreakdownRow extends StatelessWidget {
  final _IngredientNutrientPageSpec page;
  final ExploreIngredient ingredient;
  final int baseServings;
  final int selectedServings;

  const _IngredientNutrientBreakdownRow({
    required this.page,
    required this.ingredient,
    required this.baseServings,
    required this.selectedServings,
  });

  @override
  Widget build(BuildContext context) {
    final factor = selectedServings / (baseServings <= 0 ? 1 : baseServings);
    final value = page.valueForIngredient(ingredient) * factor;
    final total = page.totalValue;
    final percent = total <= 0
        ? 0
        : ((value / total).clamp(0.0, 1.0) * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                Text(
                  ingredient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: total <= 0 ? 0 : (value / total).clamp(0.0, 1.0),
                        color: page.color,
                        backgroundColor: AppColors.background,
                        minHeight: 4,
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
                          style: context.text.bodySmall,
                        ),
                        Text(
                          _formatNutrientValue(value, page.unit),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: context.text.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNutrientValue(double value, String unit) {
  final text = value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(value < 10 ? 1 : 0);
  return '$text $unit';
}

class _MicronutrientCards extends StatelessWidget {
  final List<ExploreNutrientAmount> nutrients;

  const _MicronutrientCards({required this.nutrients});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: nutrients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 92,
            child: _MicronutrientCard(nutrients[index]),
          );
        },
      ),
    );
  }
}

class _MicronutrientCard extends StatelessWidget {
  final ExploreNutrientAmount nutrient;

  const _MicronutrientCard(this.nutrient);

  @override
  Widget build(BuildContext context) {
    final color = _colorForNutrient(nutrient.key);
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconForNutrient(nutrient.key), color: color, size: 16),
          ),
          const SizedBox(height: 5),
          Text(
            nutrient.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatNutrientAmount(nutrient),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            _formatDailyValue(nutrient),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForNutrient(String key) {
    if (key.startsWith('vitamin')) return Icons.local_florist_rounded;
    return switch (key) {
      'iron' => Icons.bolt_rounded,
      'sodium' => Icons.water_drop_rounded,
      'potassium' => Icons.spa_rounded,
      'calcium' => Icons.shield_rounded,
      _ => Icons.grain_rounded,
    };
  }

  static Color _colorForNutrient(String key) {
    return switch (key) {
      'vitaminA' => AppColors.primary,
      'vitaminC' => Colors.orange,
      'vitaminD' => Colors.amber,
      'vitaminE' => Colors.teal,
      'vitaminK' => Colors.lightGreen,
      'vitaminB1' => Colors.cyan,
      'vitaminB2' => Colors.blue,
      'vitaminB3' => Colors.deepPurple,
      'vitaminB6' => Colors.pink,
      'vitaminB9' => Colors.lime,
      'vitaminB12' => Colors.green,
      'calcium' => Colors.indigo,
      'iron' => AppColors.error,
      'magnesium' => Colors.purple,
      'phosphorus' => Colors.brown,
      'potassium' => Colors.deepPurpleAccent,
      'sodium' => Colors.lightBlue,
      _ => AppColors.secondary,
    };
  }

  static String _formatNutrientAmount(ExploreNutrientAmount nutrient) {
    final amount = nutrient.amount;
    final text = amount == amount.roundToDouble()
        ? amount.round().toString()
        : amount.toStringAsFixed(amount < 10 ? 1 : 0);
    return '$text ${nutrient.unit}';
  }

  static String _formatDailyValue(ExploreNutrientAmount nutrient) {
    if (nutrient.dailyValue <= 0) return '-';
    final percent = (nutrient.amount / nutrient.dailyValue * 100).round();
    return '$percent% DV';
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

class _MicronutrientRingPainter extends CustomPainter {
  final List<ExploreNutrientAmount> nutrients;

  const _MicronutrientRingPainter({required this.nutrients});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0;
    final rect = Offset.zero & size;
    final segments = nutrients
        .map((nutrient) {
          if (nutrient.dailyValue <= 0) return null;
          final value = nutrient.amount / nutrient.dailyValue * 100;
          if (value <= 0) return null;
          return _MicronutrientRingSegment(
            value: value,
            color: _MicronutrientCard._colorForNutrient(nutrient.key),
          );
        })
        .whereType<_MicronutrientRingSegment>()
        .toList(growable: false);
    final total = segments.fold<double>(0, (sum, item) => sum + item.value);
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
    const gapAngle = 0.035;
    const minVisibleSweep = 0.025;

    for (final segment in segments) {
      final sweep = (segment.value / total) * 6.2832;
      final visibleSweep = sweep <= gapAngle
          ? sweep.clamp(minVisibleSweep, 6.2832).toDouble()
          : (sweep - gapAngle).clamp(minVisibleSweep, 6.2832).toDouble();
      segmentPaint.color = segment.color;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        visibleSweep,
        false,
        segmentPaint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MicronutrientRingPainter oldDelegate) {
    return oldDelegate.nutrients != nutrients;
  }
}

class _MicronutrientRingSegment {
  final double value;
  final Color color;

  const _MicronutrientRingSegment({
    required this.value,
    required this.color,
  });
}

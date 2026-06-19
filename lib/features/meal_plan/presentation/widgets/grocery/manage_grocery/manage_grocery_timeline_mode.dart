part of '../../../view/manage_grocery_list_page.dart';

/// Timeline-mode widgets for meal-by-meal grocery review.
///
/// Day, meal, category, and ingredient rows are grouped by timeline flow.
/// Timeline view mode widget.
class _TimelineMode extends StatelessWidget {
  /// The grocery list detail.
  final ManageGroceryListDetail detail;

  /// Creates a new timeline mode instance.
  const _TimelineMode({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: detail.timelineDays
          .map((day) => _TimelineDay(day: day))
          .toList(),
    );
  }
}

/// Timeline day widget.
class _TimelineDay extends StatelessWidget {
  /// The day data.
  final ManageGroceryTimelineDay day;

  /// Creates a new timeline day instance.
  const _TimelineDay({required this.day});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    // Check if day is expanded.
    final isExpanded = viewModel.isTimelineDayExpanded(day.date);

    // Count total ingredients.
    final itemCount = day.meals.fold<int>(
      0,
      (count, meal) => count + meal.ingredients.length,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline vertical line.
            Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F7E4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                Expanded(child: Container(width: 1, color: AppColors.border)),
              ],
            ),
            const SizedBox(width: AppSpacing.md),

            // Day content.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => context
                              .read<ManageGroceryListViewModel>()
                              .toggleTimelineDay(day.date),
                          child: Text(
                            '${DateFormat('EEEE, d MMM').format(day.date)} (Day ${day.dayNumber})',
                            style: context.text.titleMedium,
                          ),
                        ),
                      ),
                      _CountBadge(label: '$itemCount items'),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context
                            .read<ManageGroceryListViewModel>()
                            .toggleTimelineDay(day.date),
                        icon: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: AppSpacing.md),
                    ...day.meals.asMap().entries.map(
                      (entry) => _TimelineMeal(
                        date: day.date,
                        meal: entry.value,
                        isLast: entry.key == day.meals.length - 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Timeline meal widget.
class _TimelineMeal extends StatelessWidget {
  /// Date of the meal.
  final DateTime date;

  /// The meal data.
  final ManageGroceryTimelineMeal meal;

  /// Whether this is the last meal.
  final bool isLast;

  /// Creates a new timeline meal instance.
  const _TimelineMeal({
    required this.date,
    required this.meal,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    // Check if meal is expanded.
    final isExpanded = viewModel.isTimelineMealExpanded(
      date,
      meal.mealType,
      meal.title,
    );

    return IntrinsicHeight(
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal timeline dot.
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      meal.mealType == 'Breakfast'
                          ? Icons.wb_sunny
                          : Icons.nightlight,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  Expanded(child: Container(width: 1, color: AppColors.border)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Meal content.
            Expanded(
              child: Column(
                children: [
                  InkWell(
                    onTap: () => context
                        .read<ManageGroceryListViewModel>()
                        .toggleTimelineMeal(date, meal.mealType, meal.title),
                    child: SizedBox(
                      height: 32,
                      child: Row(
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    meal.mealType,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.bodyMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: AppColors.textPrimary,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          _CountBadge(
                            label: '${meal.ingredients.length} items',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Meal card.
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => context
                              .read<ManageGroceryListViewModel>()
                              .toggleTimelineMeal(
                                date,
                                meal.mealType,
                                meal.title,
                              ),
                          child: Padding(
                            padding: AppSpacing.cardPadding,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _MealImage(
                                    path: meal.imagePath,
                                    width: 48,
                                    height: 48,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    meal.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.bodyMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded) ...[
                          _GroupedTimelineIngredients(
                            ingredients: meal.ingredients,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.sm,
                              AppSpacing.lg,
                              AppSpacing.md,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 30,
                              child: OutlinedButton(
                                onPressed: () => _showAddIngredientDialog(
                                  context,
                                  relatedMealPlanIds: [meal.mealPlanId],
                                ),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  '+ Add Ingredient',
                                  style: context.text.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grouped timeline ingredients widget.
class _GroupedTimelineIngredients extends StatelessWidget {
  /// List of ingredients.
  final List<ManageGroceryItem> ingredients;

  /// Creates a new grouped timeline ingredients instance.
  const _GroupedTimelineIngredients({required this.ingredients});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    // Group ingredients by category.
    final grouped = <String, _TimelineIngredientGroup>{};
    for (final item in ingredients) {
      if (!viewModel.shouldShowItem(item.id)) continue;
      final key = item.categoryId.isEmpty ? item.categoryName : item.categoryId;
      grouped
          .putIfAbsent(
            key,
            () => _TimelineIngredientGroup(title: item.categoryName),
          )
          .items
          .add(item);
    }

    // Sort categories.
    final categories = grouped.values.toList()
      ..sort((first, second) => first.title.compareTo(second.title));

    return Column(
      children: categories
          .map(
            (group) => _TimelineIngredientCategory(
              title: group.title,
              ingredients: group.items,
            ),
          )
          .toList(),
    );
  }
}

/// Timeline ingredient group data class.
class _TimelineIngredientGroup {
  /// Category title.
  final String title;

  /// List of ingredients.
  final List<ManageGroceryItem> items = [];

  /// Creates a new timeline ingredient group instance.
  _TimelineIngredientGroup({required this.title});
}

/// Timeline ingredient category widget.
class _TimelineIngredientCategory extends StatelessWidget {
  /// Category title.
  final String title;

  /// List of ingredients.
  final List<ManageGroceryItem> ingredients;

  /// Creates a new timeline ingredient category instance.
  const _TimelineIngredientCategory({
    required this.title,
    required this.ingredients,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _ingredientCategoryIcon(title),
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _CountBadge(label: '${ingredients.length} items'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...ingredients.map((item) => _TimelineIngredient(item: item)),
        ],
      ),
    );
  }
}

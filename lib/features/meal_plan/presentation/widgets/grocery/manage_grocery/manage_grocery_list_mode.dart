part of '../../../view/manage_grocery_list_page.dart';

/// List-mode widgets for grocery categories and upcoming meals.
///
/// Category rows, meal carousel cards, and list-mode helpers live together.
/// View mode tabs widget.
class _ViewModeTabs extends StatelessWidget {
  /// Creates a new view mode tabs instance.
  const _ViewModeTabs();

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    return AppPillSegmentedControl(
      labels: const ['List', 'Timeline'],
      selectedIndex: viewModel.viewMode == ManageGroceryViewMode.list ? 0 : 1,
      onChanged: (index) =>
          context.read<ManageGroceryListViewModel>().setViewMode(
            index == 0
                ? ManageGroceryViewMode.list
                : ManageGroceryViewMode.timeline,
          ),
    );
  }
}

/// List view mode widget.
class _ListMode extends StatelessWidget {
  /// The grocery list detail.
  final ManageGroceryListDetail detail;

  /// Creates a new list mode instance.
  const _ListMode({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upcoming meals header.
        Row(
          children: [
            Expanded(
              child: Text(
                'Upcoming Meals (${DateFormat('d MMM').format(detail.startDate)} - ${DateFormat('d MMM').format(detail.endDate)})',
                style: context.text.titleMedium,
              ),
            ),
            InkWell(
              onTap: () => context.push(
                AppRouter.mealPlan,
                extra: const MealPlanArgs(initialTabIndex: 0),
              ),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  'View Plan',
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Upcoming meals carousel.
        _UpcomingMealsCarousel(meals: detail.upcomingMeals),
        const SizedBox(height: AppSpacing.xl),

        // Grocery categories.
        ...detail.categories.map(
          (category) => _GroceryCategoryCard(category: category),
        ),
      ],
    );
  }
}

/// Upcoming meals carousel widget.
class _UpcomingMealsCarousel extends StatelessWidget {
  /// List of upcoming meals.
  final List<ManageUpcomingMeal> meals;

  /// Creates a new upcoming meals carousel instance.
  const _UpcomingMealsCarousel({required this.meals});

  @override
  Widget build(BuildContext context) {
    // Show empty state if no meals.
    if (meals.isEmpty) {
      return Container(
        width: double.infinity,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F8EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'No meals are linked to this grocery list yet.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    // Build carousel with responsive card width.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compact cards reduce image letterboxing while staying readable.
        final cardWidth = (constraints.maxWidth * 0.52).clamp(172.0, 202.0);
        return SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: meals.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) =>
                _UpcomingMealCard(meal: meals[index], width: cardWidth),
          ),
        );
      },
    );
  }
}

/// Upcoming meal card widget.
class _UpcomingMealCard extends StatelessWidget {
  /// The meal data.
  final ManageUpcomingMeal meal;

  /// Card width.
  final double width;

  /// Creates a new upcoming meal card instance.
  const _UpcomingMealCard({required this.meal, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // Meal image.
              Container(
                width: 88,
                height: double.infinity,
                padding: const EdgeInsets.all(5),
                color: const Color(0xFFF6F7F6),
                child: _MealImage(
                  path: meal.imagePath,
                  width: 78,
                  height: 94,
                  fit: BoxFit.contain,
                ),
              ),
              // Meal details.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MealPill(
                        icon: Icons.calendar_today,
                        label: DateFormat('d MMM').format(meal.date),
                      ),
                      Text(
                        meal.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      _MealPill(
                        icon: _mealTypeIcon(meal.mealType),
                        label: meal.mealType,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the icon for a meal type.
  IconData _mealTypeIcon(String mealType) {
    final value = mealType.toLowerCase();
    if (value.contains('breakfast')) return Icons.wb_sunny_outlined;
    if (value.contains('lunch')) return Icons.wb_twilight_outlined;
    if (value.contains('dinner')) return Icons.nights_stay_outlined;
    return Icons.restaurant_outlined;
  }
}

/// Meal pill widget.
class _MealPill extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Label text.
  final String label;

  /// Creates a new meal pill instance.
  const _MealPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 124),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Returns an icon for an ingredient category.
IconData _ingredientCategoryIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('dairy') || value.contains('drink')) {
    return Icons.local_drink_outlined;
  }
  if (value.contains('meat') ||
      value.contains('protein') ||
      value.contains('seafood')) {
    return Icons.set_meal_outlined;
  }
  if (value.contains('bakery') ||
      value.contains('bread') ||
      value.contains('grain')) {
    return Icons.bakery_dining_outlined;
  }
  if (value.contains('snack')) return Icons.cookie_outlined;
  if (value.contains('spice') || value.contains('sauce')) {
    return Icons.soup_kitchen_outlined;
  }
  if (value.contains('frozen')) return Icons.ac_unit_outlined;
  return Icons.eco_outlined;
}

/// Grocery category card widget.
class _GroceryCategoryCard extends StatelessWidget {
  /// The category data.
  final ManageGroceryCategory category;

  /// Creates a new grocery category card instance.
  const _GroceryCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    // Filter visible items.
    final visibleItems = category.items
        .where((item) => viewModel.shouldShowItem(item.id))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        childrenPadding: EdgeInsets.zero,
        backgroundColor: const Color(0xFFFBFCFB),
        collapsedBackgroundColor: const Color(0xFFFBFCFB),
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F8EB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _ingredientCategoryIcon(category.title),
                color: AppColors.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                category.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        trailing: _CountBadge(
          label:
              '${visibleItems.length} item${visibleItems.length == 1 ? '' : 's'}',
        ),
        children: visibleItems.asMap().entries.map((entry) {
          return _GroceryItemRow(
            item: entry.value,
            showDivider: entry.key < visibleItems.length - 1,
          );
        }).toList(),
      ),
    );
  }
}

/// Grocery item row widget.
class _GroceryItemRow extends StatelessWidget {
  /// The item data.
  final ManageGroceryItem item;

  /// Whether to show a divider.
  final bool showDivider;

  /// Creates a new grocery item row instance.
  const _GroceryItemRow({required this.item, required this.showDivider});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<ManageGroceryListViewModel>();

    // Check if item is bought.
    final bought = viewModel.isBought(item.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.65),
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 7, 4, 7),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.9,
            child: Checkbox(
              value: bought,
              activeColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
              onChanged: (_) => context
                  .read<ManageGroceryListViewModel>()
                  .toggleBought(item.id),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Opacity(
              opacity: bought ? 0.55 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w400,
                      decoration: bought ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (item.quantityLabel.trim().isNotEmpty)
                    Text(
                      item.quantityLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            tooltip: 'Delete ingredient',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(34, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: viewModel.isSaving
                ? null
                : () => context.read<ManageGroceryListViewModel>().deleteItem(
                    item.id,
                  ),
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      ),
    );
  }
}

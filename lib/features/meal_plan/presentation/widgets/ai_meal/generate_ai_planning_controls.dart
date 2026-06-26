part of '../../view/planning/generate_ai_meal_page.dart';

/// Planning controls and empty/error widgets for AI meal generation.
///
/// Date scrollers, meal type chips, action buttons, and terminal states live here.
class _DateScroller extends StatelessWidget {
  /// Selected date.
  final DateTime selectedDate;

  /// Callback when a date is selected.
  final ValueChanged<DateTime> onSelected;

  /// Creates a new date scroller instance.
  const _DateScroller({required this.selectedDate, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    // Generate 7 days starting from 2 days before selected.
    final start = selectedDate.subtract(const Duration(days: 2));
    final days = List.generate(7, (index) => start.add(Duration(days: index)));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          // Header.
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text('Choose Date', style: context.text.titleMedium),
              const Spacer(),
              Text(
                DateFormat('MMM yyyy').format(selectedDate),
                style: context.text.bodySmall,
              ),
              IconButton(
                tooltip: 'Open calendar',
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) onSelected(picked);
                },
                icon: const Icon(Icons.event_outlined, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Day grid.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((date) {
              final selected = DateUtils.isSameDay(date, selectedDate);
              return Column(
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  InkWell(
                    onTap: () => onSelected(date),
                    customBorder: const CircleBorder(),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: selected
                          ? AppColors.primary
                          : Colors.transparent,
                      child: Text(
                        '${date.day}',
                        style: context.text.bodySmall?.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Recipe thumbnail widget.
class _RecipeThumb extends StatelessWidget {
  /// Recipe data.
  final AddMealAiRecipe recipe;

  /// Size of the thumbnail.
  final double size;

  /// Creates a new recipe thumb instance.
  const _RecipeThumb({required this.recipe, required this.size});

  @override
  Widget build(BuildContext context) {
    // Get the image base64 data.
    final imageBase64 = recipe.imageBase64;

    // Show base64 image if available.
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      return Image.memory(
        base64Decode(imageBase64),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _assetImage(),
      );
    }

    // Fallback to asset image.
    return _assetImage();
  }

  /// Returns the asset image widget.
  Widget _assetImage() {
    return Image.asset(
      recipe.imagePath,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}

/// Planned meal rows widget.
class _PlannedMealRows extends StatelessWidget {
  /// Selected meal type.
  final String mealType;

  /// Creates a new planned meal rows instance.
  const _PlannedMealRows({required this.mealType});

  @override
  Widget build(BuildContext context) {
    // Define meal options.
    const meals = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
      child: Column(
        children: meals.map((meal) {
          final isSelected = meal.toLowerCase() == mealType.toLowerCase();
          return ListTile(
            dense: true,
            leading: Icon(
              isSelected ? Icons.wb_sunny_outlined : Icons.restaurant_outlined,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            title: Text(meal, style: context.text.bodyMedium),
            subtitle: Text(
              isSelected
                  ? 'Selected AI recipe will be added here'
                  : 'No meal planned yet',
              style: context.text.bodySmall,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Meal type chips widget.
class _MealTypeChips extends StatelessWidget {
  /// Selected meal type.
  final String selected;

  /// List of categories.
  final List<AddMealCategoryOption> categories;

  /// Callback when a category is selected.
  final ValueChanged<AddMealCategoryOption> onSelected;

  /// Creates a new meal type chips instance.
  const _MealTypeChips({
    required this.selected,
    required this.categories,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Use default categories if none provided.
    final meals = categories.isEmpty
        ? const [
            AddMealCategoryOption(id: 'breakfast', name: 'Breakfast'),
            AddMealCategoryOption(id: 'lunch', name: 'Lunch'),
            AddMealCategoryOption(id: 'dinner', name: 'Dinner'),
            AddMealCategoryOption(id: 'snack', name: 'Snack'),
          ]
        : categories;

    return Row(
      children: meals.map((meal) {
        final active = meal.name.toLowerCase() == selected.toLowerCase();
        return Expanded(
          child: InkWell(
            onTap: () => onSelected(meal),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 56,
              margin: const EdgeInsets.only(right: AppSpacing.xs),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFEAF7EC) : Colors.white,
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  meal.name,
                  style: context.text.bodySmall?.copyWith(
                    color: active ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Small chip widget.
class _SmallChip extends StatelessWidget {
  /// Label text.
  final String label;

  /// Whether selected.
  final bool selected;

  /// Whether to use danger styling.
  final bool danger;

  /// Creates a new small chip instance.
  const _SmallChip({
    required this.label,
    this.selected = true,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine active color.
    final activeColor = danger ? AppColors.error : AppColors.textPrimary;

    // Determine fill color.
    final selectedFill = danger
        ? AppColors.error.withValues(alpha: 0.08)
        : const Color(0xFFF2F4F2);
    final inactiveColor = danger
        ? AppColors.error.withValues(alpha: 0.035)
        : Colors.white;
    final borderColor = selected
        ? danger
              ? AppColors.error.withValues(alpha: 0.32)
              : AppColors.textPrimary.withValues(alpha: 0.18)
        : AppColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: selected ? selectedFill : inactiveColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            Icon(
              Icons.check,
              size: 12,
              color: danger ? AppColors.error : AppColors.primary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: selected ? activeColor : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill widget.
class _Pill extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Label text.
  final String label;

  /// Creates a new pill instance.
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: context.text.bodySmall),
        ],
      ),
    );
  }
}

/// Primary action button widget.
class _PrimaryActionButton extends StatelessWidget {
  /// Button label.
  final String label;

  /// Callback when pressed.
  final VoidCallback? onPressed;

  /// Creates a new primary action button instance.
  const _PrimaryActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: context.text.labelLarge?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

/// Empty selected recipe widget.
class _EmptySelectedRecipe extends StatelessWidget {
  /// Creates a new empty selected recipe instance.
  const _EmptySelectedRecipe();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Image.asset('assets/images/empty_page.png', height: 110),
          const SizedBox(height: AppSpacing.sm),
          Text('No recipe selected yet', style: context.text.bodyMedium),
        ],
      ),
    );
  }
}

/// Error state widget.
class _ErrorState extends StatelessWidget {
  /// Error message.
  final String message;

  /// Callback when retry is pressed.
  final Future<void> Function() onRetry;

  /// Creates a new error state instance.
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', height: 140),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

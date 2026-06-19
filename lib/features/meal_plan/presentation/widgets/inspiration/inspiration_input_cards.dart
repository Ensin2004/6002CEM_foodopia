part of 'inspiration_tab_main_view.dart';

/// Input cards for building an inspiration request.
///
/// Weather, ingredient, and preference cards live together for scanning.
/// Weather input card widget.
class _WeatherInputCard extends StatelessWidget {
  /// Weather data.
  final MealPlanWeather? weather;

  /// Whether loading.
  final bool isLoading;

  /// Error message.
  final String? errorMessage;

  /// Selected weather category ID.
  final String selectedCategoryId;

  /// Callback when weather category changes.
  final ValueChanged<String> onChanged;

  /// Creates a new weather input card instance.
  const _WeatherInputCard({
    required this.weather,
    required this.isLoading,
    this.errorMessage,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Get current weather.
    final currentWeather = weather;

    // Build title and message.
    final title = isLoading
        ? 'Loading weather'
        : currentWeather == null
        ? 'Weather unavailable'
        : '${currentWeather.condition} - ${currentWeather.currentTemp}C';
    final message =
        currentWeather?.summary ??
        errorMessage ??
        'Weather data will appear here.';

    return _InputCard(
      icon: Icons.wb_sunny_outlined,
      title: 'Weather',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weather category dropdown.
          DropdownButtonFormField<String>(
            initialValue: selectedCategoryId,
            isExpanded: true,
            style: context.text.bodyMedium,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'sunny', child: Text('Sunny')),
              DropdownMenuItem(value: 'rainy', child: Text('Rainy')),
              DropdownMenuItem(value: 'windy', child: Text('Windy')),
              DropdownMenuItem(value: 'cloudy', child: Text('Cloudy')),
              DropdownMenuItem(value: 'hot', child: Text('Hot')),
              DropdownMenuItem(value: 'cool', child: Text('Cool')),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
          const SizedBox(height: AppSpacing.sm),

          // Weather details.
          Text(title, style: context.text.bodyMedium),
          const SizedBox(height: 4),
          Text(
            message,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ingredient input card widget.
class _IngredientInputCard extends StatelessWidget {
  /// The view model.
  final MealPlanViewModel viewModel;

  /// Creates a new ingredient input card instance.
  const _IngredientInputCard({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    // Get selected ingredients.
    final selected = viewModel.selectedIngredients;

    return _InputCard(
      icon: Icons.shopping_cart_outlined,
      title: 'Add ingredients you have',
      onTap: () => _showIngredientSheet(context, viewModel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected ingredients chips or empty message.
          if (selected.isEmpty)
            Text(
              'Search foods or add a custom ingredient.',
              style: context.text.bodyMedium?.copyWith(height: 1.35),
            )
          else
            _IngredientChips(
              ingredients: selected,
              isSelected: (_) => true,
              onTap: viewModel.toggleIngredient,
            ),
          const SizedBox(height: AppSpacing.sm),

          // Add ingredient action.
          _AddIngredientAction(
            label: selected.isEmpty ? 'Add ingredient' : 'Add another',
          ),
        ],
      ),
    );
  }

  /// Shows the ingredient picker bottom sheet.
  void _showIngredientSheet(BuildContext context, MealPlanViewModel viewModel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const _IngredientPickerSheet(),
      ),
    );
  }
}

/// Add ingredient action button.
class _AddIngredientAction extends StatelessWidget {
  /// Button label.
  final String label;

  /// Creates a new add ingredient action instance.
  const _AddIngredientAction({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.add_circle_outline,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: context.text.labelLarge?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// Preference input card widget.
class _PreferenceInputCard extends StatelessWidget {
  /// User preferences.
  final MealPlanPreferenceSummary? preferences;

  /// Callback when expanded.
  final VoidCallback onExpand;

  /// Creates a new preference input card instance.
  const _PreferenceInputCard({
    required this.preferences,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    // Get preference values.
    final mealPreference = preferences?.diet ?? 'Any';
    final allergy = preferences?.allergies.isNotEmpty == true
        ? preferences!.allergies.first
        : 'Any';
    final dislike = preferences?.dislikes.isNotEmpty == true
        ? preferences!.dislikes.first
        : 'Any';

    return _InputCard(
      icon: Icons.room_service_outlined,
      title: 'Set your preferences',
      trailing: Icons.chevron_right,
      onTap: onExpand,
      child: Row(
        children: [
          Expanded(
            child: _PreferenceMetric(
              icon: Icons.restaurant_menu,
              title: 'Meal Pref.',
              value: mealPreference,
            ),
          ),
          Expanded(
            child: _PreferenceMetric(
              icon: Icons.warning_amber_outlined,
              title: 'Allergies',
              value: allergy,
            ),
          ),
          Expanded(
            child: _PreferenceMetric(
              icon: Icons.block,
              title: 'Dislikes',
              value: dislike,
            ),
          ),
        ],
      ),
    );
  }
}

/// Preference metric widget.
class _PreferenceMetric extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Title text.
  final String title;

  /// Value text.
  final String value;

  /// Creates a new preference metric instance.
  const _PreferenceMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Input card widget.
class _InputCard extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Title text.
  final String title;

  /// Child widget.
  final Widget child;

  /// Trailing icon.
  final IconData? trailing;

  /// Callback when tapped.
  final VoidCallback? onTap;

  /// Creates a new input card instance.
  const _InputCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container.
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 21, color: const Color(0xFF8A6400)),
            ),
            const SizedBox(width: AppSpacing.md),

            // Content.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (trailing != null)
                        Icon(
                          trailing,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ingredient chips widget.
class _IngredientChips extends StatelessWidget {
  /// List of ingredients.
  final List<MealPlanInspirationIngredient> ingredients;

  /// Function to check if an ingredient is selected.
  final bool Function(MealPlanInspirationIngredient ingredient) isSelected;

  /// Callback when an ingredient is tapped.
  final ValueChanged<MealPlanInspirationIngredient> onTap;

  /// Creates a new ingredient chips instance.
  const _IngredientChips({
    required this.ingredients,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final ingredient in ingredients)
          _MiniChoiceChip(
            label: ingredient.name,
            selected: isSelected(ingredient),
            onTap: () => onTap(ingredient),
          ),
      ],
    );
  }
}

/// Mini choice chip widget.
class _MiniChoiceChip extends StatelessWidget {
  /// Chip label.
  final String label;

  /// Whether selected.
  final bool selected;

  /// Callback when tapped.
  final VoidCallback onTap;

  /// Creates a new mini choice chip instance.
  const _MiniChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF6F7F6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodySmall?.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

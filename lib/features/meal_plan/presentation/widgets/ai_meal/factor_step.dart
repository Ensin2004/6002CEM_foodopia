part of '../../view/planning/generate_ai_meal_page.dart';

/// Factor input widgets for the AI meal generation flow.
///
/// Weather, ingredient, preference, and cooking controls are grouped by setup flow.
class _StepBody extends StatelessWidget {
  /// The meal plan data.
  final AddMealAiPlan plan;

  /// Creates a new step body instance.
  const _StepBody({required this.plan});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Get the current step.
    final step = viewModel.currentStep;

    // Show loading if in inspiration flow and on step 1.
    if (viewModel.sourceRequest != null && step == 1) {
      return const LoadingDialog(
        inline: true,
        message: 'Generating AI recipes and images...',
      );
    }

    // Render the appropriate step content.
    switch (step) {
      case 2:
        return _AiResultsStep(plan: plan);
      case 3:
        return const _InstructionsStep();
      case 4:
        return _ReviewStep(plan: plan);
      default:
        return _FactorStep(plan: plan);
    }
  }
}

/// Step 1: Factor selection step.
/// Allows users to configure AI generation parameters.
class _FactorStep extends StatelessWidget {
  /// The meal plan data.
  final AddMealAiPlan plan;

  /// Creates a new factor step instance.
  const _FactorStep({required this.plan});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        // Informational tip box.
        const AppTipBox(
          title: 'Foodopia AI will suggest meal ideas',
          message:
              'Based on time of day, weather, ingredients you have, your preferences and dietary needs.',
          backgroundColor: Color(0xFFFFF8E1),
          iconColor: AppColors.secondary,
          icon: Icons.smart_toy_outlined,
        ),
        const SizedBox(height: AppSpacing.md),

        // Mini info tiles for meal type and date.
        Row(
          children: [
            Expanded(
              child: _MiniInfoTile(
                icon: Icons.wb_sunny_outlined,
                label: 'Planning for',
                value: plan.mealType,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MiniInfoTile(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: DateFormat('EEE, d MMM yyyy').format(plan.planningDate),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Section header.
        Text('Consider These Factors', style: context.text.titleMedium),
        const SizedBox(height: 2),

        // Section subtitle.
        Text(
          'AI will use these information to generate the best suggestions for you.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Factor cards.
        const _WeatherFactorCard(),
        const _IngredientFactorCard(
          type: _IngredientFactorType.include,
          icon: Icons.shopping_cart_outlined,
          title: 'Ingredients to Include',
          subtitle: 'Search USDA foods or add ingredients AI should include.',
        ),
        _MealPreferenceFactorCard(plan: plan),
        const _IngredientFactorCard(
          type: _IngredientFactorType.avoid,
          icon: Icons.block,
          title: 'Ingredients to Avoid',
          subtitle: 'Dislikes from settings are selected by default.',
        ),
        _DishPreferenceFactorCard(plan: plan),
        const _CookingPreferenceFactorCard(),
        const SizedBox(height: AppSpacing.lg),

        // Generate button.
        _PrimaryActionButton(
          label: 'Generate Recipe',
          onPressed: context.read<GenerateAiMealViewModel>().goToResults,
        ),
      ],
    );
  }
}

/// Weather factor card for AI generation.
class _WeatherFactorCard extends StatelessWidget {
  /// Creates a new weather factor card instance.
  const _WeatherFactorCard();

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Get the selected weather snapshot.
    final weather = viewModel.selectedWeatherSnapshot;

    return _ExpandableFactorCard(
      icon: Icons.wb_cloudy_outlined,
      title: 'Weather',
      subtitle: '${weather.condition} - ${weather.temperature}C',
      selectedLabels: [weather.summary],
      children: [
        // Weather category dropdown.
        DropdownButtonFormField<String>(
          initialValue: viewModel.selectedWeatherCategoryId,
          isExpanded: true,
          style: context.text.bodyMedium,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          items: [
            for (final category in viewModel.weatherCategories)
              DropdownMenuItem(value: category.id, child: Text(category.label)),
          ],
          onChanged: (value) {
            if (value != null) {
              context.read<GenerateAiMealViewModel>().selectWeatherCategory(
                value,
              );
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _SelectedSummaryText(weather.summary),
      ],
    );
  }
}

/// Type of ingredient factor (include or avoid).
enum _IngredientFactorType { include, avoid }

/// Ingredient factor card for AI generation.
class _IngredientFactorCard extends StatelessWidget {
  /// Type of ingredient factor.
  final _IngredientFactorType type;

  /// Icon to display.
  final IconData icon;

  /// Title of the card.
  final String title;

  /// Subtitle of the card.
  final String subtitle;

  /// Creates a new ingredient factor card instance.
  const _IngredientFactorCard({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Get selected ingredients based on type.
    final selected = type == _IngredientFactorType.include
        ? viewModel.selectedIngredientsToInclude
        : viewModel.selectedIngredientsToAvoid;

    return _ExpandableFactorCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      selectedLabels: selected,
      children: [
        // Ingredient preview panel.
        _IngredientPreviewPanel(
          type: type,
          selected: selected,
          defaultValues: type == _IngredientFactorType.include
              ? viewModel.defaultIngredientsToInclude
              : viewModel.defaultIngredientsToAvoid,
          onRemove: type == _IngredientFactorType.include
              ? context
                    .read<GenerateAiMealViewModel>()
                    .toggleIngredientToInclude
              : context.read<GenerateAiMealViewModel>().toggleIngredientToAvoid,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Edit ingredients button.
        Align(
          alignment: Alignment.centerLeft,
          child: _AddFactorAction(
            label: selected.isEmpty ? 'Add ingredient' : 'Edit ingredients',
            onTap: () => _showIngredientSheet(context, type),
          ),
        ),
      ],
    );
  }

  /// Shows the ingredient picker sheet.
  void _showIngredientSheet(BuildContext context, _IngredientFactorType type) {
    // Get the view model.
    final viewModel = context.read<GenerateAiMealViewModel>();

    // Show bottom sheet.
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: _IngredientPickerSheet(type: type),
      ),
    );
  }
}

/// Add factor action button.
class _AddFactorAction extends StatelessWidget {
  /// Button label.
  final String label;

  /// Callback when tapped.
  final VoidCallback onTap;

  /// Creates a new add factor action instance.
  const _AddFactorAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
              style: context.text.labelLarge?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview panel for selected ingredients.
class _IngredientPreviewPanel extends StatelessWidget {
  /// Type of ingredient factor.
  final _IngredientFactorType type;

  /// List of selected ingredients.
  final List<String> selected;

  /// List of default values.
  final List<String> defaultValues;

  /// Callback when an ingredient is removed.
  final ValueChanged<String> onRemove;

  /// Creates a new ingredient preview panel instance.
  const _IngredientPreviewPanel({
    required this.type,
    required this.selected,
    required this.defaultValues,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if this is the avoid type.
    final isAvoid = type == _IngredientFactorType.avoid;

    // Create a set of selected values for quick lookup.
    final selectedSet = selected.map((item) => item.toLowerCase()).toSet();

    // Find defaults that are not selected.
    final inactiveDefaults = defaultValues
        .where((item) => !selectedSet.contains(item.toLowerCase()))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with count badge.
          Row(
            children: [
              Icon(
                isAvoid
                    ? Icons.shield_outlined
                    : Icons.shopping_basket_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  isAvoid
                      ? 'Selected for AI to avoid'
                      : 'Selected for AI to include',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _CountBadge(count: selected.length),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Selected ingredients chips or empty message.
          if (selected.isEmpty)
            Text(
              isAvoid
                  ? 'No allergies or dislikes selected for this request.'
                  : 'No ingredients selected for this request.',
              style: context.text.bodySmall,
            )
          else
            _RemovableChipWrap(
              values: selected,
              danger: isAvoid,
              onRemove: onRemove,
            ),

          // Inactive defaults preview.
          if (inactiveDefaults.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Deselected defaults: ${inactiveDefaults.take(3).join(', ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Count badge widget.
class _CountBadge extends StatelessWidget {
  /// The count to display.
  final int count;

  /// Creates a new count badge instance.
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: context.text.bodySmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Removable chip wrap widget.
class _RemovableChipWrap extends StatelessWidget {
  /// List of values to display as chips.
  final List<String> values;

  /// Whether to use danger styling.
  final bool danger;

  /// Callback when a chip is removed.
  final ValueChanged<String> onRemove;

  /// Creates a new removable chip wrap instance.
  const _RemovableChipWrap({
    required this.values,
    required this.danger,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final value in values)
          InputChip(
            label: Text(value),
            onDeleted: () => onRemove(value),
            deleteIcon: const Icon(Icons.close, size: 16),
            visualDensity: VisualDensity.compact,
            backgroundColor: danger
                ? AppColors.error.withValues(alpha: 0.08)
                : AppColors.primary.withValues(alpha: 0.1),
            side: BorderSide(
              color: danger
                  ? AppColors.error.withValues(alpha: 0.25)
                  : AppColors.primary.withValues(alpha: 0.25),
            ),
            labelStyle: context.text.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

/// Ingredient picker bottom sheet.
class _IngredientPickerSheet extends StatefulWidget {
  /// Type of ingredient factor.
  final _IngredientFactorType type;

  /// Creates a new ingredient picker sheet instance.
  const _IngredientPickerSheet({required this.type});

  @override
  State<_IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

/// State for the ingredient picker sheet.
class _IngredientPickerSheetState extends State<_IngredientPickerSheet> {
  /// Text controller for search input.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Get bottom inset for keyboard.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    // Determine if this is the avoid type.
    final isAvoid = widget.type == _IngredientFactorType.avoid;

    // Get selected ingredients based on type.
    final selected = isAvoid
        ? viewModel.selectedIngredientsToAvoid
        : viewModel.selectedIngredientsToInclude;

    // Get toggle function based on type.
    final toggle = isAvoid
        ? viewModel.toggleIngredientToAvoid
        : viewModel.toggleIngredientToInclude;

    // Get add custom function based on type.
    final addCustom = isAvoid
        ? viewModel.addIngredientToAvoid
        : viewModel.addIngredientToInclude;

    // Get the search query.
    final query = _controller.text.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle.
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Header.
            Text(
              isAvoid ? 'Ingredients to avoid' : 'Ingredients to include',
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle.
            Text(
              isAvoid
                  ? 'Saved allergies and dislikes are selected for this request only.'
                  : 'Suggested ingredients are selected by default and can be adjusted.',
              style: context.text.bodyMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: AppSpacing.md),

            // Search input.
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search USDA foods or add custom ingredient',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    addCustom(_controller.text);
                    _controller.clear();
                    viewModel.searchFoods('');
                  },
                  icon: const Icon(Icons.add),
                ),
              ),
              onChanged: viewModel.searchFoods,
              onSubmitted: addCustom,
            ),
            const SizedBox(height: AppSpacing.md),

            // Scrollable content.
            Expanded(
              child: ListView(
                children: [
                  // Selected ingredients section.
                  _IngredientSheetSection(
                    title: 'Selected',
                    icon: Icons.check_circle_outline,
                    child: selected.isEmpty
                        ? Text(
                            'No ingredients selected yet.',
                            style: context.text.bodyMedium,
                          )
                        : _ChipWrap(
                            values: selected,
                            selectedValues: selected,
                            danger: isAvoid,
                            onSelected: toggle,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // From settings section (avoid only).
                  if (isAvoid) ...[
                    _IngredientSheetSection(
                      title: 'From Settings',
                      icon: Icons.person_outline,
                      child: viewModel.savedIngredientsToAvoid.isEmpty
                          ? Text(
                              'No allergies or dislikes saved in settings.',
                              style: context.text.bodyMedium,
                            )
                          : _ChipWrap(
                              values: viewModel.savedIngredientsToAvoid,
                              selectedValues: selected,
                              danger: true,
                              onSelected: toggle,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Allergen defaults section.
                    _IngredientSheetSection(
                      title: 'Allergen defaults',
                      icon: Icons.warning_amber_outlined,
                      child: _ConfigOptionChips(
                        isLoading: viewModel.isFactorOptionsLoading,
                        emptyMessage: 'No allergens available yet.',
                        options: viewModel.allergyOptions,
                        selectedValues: selected,
                        danger: true,
                        onSelected: toggle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Dislike defaults section.
                    _IngredientSheetSection(
                      title: 'Dislike defaults',
                      icon: Icons.block,
                      child: _ConfigOptionChips(
                        isLoading: viewModel.isFactorOptionsLoading,
                        emptyMessage: 'No dislikes available yet.',
                        options: viewModel.dislikeOptions,
                        selectedValues: selected,
                        danger: true,
                        onSelected: toggle,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),

                  // USDA search results section.
                  _IngredientSheetSection(
                    title: 'USDA search results',
                    icon: Icons.search,
                    child: viewModel.isFoodSearching
                        ? const LoadingDialog(
                            inline: true,
                            message: 'Searching foods...',
                          )
                        : query.length < 2
                        ? Text(
                            'Type at least 2 characters to search.',
                            style: context.text.bodyMedium,
                          )
                        : viewModel.foodSearchResults.isEmpty
                        ? Text(
                            'No results found.',
                            style: context.text.bodyMedium,
                          )
                        : _IngredientSearchResultChips(
                            ingredients: viewModel.foodSearchResults,
                            selectedValues: selected,
                            danger: isAvoid,
                            onSelected: (item) => toggle(item.name),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Done button.
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search result chips for ingredients.
class _IngredientSearchResultChips extends StatelessWidget {
  /// List of ingredients.
  final List<MealPlanInspirationIngredient> ingredients;

  /// List of selected values.
  final List<String> selectedValues;

  /// Whether to use danger styling.
  final bool danger;

  /// Callback when an ingredient is selected.
  final ValueChanged<MealPlanInspirationIngredient> onSelected;

  /// Creates a new search result chips instance.
  const _IngredientSearchResultChips({
    required this.ingredients,
    required this.selectedValues,
    required this.danger,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Create a set of selected values for quick lookup.
    final selectedSet = selectedValues
        .map((item) => item.toLowerCase())
        .toSet();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final ingredient in ingredients)
          InkWell(
            onTap: () => onSelected(ingredient),
            borderRadius: BorderRadius.circular(12),
            child: _SmallChip(
              label: ingredient.name,
              selected: selectedSet.contains(ingredient.name.toLowerCase()),
              danger: danger,
            ),
          ),
      ],
    );
  }
}

/// Section widget for the ingredient picker sheet.
class _IngredientSheetSection extends StatelessWidget {
  /// Section title.
  final String title;

  /// Section icon.
  final IconData icon;

  /// Section child content.
  final Widget child;

  /// Creates a new ingredient sheet section instance.
  const _IngredientSheetSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title.
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: const Color(0xFF8A6400)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Configuration option chips widget.
class _ConfigOptionChips extends StatelessWidget {
  /// Whether loading.
  final bool isLoading;

  /// Empty state message.
  final String emptyMessage;

  /// List of options.
  final List<MealPlanPreferenceOption> options;

  /// List of selected values.
  final List<String> selectedValues;

  /// Whether to use danger styling.
  final bool danger;

  /// Callback when an option is selected.
  final ValueChanged<String> onSelected;

  /// Creates a new config option chips instance.
  const _ConfigOptionChips({
    required this.isLoading,
    required this.emptyMessage,
    required this.options,
    required this.selectedValues,
    required this.danger,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading indicator.
    if (isLoading) {
      return const LoadingDialog(inline: true, message: 'Loading defaults...');
    }

    // Show empty message.
    if (options.isEmpty) {
      return Text(emptyMessage, style: context.text.bodyMedium);
    }

    // Show chips.
    return _ChipWrap(
      values: options.map((item) => item.name).toList(),
      selectedValues: selectedValues,
      danger: danger,
      onSelected: onSelected,
    );
  }
}

/// Meal preference factor card.
class _MealPreferenceFactorCard extends StatelessWidget {
  /// The meal plan data.
  final AddMealAiPlan plan;

  /// Creates a new meal preference factor card instance.
  const _MealPreferenceFactorCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Build options list from preferences and selected values.
    final options = {
      ...viewModel.mealPreferenceOptions.map((item) => item.name),
      ...viewModel.selectedMealPreferences,
    }.toList();

    return _ExpandableFactorCard(
      icon: Icons.favorite,
      title: 'Meal Preferences',
      subtitle: 'Values from Settings can be adjusted for this request.',
      selectedLabels: viewModel.selectedMealPreferences.isEmpty
          ? const ['No Preference']
          : viewModel.selectedMealPreferences,
      children: [
        // Show loading or options.
        if (viewModel.isFactorOptionsLoading)
          const LoadingDialog(inline: true, message: 'Loading preferences...')
        else if (options.isEmpty)
          Text('No meal preferences available.', style: context.text.bodySmall)
        else
          _ChipWrap(
            values: options,
            selectedValues: viewModel.selectedMealPreferences,
            onSelected: context
                .read<GenerateAiMealViewModel>()
                .toggleMealPreference,
          ),
      ],
    );
  }
}

/// Dish preference factor card.
class _DishPreferenceFactorCard extends StatelessWidget {
  /// The meal plan data.
  final AddMealAiPlan plan;

  /// Creates a new dish preference factor card instance.
  const _DishPreferenceFactorCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    return _ExpandableFactorCard(
      icon: Icons.no_meals_outlined,
      title: 'Dish Preference',
      subtitle: 'Choose dish types AI should include or avoid.',
      selectedLabels: [
        ...viewModel.selectedDishIncludes,
        ...viewModel.selectedDishAvoids,
      ],
      children: [
        _SectionLabel('Include examples'),
        const SizedBox(height: AppSpacing.xs),
        _ChipWrap(values: plan.dishPreferences, selectedValues: const []),
        const SizedBox(height: AppSpacing.sm),
        _WordLimitedTextInput(
          hintText: 'Type dish to include, e.g. grilled rice bowl',
          onChanged: context
              .read<GenerateAiMealViewModel>()
              .updateDishIncludeText,
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionLabel('Avoid examples'),
        const SizedBox(height: AppSpacing.xs),
        const _ChipWrap(
          values: ['Soup', 'Fried', 'Spicy', 'Oily', 'Creamy'],
          selectedValues: [],
          danger: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        _WordLimitedTextInput(
          hintText: 'Type dish to avoid, e.g. spicy soup',
          onChanged: context
              .read<GenerateAiMealViewModel>()
              .updateDishAvoidText,
        ),
      ],
    );
  }
}

/// Cooking preference factor card.
class _CookingPreferenceFactorCard extends StatelessWidget {
  /// Creates a new cooking preference factor card instance.
  const _CookingPreferenceFactorCard();

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Build selected labels.
    final selectedLabels = [
      'Cooking: ${viewModel.selectedCookingTime} mins',
      'Difficulty: ${viewModel.selectedDifficulty}',
      'Serving: ${viewModel.selectedServingSize}',
    ];

    return _ExpandableFactorCard(
      icon: Icons.soup_kitchen_outlined,
      title: 'Cooking Preferences',
      subtitle: 'Cooking time, difficulty and serving size.',
      selectedLabels: selectedLabels,
      children: [
        _CookingMinutesInput(
          minutes: viewModel.selectedCookingTime,
          onChanged: context.read<GenerateAiMealViewModel>().updateCookingTime,
        ),
        const SizedBox(height: AppSpacing.md),
        _DifficultyLevelPicker(
          selectedLevel: viewModel.selectedDifficultyLevel,
          onSelected: context.read<GenerateAiMealViewModel>().selectDifficulty,
        ),
        const SizedBox(height: AppSpacing.md),
        _ServingSizeInput(
          servings: viewModel.selectedServingCount,
          onChanged: context.read<GenerateAiMealViewModel>().selectServingSize,
        ),
      ],
    );
  }
}

/// Step 2: AI results step.

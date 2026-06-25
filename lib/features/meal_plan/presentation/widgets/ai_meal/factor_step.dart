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
        _GenerateAiFactorFormContent(
          plan: plan,
          onGenerate: context.read<GenerateAiMealViewModel>().goToResults,
        ),
      ],
    );
  }
}

/// Shared AI factor form content.
class _GenerateAiFactorFormContent extends StatelessWidget {
  /// The meal plan data.
  final AddMealAiPlan plan;

  /// Callback when the generate action is pressed.
  final VoidCallback onGenerate;

  /// Creates a new shared AI factor form content instance.
  const _GenerateAiFactorFormContent({
    required this.plan,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informational tip box.
        const AppTipBox(
          title: 'Foodopia AI will build recipe ideas',
          message:
              'Set the details that matter for this meal. Anything flexible can stay as Any.',
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
        Text('Customize Your Recipe', style: context.text.titleMedium),
        const SizedBox(height: 2),

        // Section subtitle.
        Text(
          'Tap chips to choose examples, or open a section to add your own details.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Factor cards.
        const _WeatherFactorCard(),
        const _IngredientFactorCard(
          type: _IngredientFactorType.include,
          icon: Icons.shopping_cart_outlined,
          title: 'Ingredients to Include',
          subtitle: 'Search foods or add ingredients AI should include.',
        ),
        const _AllergyFactorCard(),
        const _FoodDislikeFactorCard(),
        _MealPreferenceFactorCard(plan: plan),
        const _CuisineStyleFactorCard(),
        _DishPreferenceFactorCard(plan: plan),
        const _CookingMethodFactorCard(),
        const _SpiceLevelFactorCard(),
        const _CookingPreferenceFactorCard(),
        const _ExtraPreferencesFactorCard(),
        const SizedBox(height: AppSpacing.lg),

        // Generate button.
        _PrimaryActionButton(
          label: 'Generate Recipe',
          onPressed: () => _submitForm(context),
        ),
      ],
    );
  }

  /// Validates and submits the form.
  void _submitForm(BuildContext context) {
    final viewModel = context.read<GenerateAiMealViewModel>();
    final error = viewModel.validateGenerationRequest();
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }

    onGenerate();
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
      childrenBuilder: (context) {
        final sheetViewModel = context.watch<GenerateAiMealViewModel>();
        final sheetWeather = sheetViewModel.selectedWeatherSnapshot;

        return [
          // Weather category dropdown.
          DropdownButtonFormField<String>(
            initialValue: sheetViewModel.selectedWeatherCategoryId,
            isExpanded: true,
            style: context.text.bodyMedium,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            items: [
              for (final category in sheetViewModel.weatherCategories)
                DropdownMenuItem(
                  value: category.id,
                  child: Text(category.label),
                ),
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
          _SelectedSummaryText(sheetWeather.summary),
        ];
      },
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
      childrenBuilder: (context) {
        final sheetViewModel = context.watch<GenerateAiMealViewModel>();
        final sheetSelected = type == _IngredientFactorType.include
            ? sheetViewModel.selectedIngredientsToInclude
            : sheetViewModel.selectedIngredientsToAvoid;

        return [
          // Ingredient preview panel.
          _IngredientPreviewPanel(
            type: type,
            selected: sheetSelected,
            defaultValues: type == _IngredientFactorType.include
                ? sheetViewModel.defaultIngredientsToInclude
                : sheetViewModel.defaultIngredientsToAvoid,
            onRemove: type == _IngredientFactorType.include
                ? context
                      .read<GenerateAiMealViewModel>()
                      .toggleIngredientToInclude
                : context
                      .read<GenerateAiMealViewModel>()
                      .toggleIngredientToAvoid,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Edit ingredients button.
          Align(
            alignment: Alignment.centerLeft,
            child: _AddFactorAction(
              label: sheetSelected.isEmpty
                  ? 'Add ingredient'
                  : 'Edit ingredients',
              onTap: () => _showIngredientSheet(context, type),
            ),
          ),
        ];
      },
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

/// Allergy factor card for AI generation.
class _AllergyFactorCard extends StatelessWidget {
  /// Creates a new allergy factor card instance.
  const _AllergyFactorCard();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();

    return _ExpandableFactorCard(
      icon: Icons.health_and_safety_outlined,
      title: 'Allergies',
      subtitle: 'Allergies from Settings are selected by default for safety.',
      selectedLabels: viewModel.selectedAllergies.isEmpty
          ? const ['No allergies selected']
          : viewModel.selectedAllergies,
      childrenBuilder: (context) {
        final sheetViewModel = context.watch<GenerateAiMealViewModel>();
        final sheetOptions = {
          ...sheetViewModel.defaultAllergies,
          ...sheetViewModel.allergyOptions.map((item) => item.name),
          ...sheetViewModel.selectedAllergies,
        }.where((item) => item.trim().isNotEmpty).toList();

        return [
          if (sheetViewModel.isFactorOptionsLoading)
            const LoadingDialog(inline: true, message: 'Loading allergies...')
          else if (sheetOptions.isEmpty)
            Text(
              'No allergies saved or configured.',
              style: context.text.bodySmall,
            )
          else
            _ChipWrap(
              values: sheetOptions,
              selectedValues: sheetViewModel.selectedAllergies,
              danger: true,
              onSelected: context.read<GenerateAiMealViewModel>().toggleAllergy,
            ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: _AddFactorAction(
              icon: Icons.search,
              label: 'Search or add allergy',
              onTap: () => _showAllergyIngredientSheet(context),
            ),
          ),
        ];
      },
    );
  }

  /// Shows the allergy search sheet for custom allergy values.
  void _showAllergyIngredientSheet(BuildContext context) {
    final viewModel = context.read<GenerateAiMealViewModel>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const _IngredientPickerSheet(
          type: _IngredientFactorType.avoid,
          title: 'Search or add allergy',
          subtitle: 'Add allergy ingredients AI must avoid for this request.',
        ),
      ),
    );
  }
}

/// Food dislike and avoid ingredient factor card.
class _FoodDislikeFactorCard extends StatelessWidget {
  /// Creates a new food dislike factor card instance.
  const _FoodDislikeFactorCard();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();
    final selectedLabels = [
      ...viewModel.selectedFoodDislikes,
      ...viewModel.selectedCustomAvoidIngredients,
    ];

    return _ExpandableFactorCard(
      icon: Icons.block,
      title: 'Food Dislikes / Ingredients to Avoid',
      subtitle:
          'Dislikes from Settings are selected by default. Add more if needed.',
      selectedLabels: selectedLabels.isEmpty
          ? const ['No dislikes selected']
          : selectedLabels,
      childrenBuilder: (context) {
        final sheetViewModel = context.watch<GenerateAiMealViewModel>();
        final sheetOptions = {
          ...sheetViewModel.defaultDislikes,
          ...sheetViewModel.dislikeOptions.map((item) => item.name),
          ...sheetViewModel.selectedFoodDislikes,
        }.where((item) => item.trim().isNotEmpty).toList();

        return [
          if (sheetViewModel.isFactorOptionsLoading)
            const LoadingDialog(inline: true, message: 'Loading dislikes...')
          else if (sheetOptions.isEmpty)
            Text(
              'No dislikes saved or configured.',
              style: context.text.bodySmall,
            )
          else
            _ChipWrap(
              values: sheetOptions,
              selectedValues: sheetViewModel.selectedFoodDislikes,
              danger: true,
              onSelected: context
                  .read<GenerateAiMealViewModel>()
                  .toggleFoodDislike,
            ),
          const SizedBox(height: AppSpacing.sm),
          if (sheetViewModel.selectedCustomAvoidIngredients.isNotEmpty) ...[
            _SectionLabel('Custom avoid ingredients'),
            const SizedBox(height: AppSpacing.xs),
            _ChipWrap(
              values: sheetViewModel.selectedCustomAvoidIngredients,
              selectedValues: sheetViewModel.selectedCustomAvoidIngredients,
              danger: true,
              onSelected: context
                  .read<GenerateAiMealViewModel>()
                  .toggleIngredientToAvoid,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: _AddFactorAction(
              icon: Icons.search,
              label: 'Search or add avoid ingredient',
              onTap: () => _showAvoidIngredientSheet(context),
            ),
          ),
        ];
      },
    );
  }

  /// Shows the avoid ingredient sheet for custom avoid values.
  void _showAvoidIngredientSheet(BuildContext context) {
    final viewModel = context.read<GenerateAiMealViewModel>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const _IngredientPickerSheet(
          type: _IngredientFactorType.avoid,
          title: 'Search or add avoid ingredient',
          subtitle: 'Add ingredients AI should avoid for this request.',
        ),
      ),
    );
  }
}

/// Add factor action button.
class _AddFactorAction extends StatelessWidget {
  /// Button label.
  final String label;

  /// Icon to display.
  final IconData icon;

  /// Callback when tapped.
  final VoidCallback onTap;

  /// Creates a new add factor action instance.
  const _AddFactorAction({
    required this.label,
    required this.onTap,
    this.icon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
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

  /// Optional title override.
  final String? title;

  /// Optional subtitle override.
  final String? subtitle;

  /// Creates a new ingredient picker sheet instance.
  const _IngredientPickerSheet({required this.type, this.title, this.subtitle});

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
              widget.title ??
                  (isAvoid ? 'Ingredients to avoid' : 'Ingredients to include'),
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle.
            Text(
              widget.subtitle ??
                  (isAvoid
                      ? 'Add ingredients AI should avoid for this request.'
                      : 'Search foods or add a custom ingredient AI should include.'),
              style: context.text.bodyMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: AppSpacing.md),

            // Search input.
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search foods or add custom ingredient',
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

                  const SizedBox(height: AppSpacing.md),

                  // Search results section.
                  _IngredientSheetSection(
                    title: 'Search results',
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

    return _ExpandableFactorCard(
      icon: Icons.favorite,
      title: 'Meal Preferences',
      subtitle: 'Diet or profile choices such as vegetarian, halal or keto.',
      selectedLabels: viewModel.selectedMealPreferences.isEmpty
          ? const ['No Preference']
          : viewModel.selectedMealPreferences,
      childrenBuilder: (context) {
        final sheetViewModel = context.watch<GenerateAiMealViewModel>();
        final sheetOptions = {
          ...sheetViewModel.mealPreferenceOptions.map((item) => item.name),
          ...sheetViewModel.selectedMealPreferences,
        }.toList();

        return [
          // Show loading or options.
          if (sheetViewModel.isFactorOptionsLoading)
            const LoadingDialog(inline: true, message: 'Loading preferences...')
          else if (sheetOptions.isEmpty)
            Text(
              'No meal preferences available.',
              style: context.text.bodySmall,
            )
          else
            _ChipWrap(
              values: sheetOptions,
              selectedValues: sheetViewModel.selectedMealPreferences,
              onSelected: context
                  .read<GenerateAiMealViewModel>()
                  .toggleMealPreference,
            ),
        ];
      },
    );
  }
}

/// Cuisine / recipe style factor card.
class _CuisineStyleFactorCard extends StatelessWidget {
  /// Creates a new cuisine style factor card instance.
  const _CuisineStyleFactorCard();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();

    return _ExpandableFactorCard(
      icon: Icons.public,
      title: 'Cuisine / Recipe Style',
      subtitle: 'Choose the cooking culture or recipe category to guide AI.',
      selectedLabels: viewModel.selectedCuisineStyles.isEmpty
          ? const ['Any style']
          : viewModel.selectedCuisineStyles,
      childrenBuilder: (context) {
        final sheetViewModel = context.watch<GenerateAiMealViewModel>();
        final sheetOptions = {
          ...sheetViewModel.cuisineStyleOptions.map((item) => item.name),
          ...sheetViewModel.selectedCuisineStyles,
        }.toList();

        return [
          if (sheetViewModel.isFactorOptionsLoading)
            const LoadingDialog(
              inline: true,
              message: 'Loading recipe styles...',
            )
          else if (sheetOptions.isEmpty)
            Text('No recipe styles available.', style: context.text.bodySmall)
          else
            _ChipWrap(
              values: sheetOptions,
              selectedValues: sheetViewModel.selectedCuisineStyles,
              onSelected: context
                  .read<GenerateAiMealViewModel>()
                  .toggleCuisineStyle,
            ),
        ];
      },
    );
  }
}

/// Dish style factor card.
class _DishPreferenceFactorCard extends StatelessWidget {
  /// The meal plan data.
  final AddMealAiPlan plan;

  /// Creates a new dish style factor card instance.
  const _DishPreferenceFactorCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    return _ExpandableFactorCard(
      icon: Icons.no_meals_outlined,
      title: 'Dish Style',
      subtitle: 'Tell AI specific dish formats to include or avoid.',
      selectedLabels: [
        ...viewModel.selectedDishIncludes,
        ...viewModel.selectedDishAvoids,
      ],
      childrenBuilder: (context) {
        final sheetViewModel = context.watch<GenerateAiMealViewModel>();

        return [
          _SectionLabel('Tap examples to include'),
          const SizedBox(height: AppSpacing.xs),
          if (plan.dishPreferences.isEmpty)
            Text(
              'No dish style examples available.',
              style: context.text.bodySmall,
            )
          else
            _ChipWrap(
              values: plan.dishPreferences,
              selectedValues: sheetViewModel.selectedDishIncludes,
              onSelected: context
                  .read<GenerateAiMealViewModel>()
                  .toggleDishIncludeHint,
            ),
          const SizedBox(height: AppSpacing.sm),
          _WordLimitedTextInput(
            initialText: sheetViewModel.dishIncludeText,
            hintText: 'e.g. rice bowl, soup, grilled dish, noodles',
            onChanged: context
                .read<GenerateAiMealViewModel>()
                .updateDishIncludeText,
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionLabel('Tap examples to avoid'),
          const SizedBox(height: AppSpacing.xs),
          _ChipWrap(
            values: ['Soup', 'Fried', 'Spicy', 'Oily', 'Creamy'],
            selectedValues: sheetViewModel.selectedDishAvoids,
            danger: true,
            onSelected: context
                .read<GenerateAiMealViewModel>()
                .toggleDishAvoidHint,
          ),
          const SizedBox(height: AppSpacing.sm),
          _WordLimitedTextInput(
            initialText: sheetViewModel.dishAvoidText,
            hintText: 'e.g. fried food, creamy pasta, soup',
            onChanged: context
                .read<GenerateAiMealViewModel>()
                .updateDishAvoidText,
          ),
        ];
      },
    );
  }
}

/// Cooking method / equipment factor card.
class _CookingMethodFactorCard extends StatelessWidget {
  /// Creates a new cooking method factor card instance.
  const _CookingMethodFactorCard();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();

    return _ExpandableFactorCard(
      icon: Icons.blender_outlined,
      title: 'Cooking Method / Equipment',
      subtitle: 'Choose practical tools or methods available for this meal.',
      selectedLabels: viewModel.selectedCookingMethods.isEmpty
          ? const ['Any method']
          : viewModel.selectedCookingMethods,
      childrenBuilder: (context) {
        final sheetViewModel = context.watch<GenerateAiMealViewModel>();

        return [
          _ChipWrap(
            values: sheetViewModel.cookingMethodOptions,
            selectedValues: sheetViewModel.selectedCookingMethods,
            onSelected: context
                .read<GenerateAiMealViewModel>()
                .toggleCookingMethod,
          ),
        ];
      },
    );
  }
}

/// Spice level factor card.
class _SpiceLevelFactorCard extends StatelessWidget {
  /// Creates a new spice level factor card instance.
  const _SpiceLevelFactorCard();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();

    return _ExpandableFactorCard(
      icon: Icons.local_fire_department_outlined,
      title: 'Spice Level',
      subtitle: 'Choose how spicy the generated recipe should be.',
      selectedLabels: [viewModel.selectedSpiceLevel],
      childrenBuilder: (context) {
        final sheetViewModel = context.watch<GenerateAiMealViewModel>();

        return [
          _ChipWrap(
            values: sheetViewModel.spiceLevelOptions,
            selectedValues: [sheetViewModel.selectedSpiceLevel],
            onSelected: context
                .read<GenerateAiMealViewModel>()
                .selectSpiceLevel,
          ),
        ];
      },
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
      childrenBuilder: (context) {
        final sheetViewModel = context.watch<GenerateAiMealViewModel>();

        return [
          _CookingMinutesInput(
            minutes: sheetViewModel.selectedCookingTime,
            onChanged: context
                .read<GenerateAiMealViewModel>()
                .updateCookingTime,
          ),
          const SizedBox(height: AppSpacing.md),
          _DifficultyLevelPicker(
            selectedLevel: sheetViewModel.selectedDifficultyLevel,
            onSelected: context
                .read<GenerateAiMealViewModel>()
                .selectDifficulty,
          ),
          const SizedBox(height: AppSpacing.md),
          _ServingSizeInput(
            servings: sheetViewModel.selectedServingCount,
            onChanged: context
                .read<GenerateAiMealViewModel>()
                .selectServingSize,
          ),
        ];
      },
    );
  }
}

/// Extra preferences factor card.
class _ExtraPreferencesFactorCard extends StatelessWidget {
  /// Creates a new extra preferences factor card instance.
  const _ExtraPreferencesFactorCard();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();

    return _ExpandableFactorCard(
      icon: Icons.edit_note_outlined,
      title: 'Extra Preferences',
      subtitle:
          'Optional. Add any special request not covered above. AI will use it only for this generation.',
      selectedLabels: viewModel.extraPreferencesText.trim().isEmpty
          ? const []
          : const ['Extra request added'],
      childrenBuilder: (context) {
        final sheetViewModel = context.watch<GenerateAiMealViewModel>();

        return [
          _WordLimitedTextInput(
            initialText: sheetViewModel.extraPreferencesText,
            hintText:
                'e.g. kid friendly, cheap ingredients, soft food, less oily, no rice today',
            onChanged: context
                .read<GenerateAiMealViewModel>()
                .updateExtraPreferences,
          ),
        ];
      },
    );
  }
}

/// Step 2: AI results step.

part of '../../view/planning/generate_ai_meal_page.dart';

/// Instruction and review step widgets for generated recipes.
///
/// Draft editing, recipe saving, and meal-plan saving remain grouped by final flow.
class _InstructionsStep extends StatefulWidget {
  /// Creates a new instructions step instance.
  const _InstructionsStep();

  @override
  State<_InstructionsStep> createState() => _InstructionsStepState();
}

/// State for the instructions step.
class _InstructionsStepState extends State<_InstructionsStep> {
  /// Current page in the instructions flow.
  int _page = 1;

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Get the first selected recipe.
    final recipe = viewModel.selectedRecipes.firstOrNull;

    // Get the recipe draft basic info.
    final basicInfo = viewModel.recipeDraftBasicInfo;

    // Show empty state if no recipe selected.
    if (recipe == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Spacer(),
            Image.asset('assets/images/empty_page.png', height: 150),
            const SizedBox(height: AppSpacing.md),
            Text('Select one AI recipe first', style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Go back to AI Result and choose the recipe you want to prepare.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
            const Spacer(),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with page indicator and back button.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Recipe Instructions ($_page/4)',
                  style: context.text.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: _page <= 1 ? null : () => setState(() => _page -= 1),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Back'),
              ),
            ],
          ),
        ),

        // Dynamic page content.
        Expanded(child: _buildRecipeDraftPage(context, recipe, basicInfo)),
      ],
    );
  }

  /// Builds the appropriate recipe draft page based on the current page.
  Widget _buildRecipeDraftPage(
    BuildContext context,
    AddMealAiRecipe recipe,
    AddRecipeBasicInfo? basicInfo,
  ) {
    // Get the view model.
    final viewModel = context.read<GenerateAiMealViewModel>();

    // Render the appropriate page.
    switch (_page) {
      case 2:
        return AddRecipeIngredientsPage(
          key: ValueKey('ai-ingredients-${recipe.id}'),
          recipeId: '',
          initialVisibility: basicInfo?.visibility ?? 'private',
          initialAiRecipe: recipe,
          initialAiRequest: viewModel.generationRequest,
          userId: viewModel.userId,
          aiDraftBasicInfo: basicInfo,
          hideProgressBar: true,
          hideAppBar: true,
          onAiDraftNext: (ingredients) {
            viewModel.saveRecipeDraftIngredients(ingredients);
            setState(() => _page = 3);
          },
        );
      case 3:
        return AddRecipeInstructionsPage(
          key: ValueKey('ai-instructions-${recipe.id}'),
          recipeId: '',
          initialVisibility: basicInfo?.visibility ?? 'private',
          initialAiRecipe: recipe,
          initialAiRequest: viewModel.generationRequest,
          userId: viewModel.userId,
          aiDraftBasicInfo: basicInfo,
          aiDraftIngredients: viewModel.recipeDraftIngredients,
          hideProgressBar: true,
          hideAppBar: true,
          onAiDraftNext: (draft) {
            viewModel.saveRecipeDraftInstructions(
              instructions: draft.instructions,
              useSections: draft.useSections,
            );
            setState(() => _page = 4);
          },
        );
      case 4:
        if (basicInfo == null) {
          // Reset to page 1 if basic info is missing.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _page = 1);
          });
          return const SizedBox.shrink();
        }
        return AddRecipeReviewPage(
          key: ValueKey('ai-review-${recipe.id}'),
          recipeId: '',
          initialAiRecipe: recipe,
          initialAiRequest: viewModel.generationRequest,
          userId: viewModel.userId,
          aiDraftBasicInfo: basicInfo,
          aiDraftIngredients: viewModel.recipeDraftIngredients,
          aiDraftInstructions: viewModel.recipeDraftInstructions,
          aiDraftUseSections: viewModel.recipeDraftUseSections,
          hideProgressBar: true,
          hideAppBar: true,
          onAiDraftReviewed: viewModel.goToNextStep,
        );
      default:
        return AddRecipeBasicInfoPage(
          key: ValueKey('ai-basic-${recipe.id}'),
          recipeId: '',
          initialAiRecipe: recipe,
          initialAiRequest: viewModel.generationRequest,
          userId: viewModel.userId,
          hideProgressBar: true,
          hideAppBar: true,
          onAiDraftNext: (info) {
            viewModel.saveRecipeDraftBasicInfo(info);
            setState(() => _page = 2);
          },
        );
    }
  }
}

/// Extension to get first element or null.
extension _FirstOrNull<T> on List<T> {
  /// Returns the first element or null if the list is empty.
  T? get firstOrNull => isEmpty ? null : first;
}

/// Step 4: Review step.
class _ReviewStep extends StatefulWidget {
  /// The meal plan data.
  final AddMealAiPlan plan;

  /// Creates a new review step instance.
  const _ReviewStep({required this.plan});

  @override
  State<_ReviewStep> createState() => _ReviewStepState();
}

/// State for the review step.
class _ReviewStepState extends State<_ReviewStep> {
  /// Whether saving recipe is in progress.
  bool _isSavingRecipe = false;

  /// Whether saving both is in progress.
  bool _isSavingBoth = false;

  @override
  Widget build(BuildContext context) {
    // Get the plan.
    final plan = widget.plan;

    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Get selected recipes.
    final selectedRecipes = viewModel.selectedRecipes;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        // Date picker.
        _DateScroller(
          selectedDate: viewModel.selectedDate,
          onSelected: viewModel.selectDate,
        ),
        const SizedBox(height: AppSpacing.md),

        // Weather factor.
        _FactorCard(
          icon: Icons.wb_sunny_outlined,
          title: '${plan.weather.condition} - ${plan.weather.temperature}C',
          subtitle: plan.weather.summary,
          highlighted: true,
        ),
        const SizedBox(height: AppSpacing.md),

        // Planned meals section.
        Text(
          'Meals planned on ${DateFormat('EEE, d MMM').format(viewModel.selectedDate)}',
          style: context.text.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _PlannedMealRows(
          mealType: viewModel.selectedMealCategory?.name ?? plan.mealType,
        ),
        const SizedBox(height: AppSpacing.md),

        // Meal type selection.
        Text('Choose Meal', style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _MealTypeChips(
          selected: viewModel.selectedMealCategory?.name ?? plan.mealType,
          categories: viewModel.mealCategories,
          onSelected: viewModel.selectMealCategory,
        ),
        const SizedBox(height: AppSpacing.md),

        // Recipe details.
        Text('Recipe Details', style: context.text.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (selectedRecipes.isEmpty)
          const _EmptySelectedRecipe()
        else
          ...selectedRecipes.map((recipe) => _ReviewRecipeCard(recipe: recipe)),
        const SizedBox(height: AppSpacing.lg),

        // Action buttons.
        _PrimaryActionButton(
          label: viewModel.isSaving ? 'Adding...' : 'Add to Meal Plan',
          onPressed: viewModel.isSaving
              ? null
              : () => _saveMealPlan(context, viewModel),
        ),
        const SizedBox(height: AppSpacing.sm),

        _PrimaryActionButton(
          label: _isSavingRecipe ? 'Saving...' : 'Save Recipe',
          onPressed: _isSavingRecipe || !viewModel.hasRecipeDraft
              ? null
              : () => _saveRecipe(context, viewModel),
        ),
        const SizedBox(height: AppSpacing.sm),

        OutlinedButton(
          onPressed:
              viewModel.isSaving || _isSavingBoth || !viewModel.hasRecipeDraft
              ? null
              : () => _saveBoth(context, viewModel),
          child: Text(
            _isSavingBoth ? 'Saving...' : 'Add to Meal Plan & Recipe',
          ),
        ),
      ],
    );
  }

  /// Saves the meal plan.
  Future<void> _saveMealPlan(
    BuildContext context,
    GenerateAiMealViewModel viewModel,
  ) async {
    final canContinue = await _confirmOverTargetIfNeeded(context, viewModel);
    if (!context.mounted || !canContinue) return;

    final success = await viewModel.saveSelectedRecipesToPlan();

    // Check if context is still mounted.
    if (!context.mounted) return;

    // Show error if failed.
    if (!success) {
      _showSnack(context, viewModel.errorMessage ?? 'Unable to add meal plan.');
      return;
    }

    // Navigate to meal plan page.
    _goToMealPlan(context, viewModel);
  }

  /// Saves the recipe.
  Future<void> _saveRecipe(
    BuildContext context,
    GenerateAiMealViewModel viewModel,
  ) async {
    // Set saving state.
    setState(() => _isSavingRecipe = true);

    // Save the recipe draft.
    final success = await _saveRecipeDraft(viewModel);

    // Check if context is still mounted.
    if (!context.mounted) return;

    // Reset saving state.
    setState(() => _isSavingRecipe = false);

    // Show success message.
    if (!success) return;
    _showSnack(context, 'Recipe saved.');
  }

  /// Saves both meal plan and recipe.
  Future<void> _saveBoth(
    BuildContext context,
    GenerateAiMealViewModel viewModel,
  ) async {
    final canContinue = await _confirmOverTargetIfNeeded(context, viewModel);
    if (!context.mounted || !canContinue) return;

    // Set saving state.
    setState(() => _isSavingBoth = true);

    // Save the recipe draft.
    final recipeSaved = await _saveRecipeDraft(viewModel);

    // Check if context is still mounted.
    if (!context.mounted) return;

    // Show error if recipe save failed.
    if (!recipeSaved) {
      setState(() => _isSavingBoth = false);
      return;
    }

    // Save the meal plan.
    final mealSaved = await viewModel.saveSelectedRecipesToPlan();

    // Check if context is still mounted.
    if (!context.mounted) return;

    // Reset saving state.
    setState(() => _isSavingBoth = false);

    // Show error if meal plan save failed.
    if (!mealSaved) {
      _showSnack(context, viewModel.errorMessage ?? 'Unable to add meal plan.');
      return;
    }

    // Navigate to meal plan page.
    _goToMealPlan(context, viewModel);
  }

  /// Confirms over-target AI meal selection before saving.
  Future<bool> _confirmOverTargetIfNeeded(
    BuildContext context,
    GenerateAiMealViewModel viewModel,
  ) async {
    // Non-exceeding selections continue without extra confirmation.
    final guidance = viewModel.selectedRecipeCalorieGuidance;
    if (guidance?.status != MealCalorieGuidanceStatus.exceeds) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Calorie target exceeded'),
        content: Text(
          'This meal exceeds your daily target by '
          '${guidance!.exceededByCalories ?? 0} ${guidance.calorieUnit}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Choose another'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add anyway'),
          ),
        ],
      ),
    );

    return result == true;
  }

  /// Saves the recipe draft using use cases.
  Future<bool> _saveRecipeDraft(GenerateAiMealViewModel viewModel) async {
    // Get the basic info.
    final basicInfo = viewModel.recipeDraftBasicInfo;
    if (basicInfo == null) return false;

    // Save basic info.
    final basicResult = await sl<SaveAddRecipeBasicInfoUseCase>().execute(
      basicInfo,
    );
    if (basicResult.isLeft()) {
      if (mounted) _showSnack(context, basicResult.left?.message);
      return false;
    }

    // Get the saved recipe ID.
    final savedRecipeId = basicResult.right!;

    // Save ingredients.
    final ingredientResult = await sl<SaveAddRecipeIngredientsUseCase>()
        .execute(
          recipeId: savedRecipeId,
          ingredients: viewModel.recipeDraftIngredients,
        );
    if (ingredientResult.isLeft()) {
      if (mounted) _showSnack(context, ingredientResult.left?.message);
      return false;
    }

    // Save instructions.
    final instructionResult = await sl<SaveAddRecipeInstructionsUseCase>()
        .execute(
          recipeId: savedRecipeId,
          useSections: viewModel.recipeDraftUseSections,
          instructions: viewModel.recipeDraftInstructions,
        );
    if (instructionResult.isLeft()) {
      if (mounted) _showSnack(context, instructionResult.left?.message);
      return false;
    }

    // Complete the recipe.
    final completeResult = await sl<CompleteAddRecipeUseCase>().execute(
      recipeId: savedRecipeId,
      mode: 'ai_generated',
    );
    if (completeResult.isLeft()) {
      if (mounted) _showSnack(context, completeResult.left?.message);
      return false;
    }

    return true;
  }

  /// Navigates to the meal plan page.
  void _goToMealPlan(BuildContext context, GenerateAiMealViewModel viewModel) {
    // Show success message.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Meal plan added.')));

    // Navigate to meal plan page.
    context.go(
      AppRouter.mealPlan,
      extra: MealPlanArgs(initialTabIndex: 0, userId: viewModel.userId),
    );
  }

  /// Shows a snackbar with a message.
  void _showSnack(BuildContext context, String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Unable to save recipe.')),
    );
  }
}

/// Mini info tile widget.

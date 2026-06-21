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

        // Save options.
        _SaveOptionsSection(
          isBusy: _isBusy(viewModel),
          hasRecipeDraft: viewModel.hasRecipeDraft,
          primaryLabel: _isSavingBoth
              ? 'Saving both...'
              : 'Add to Meal Plan + Save Recipe',
          onSaveBoth: viewModel.hasRecipeDraft && !_isBusy(viewModel)
              ? () => _saveBoth(context, viewModel)
              : null,
          mealPlanLabel: viewModel.isSaving
              ? 'Adding to meal plan...'
              : 'Add to Meal Plan Only',
          onSaveMealPlan: _isBusy(viewModel)
              ? null
              : () => _saveMealPlan(context, viewModel),
          recipeLabel: _isSavingRecipe
              ? 'Saving recipe...'
              : 'Save Recipe Only',
          onSaveRecipe: viewModel.hasRecipeDraft && !_isBusy(viewModel)
              ? () => _saveRecipe(context, viewModel)
              : null,
        ),
      ],
    );
  }

  bool _isBusy(GenerateAiMealViewModel viewModel) {
    return viewModel.isSaving || _isSavingRecipe || _isSavingBoth;
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
    final savedRecipeId = await _saveRecipeDraft(viewModel);

    // Check if context is still mounted.
    if (!context.mounted) return;

    // Reset saving state.
    setState(() => _isSavingRecipe = false);

    // Open the saved private recipe in the user's library.
    if (savedRecipeId == null) return;
    _goToLibraryRecipe(context, savedRecipeId);
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
    final savedRecipeId = await _saveRecipeDraft(viewModel);

    // Check if context is still mounted.
    if (!context.mounted) return;

    // Show error if recipe save failed.
    if (savedRecipeId == null) {
      setState(() => _isSavingBoth = false);
      return;
    }
    viewModel.linkSelectedRecipeToSavedRecipe(savedRecipeId);

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
  Future<String?> _saveRecipeDraft(GenerateAiMealViewModel viewModel) async {
    // Get the basic info.
    final basicInfo = await _recipeBasicInfoForSave(viewModel);
    if (basicInfo == null) return null;

    // Save basic info.
    final basicResult = await sl<SaveAddRecipeBasicInfoUseCase>().execute(
      basicInfo,
    );
    if (basicResult.isLeft()) {
      if (mounted) _showSnack(context, basicResult.left?.message);
      return null;
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
      return null;
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
      return null;
    }

    // Complete the recipe.
    final completeResult = await sl<CompleteAddRecipeUseCase>().execute(
      recipeId: savedRecipeId,
      mode: 'ai_generated',
    );
    if (completeResult.isLeft()) {
      if (mounted) _showSnack(context, completeResult.left?.message);
      return null;
    }

    return savedRecipeId;
  }

  /// Ensures AI recipe media is present before saving to the library.
  Future<AddRecipeBasicInfo?> _recipeBasicInfoForSave(
    GenerateAiMealViewModel viewModel,
  ) async {
    final basicInfo = viewModel.recipeDraftBasicInfo;
    if (basicInfo == null) return null;
    if (basicInfo.mediaFiles.isNotEmpty ||
        basicInfo.existingMediaUrls.isNotEmpty) {
      return basicInfo;
    }

    final recipe = viewModel.selectedRecipes.firstOrNull;
    if (recipe == null) return basicInfo;

    final aiImageFile = await _aiImageFileForSave(recipe);
    if (aiImageFile != null) {
      return AddRecipeBasicInfo(
        recipeId: basicInfo.recipeId,
        mediaFiles: [aiImageFile],
        existingMediaUrls: basicInfo.existingMediaUrls,
        recipeName: basicInfo.recipeName,
        description: basicInfo.description,
        otherNames: basicInfo.otherNames,
        categoryIds: basicInfo.categoryIds,
        customCategories: basicInfo.customCategories,
        preparationMinutes: basicInfo.preparationMinutes,
        difficultyLevel: basicInfo.difficultyLevel,
        servings: basicInfo.servings,
        allergenIds: basicInfo.allergenIds,
        customAllergens: basicInfo.customAllergens,
        visibility: basicInfo.visibility,
        isAiGenerated: basicInfo.isAiGenerated,
      );
    }

    final existingAiImage = _aiExistingImageUrlForSave(recipe);
    if (existingAiImage == null) return basicInfo;

    return AddRecipeBasicInfo(
      recipeId: basicInfo.recipeId,
      mediaFiles: basicInfo.mediaFiles,
      existingMediaUrls: [existingAiImage],
      recipeName: basicInfo.recipeName,
      description: basicInfo.description,
      otherNames: basicInfo.otherNames,
      categoryIds: basicInfo.categoryIds,
      customCategories: basicInfo.customCategories,
      preparationMinutes: basicInfo.preparationMinutes,
      difficultyLevel: basicInfo.difficultyLevel,
      servings: basicInfo.servings,
      allergenIds: basicInfo.allergenIds,
      customAllergens: basicInfo.customAllergens,
      visibility: basicInfo.visibility,
      isAiGenerated: basicInfo.isAiGenerated,
    );
  }

  Future<File?> _aiImageFileForSave(AddMealAiRecipe recipe) async {
    final encoded = recipe.imageBase64;
    if (encoded == null || encoded.trim().isEmpty) return null;

    try {
      final bytes = base64Decode(_base64Payload(encoded));
      final safeId = recipe.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'foodopia_${safeId}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  String? _aiExistingImageUrlForSave(AddMealAiRecipe recipe) {
    if (recipe.imageBase64?.trim().isNotEmpty == true) return null;

    final imagePath = recipe.imagePath.trim();
    if (imagePath.isEmpty || imagePath.startsWith('assets/')) return null;
    if (!imagePath.startsWith('http://') && !imagePath.startsWith('https://')) {
      return null;
    }

    return imagePath;
  }

  String _base64Payload(String value) {
    final commaIndex = value.indexOf(',');
    return commaIndex >= 0 ? value.substring(commaIndex + 1) : value;
  }

  /// Navigates to the meal plan page.
  void _goToMealPlan(BuildContext context, GenerateAiMealViewModel viewModel) {
    // Show success message.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Meal plan added.')));

    // Return success to the existing planning page for a lightweight refresh.
    context.pop(true);
  }

  /// Opens the saved recipe in the private library tab.
  void _goToLibraryRecipe(BuildContext context, String recipeId) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recipe saved.')));

    context.go(
      AppRouter.library,
      extra: LibraryArgs(
        focusedRecipeId: recipeId,
        focusedRecipeIsPublished: false,
      ),
    );
  }

  /// Shows a snackbar with a message.
  void _showSnack(BuildContext context, String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Unable to save recipe.')),
    );
  }
}

/// Clear save destination choices for the final AI recipe step.
class _SaveOptionsSection extends StatelessWidget {
  /// Whether any save action is in progress.
  final bool isBusy;

  /// Whether a reviewed recipe draft is ready to be saved.
  final bool hasRecipeDraft;

  /// Primary action label.
  final String primaryLabel;

  /// Save both callback.
  final VoidCallback? onSaveBoth;

  /// Meal-plan-only label.
  final String mealPlanLabel;

  /// Meal-plan-only callback.
  final VoidCallback? onSaveMealPlan;

  /// Recipe-only label.
  final String recipeLabel;

  /// Recipe-only callback.
  final VoidCallback? onSaveRecipe;

  /// Creates a new save options section.
  const _SaveOptionsSection({
    required this.isBusy,
    required this.hasRecipeDraft,
    required this.primaryLabel,
    required this.onSaveBoth,
    required this.mealPlanLabel,
    required this.onSaveMealPlan,
    required this.recipeLabel,
    required this.onSaveRecipe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.task_alt,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose where to save',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      hasRecipeDraft
                          ? 'Save the reviewed AI recipe to one or both places.'
                          : 'Review the recipe details first to save it to your recipe library.',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _RecommendedSaveButton(
            label: primaryLabel,
            enabled: onSaveBoth != null,
            isBusy: isBusy,
            onPressed: onSaveBoth,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SaveOptionCard(
                  icon: Icons.event_available_outlined,
                  title: mealPlanLabel,
                  subtitle: 'Plan this meal for the selected date.',
                  onPressed: onSaveMealPlan,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SaveOptionCard(
                  icon: Icons.menu_book_outlined,
                  title: recipeLabel,
                  subtitle: 'Keep this recipe in your library.',
                  onPressed: onSaveRecipe,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Recommended combined save action.
class _RecommendedSaveButton extends StatelessWidget {
  /// Button label.
  final String label;

  /// Whether the button can be used.
  final bool enabled;

  /// Whether saving is active.
  final bool isBusy;

  /// Callback when pressed.
  final VoidCallback? onPressed;

  /// Creates a recommended save button.
  const _RecommendedSaveButton({
    required this.label,
    required this.enabled,
    required this.isBusy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.done_all_outlined),
        label: Text(label, textAlign: TextAlign.center),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: context.text.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Secondary save option card.
class _SaveOptionCard extends StatelessWidget {
  /// Option icon.
  final IconData icon;

  /// Option title.
  final String title;

  /// Option explanation.
  final String subtitle;

  /// Callback when selected.
  final VoidCallback? onPressed;

  /// Creates a new save option card.
  const _SaveOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled ? const Color(0xFFF8F9FA) : const Color(0xFFF2F3F2),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled
                  ? AppColors.primary.withValues(alpha: 0.24)
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: enabled ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini info tile widget.

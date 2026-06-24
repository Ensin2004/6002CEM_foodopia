import 'package:flutter/material.dart';
import 'package:foodopia/features/recipe/presentation/widgets/label.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/extensions/either_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/progress_bar/app_step_progress_bar.dart';
import '../../../meal_plan/domain/entities/add_meal_ai_plan.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/entities/add_recipe_instruction.dart';
import '../../../meal_plan/domain/entities/meal_serving_amount.dart';
import '../../domain/entities/add_recipe_review.dart';
import '../../domain/usecases/complete_add_recipe_usecase.dart';
import '../../domain/usecases/finalize_add_recipe_usecase.dart';
import '../../domain/usecases/get_add_recipe_review_usecase.dart';
import '../../domain/usecases/save_add_recipe_basic_info_usecase.dart';
import '../../domain/usecases/save_add_recipe_ingredients_usecase.dart';
import '../../domain/usecases/save_add_recipe_instructions_usecase.dart';
import '../viewmodel/add_recipe_review_viewmodel.dart';
import '../viewmodel/add_recipe_visibility_viewmodel.dart';
import '../widgets/recipe_error_dialog.dart';
import '../widgets/recipe_visibility_action_button.dart';
import '../widgets/review/review_hero_image.dart';
import '../widgets/review/review_info_row.dart';
import '../widgets/review/review_ingredient_item.dart';
import '../widgets/review/review_instruction_item.dart';
import '../widgets/review/review_section_row.dart';

/// Add recipe review page
/// For user to check and review all the info of the recipe
class AddRecipeReviewPage extends StatelessWidget {
  final String recipeId;
  final AddMealAiRecipe? initialAiRecipe;
  final AddMealAiGenerationRequest? initialAiRequest;
  final String? userId;
  final AddRecipeBasicInfo? aiDraftBasicInfo;
  final List<AddRecipeIngredient> aiDraftIngredients;
  final List<AddRecipeInstruction> aiDraftInstructions;
  final bool aiDraftUseSections;
  final bool hideProgressBar;
  final bool hideAppBar;
  final VoidCallback? onAiDraftReviewed;

  const AddRecipeReviewPage({
    super.key,
    required this.recipeId,
    this.initialAiRecipe,
    this.initialAiRequest,
    this.userId,
    this.aiDraftBasicInfo,
    this.aiDraftIngredients = const [],
    this.aiDraftInstructions = const [],
    this.aiDraftUseSections = false,
    this.hideProgressBar = false,
    this.hideAppBar = false,
    this.onAiDraftReviewed,
  });

  @override
  Widget build(BuildContext context) {
    // Build AI review data if this is an AI draft flow
    final aiReview = _buildAiReview();
    // Set up view models with dependency injection
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final viewModel = AddRecipeReviewViewModel(
              getReviewUseCase: sl<GetAddRecipeReviewUseCase>(),
              finalizeRecipeUseCase: sl<FinalizeAddRecipeUseCase>(),
              deleteRecipeUseCase: sl(),
            );

            // Load existing review for manual flow, skip loading for AI draft
            if (aiReview == null) {
              viewModel.loadReview(recipeId);
            } else {
              viewModel.isLoading = false;
            }
            return viewModel;
          },
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AddRecipeVisibilityViewModel(updateVisibilityUseCase: sl()),
        ),
      ],
      child: _AddRecipeReviewView(
        recipeId: recipeId,
        aiReview: aiReview,
        aiDraftBasicInfo: aiDraftBasicInfo,
        aiDraftIngredients: aiDraftIngredients,
        aiDraftInstructions: aiDraftInstructions,
        aiDraftUseSections: aiDraftUseSections,
        hideProgressBar: hideProgressBar,
        hideAppBar: hideAppBar,
        onAiDraftReviewed: onAiDraftReviewed,
      ),
    );
  }

  /// Builds a review object containing all info from AI-generated data.
  AddRecipeReview? _buildAiReview() {
    final basicInfo = aiDraftBasicInfo;
    final aiRecipe = initialAiRecipe;
    if (aiRecipe == null || basicInfo == null) return null;
    final media = [
      ...basicInfo.existingMediaUrls,
      if (basicInfo.existingMediaUrls.isEmpty &&
          aiRecipe.imageBase64?.isNotEmpty == true)
        'data:image/png;base64,${aiRecipe.imageBase64!}'
      else if (basicInfo.existingMediaUrls.isEmpty)
        aiRecipe.imagePath,
    ].where((item) => item.trim().isNotEmpty).toList();

    return AddRecipeReview(
      recipeId: '',
      media: media,
      recipeName: basicInfo.recipeName,
      description: basicInfo.description,
      otherNames: basicInfo.otherNames,
      categories: [...basicInfo.categoryIds, ...basicInfo.customCategories],
      preparationMinutes: basicInfo.preparationMinutes,
      difficultyLevel: basicInfo.difficultyLevel,
      servings: basicInfo.servings,
      allergens: [...basicInfo.allergenIds, ...basicInfo.customAllergens],
      visibility: basicInfo.visibility,
      nutrients: AddRecipeReviewNutrients(
        calories: aiRecipe.calories > 0 ? '${aiRecipe.calories} kcal' : '-',
        proteins: _formatMacro(aiRecipe.protein),
        carbohydrates: _formatMacro(aiRecipe.carbohydrates),
        fats: _formatMacro(aiRecipe.fat),
      ),
      ingredients: aiDraftIngredients
          .map(
            (item) => AddRecipeReviewIngredient(
              name: item.name,
              image: item.existingImageUrl ?? '',
              amount: _formatAmount(item.amount),
              unit: item.customUnit.isNotEmpty ? item.customUnit : item.unitId,
              usdaId: item.usdaId,
              nutrients: item.usdaNutrients,
              ingredientCategoryId: item.ingredientCategoryId,
            ),
          )
          .toList(),
      instructions: aiDraftInstructions
          .map(
            (item) => AddRecipeReviewInstruction(
              sectionIndex: item.sectionIndex,
              sectionTitle: item.sectionTitle,
              stepIndex: item.stepIndex,
              image: item.existingStepImageUrl ?? '',
              description: item.description,
            ),
          )
          .toList(),
      instructionUseSection: aiDraftUseSections,
    );
  }

  /// Formats a decimal amount for display
  String _formatAmount(double amount) {
    return amount % 1 == 0 ? amount.toInt().toString() : amount.toString();
  }

  /// Formats macronutrient values with 'g' suffix
  String _formatMacro(double value) {
    if (value <= 0) return '-';
    final formatted = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '${formatted}g';
  }
}

/// Stateful widget of the add recipe review page.
class _AddRecipeReviewView extends StatefulWidget {
  final String recipeId;
  final AddRecipeReview? aiReview;
  final AddRecipeBasicInfo? aiDraftBasicInfo;
  final List<AddRecipeIngredient> aiDraftIngredients;
  final List<AddRecipeInstruction> aiDraftInstructions;
  final bool aiDraftUseSections;
  final bool hideProgressBar;
  final bool hideAppBar;
  final VoidCallback? onAiDraftReviewed;

  const _AddRecipeReviewView({
    required this.recipeId,
    this.aiReview,
    this.aiDraftBasicInfo,
    this.aiDraftIngredients = const [],
    this.aiDraftInstructions = const [],
    this.aiDraftUseSections = false,
    this.hideProgressBar = false,
    this.hideAppBar = false,
    this.onAiDraftReviewed,
  });

  @override
  State<_AddRecipeReviewView> createState() => _AddRecipeReviewViewState();
}

class _AddRecipeReviewViewState extends State<_AddRecipeReviewView> {
  bool _isSavingAiDraft = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddRecipeReviewViewModel>();
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 600
        ? 48.0
        : AppSpacing.lg;

    if (widget.aiReview == null && viewModel.isLoading) {
      return const _AddRecipePageLoading();
    }

    final review = widget.aiReview ?? viewModel.review;
    if (review == null) {
      return _RecipeErrorState(message: viewModel.errorMessage);
    }

    // Seed visibility for manual flow
    if (widget.aiReview == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<AddRecipeVisibilityViewModel>().seedVisibility(
          review.visibility,
        );
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: widget.hideAppBar
          ? null
          : CustomAppBar(
              title: widget.aiReview == null
                  ? "New Recipe"
                  : "Customize AI Recipe",
              actions: widget.aiReview == null
                  ? [
                      Consumer<AddRecipeVisibilityViewModel>(
                        builder: (context, visibilityViewModel, _) {
                          return RecipeVisibilityActionButton(
                            visibility: visibilityViewModel.visibility,
                            isSaving: visibilityViewModel.isSaving,
                            onChanged: (value) => confirmRecipeVisibilityChange(
                              context: context,
                              currentVisibility: visibilityViewModel.visibility,
                              nextVisibility: value,
                              onConfirmed: (visibility) =>
                                  visibilityViewModel.updateVisibility(
                                    recipeId: widget.recipeId,
                                    value: visibility,
                                  ),
                              errorMessage: () =>
                                  visibilityViewModel.errorMessage,
                            ),
                          );
                        },
                      ),
                    ]
                  : null,
            ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
            if (!widget.hideProgressBar)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.md,
                ),
                child: AppStepProgressBar(
                  totalSteps: 4,
                  currentStep: 4,
                  labels: [
                    "Basic Info",
                    "Ingredients",
                    "Instructions",
                    "Review",
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.sm,
                horizontalPadding,
                AppSpacing.lg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Label, Tips
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Label(text: "Review"),
                        const SizedBox(height: 2),
                        Text(
                          "Review your recipe before saving",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  // Delete button
                  if (widget.aiReview == null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      tooltip: "Delete recipe",
                      onPressed: viewModel.isDeleting
                          ? null
                          : () => _confirmDeleteRecipe(
                              context,
                              viewModel,
                              review,
                            ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: AppColors.error,
                    ),
                ],
              ),
            ),

            // Information
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  0,
                ),
                children: [
                  // Recipe Image and Video
                  ReviewHeroImage(media: review.media),
                  const SizedBox(height: AppSpacing.lg),

                  // Basic Info
                  ReviewSectionRow(
                    icon: Icons.info_rounded,
                    title: "Basic Info",
                    onEdit: widget.aiReview == null
                        ? () => context.pushReplacement(
                            AppRouter.addRecipeBasicInfo,
                            extra: AddRecipeBasicInfoArgs(
                              recipeId: widget.recipeId,
                              returnToReview: true,
                            ),
                          )
                        : null,
                    children: [
                      ReviewInfoRow(
                        label: "Recipe Name",
                        value: review.recipeName,
                      ),
                      ReviewInfoRow(
                        label: "Description",
                        value: review.description,
                      ),
                      ReviewInfoRow(
                        label: "Other Name",
                        value: _joinOrDash(review.otherNames),
                      ),
                      ReviewInfoRow(
                        label: "Category",
                        value: _joinOrDash(review.categories),
                      ),
                      ReviewInfoRow(
                        label: "Preparation Time",
                        value: "${review.preparationMinutes} minutes",
                      ),
                      ReviewInfoRow(
                        label: "Difficulty Level",
                        difficultyLevel: review.difficultyLevel,
                      ),
                      ReviewInfoRow(
                        label: "Servings",
                        value: MealServingAmount.format(review.servings),
                      ),
                      ReviewInfoRow(
                        label: "Allergen Info",
                        value: _joinOrDash(review.allergens),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Nutrients
                  ReviewSectionRow(
                    icon: Icons.science_rounded,
                    title: "Nutrients (AI Estimated)",
                    children: [
                      const _NutritionSubheader(title: "Macronutrients"),
                      ReviewInfoRow(
                        label: "Calories",
                        value: review.nutrients.calories,
                      ),
                      ReviewInfoRow(
                        label: "Protein",
                        value: review.nutrients.proteins,
                      ),
                      ReviewInfoRow(
                        label: "Carbohydrates",
                        value: review.nutrients.carbohydrates,
                      ),
                      ReviewInfoRow(label: "Fat", value: review.nutrients.fats),
                      ReviewInfoRow(
                        label: "Fiber",
                        value: review.nutrients.fiber,
                      ),
                      ReviewInfoRow(
                        label: "Water",
                        value: review.nutrients.water,
                      ),
                      if (review.nutrients.vitamins.isNotEmpty)
                        const _NutritionSubheader(title: "Vitamins"),
                      ..._nutrientRows(review.nutrients.vitamins),
                      if (review.nutrients.minerals.isNotEmpty)
                        const _NutritionSubheader(title: "Minerals"),
                      ..._nutrientRows(review.nutrients.minerals),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Ingredients
                  ReviewSectionRow(
                    icon: Icons.eco_rounded,
                    title: "Ingredients",
                    onEdit: widget.aiReview == null
                        ? () => context.pushReplacement(
                            AppRouter.addRecipeIngredients,
                            extra: AddRecipeIngredientsArgs(
                              recipeId: widget.recipeId,
                              visibility: context
                                  .read<AddRecipeVisibilityViewModel>()
                                  .visibility,
                              returnToReview: true,
                            ),
                          )
                        : null,
                    children: _sortedIngredients(review.ingredients)
                        .map((item) => ReviewIngredientItem(ingredient: item))
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Instructions
                  ReviewSectionRow(
                    icon: Icons.menu_book_rounded,
                    title: "Instructions",
                    onEdit: widget.aiReview == null
                        ? () => context.pushReplacement(
                            AppRouter.addRecipeInstructions,
                            extra: AddRecipeInstructionsArgs(
                              recipeId: widget.recipeId,
                              visibility: context
                                  .read<AddRecipeVisibilityViewModel>()
                                  .visibility,
                              returnToReview: true,
                            ),
                          )
                        : null,
                    children: _instructionsWidgets(review),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.lg,
                horizontalPadding,
                AppSpacing.lg,
              ),
              child: PrimaryButton(
                text: widget.aiReview == null
                    ? "Save"
                    : widget.onAiDraftReviewed == null
                    ? "Add Recipe"
                    : "Next",
                isLoading: viewModel.isSaving || _isSavingAiDraft,
                onPressed: viewModel.isSaving || _isSavingAiDraft
                    ? null
                    : widget.aiReview == null
                    ? () => _finishSavedRecipe(context, viewModel)
                    : widget.onAiDraftReviewed ?? () => _saveAiDraft(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Sorting Helpers
  // ============================================================

  /// Sorts ingredients alphabetically for easier scanning.
  List<AddRecipeReviewIngredient> _sortedIngredients(
    List<AddRecipeReviewIngredient> ingredients,
  ) {
    return [...ingredients]..sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );
  }

  // ============================================================
  // Action Methods
  // ============================================================

  /// Saves a completed manual recipe and navigates to the library
  Future<void> _finishSavedRecipe(
    BuildContext context,
    AddRecipeReviewViewModel viewModel,
  ) async {
    // Final save marks the recipe as completed before returning to the library.
    final success = await viewModel.finalizeRecipe(widget.recipeId);
    if (!context.mounted) return;
    if (!success) {
      await showRecipeErrorDialog(
        context: context,
        message: viewModel.errorMessage ?? "Unable to save recipe.",
      );
      return;
    }

    // Home route receives focus parameters so the saved recipe can be highlighted.
    final visibility = context.read<AddRecipeVisibilityViewModel>().visibility;
    context.go(
      Uri(
        path: AppRouter.home,
        queryParameters: {
          'tab': '4',
          'focusedRecipeId': widget.recipeId,
          'focusedRecipeIsPublished': '${visibility == "public"}',
          'createdAt': DateTime.now().microsecondsSinceEpoch.toString(),
        },
      ).toString(),
      extra: HomeArgs(
        initialTabIndex: 4,
        focusedRecipeId: widget.recipeId,
        focusedRecipeIsPublished: visibility == "public",
      ),
    );
  }

  /// Confirms and executes recipe deletion
  Future<void> _confirmDeleteRecipe(
    BuildContext context,
    AddRecipeReviewViewModel viewModel,
    AddRecipeReview review,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete recipe?"),
          content: Text(
            'This will permanently delete "${review.recipeName}" from your library.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    // Loading dialog stays visible while the delete use case clears recipe data.
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(message: "Deleting recipe..."),
    );

    final success = await viewModel.deleteRecipe(review.recipeId);

    if (!context.mounted) return;
    rootNavigator.pop();

    if (!success) {
      await showRecipeErrorDialog(
        context: context,
        message: viewModel.errorMessage ?? "Unable to delete recipe.",
        title: "Unable to Delete",
      );
      return;
    }

    // Library route receives a refresh token after successful deletion.
    context.go(
      Uri(
        path: AppRouter.home,
        queryParameters: {
          'tab': '4',
          'deletedAt': DateTime.now().microsecondsSinceEpoch.toString(),
        },
      ).toString(),
      extra: HomeArgs(
        initialTabIndex: 4,
        libraryRefreshToken: DateTime.now().microsecondsSinceEpoch.toString(),
      ),
    );
  }

  /// Saves an AI draft recipe through the three-step save process
  Future<void> _saveAiDraft(BuildContext context) async {
    // AI draft review can only save after basic information exists.
    final basicInfo = widget.aiDraftBasicInfo;
    if (basicInfo == null) return;

    setState(() => _isSavingAiDraft = true);

    // Save basic info
    final basicResult = await sl<SaveAddRecipeBasicInfoUseCase>().execute(
      basicInfo,
    );
    if (!context.mounted) return;
    if (basicResult.isLeft()) {
      await _finishFailedSave(context, basicResult.left?.message);
      return;
    }

    final savedRecipeId = basicResult.right!;

    // Save ingredients
    final ingredientResult = await sl<SaveAddRecipeIngredientsUseCase>()
        .execute(
          recipeId: savedRecipeId,
          ingredients: widget.aiDraftIngredients,
        );
    if (!context.mounted) return;
    if (ingredientResult.isLeft()) {
      await _finishFailedSave(context, ingredientResult.left?.message);
      return;
    }

    // Save instructions
    final instructionResult = await sl<SaveAddRecipeInstructionsUseCase>()
        .execute(
          recipeId: savedRecipeId,
          useSections: widget.aiDraftUseSections,
          instructions: widget.aiDraftInstructions,
        );
    if (!context.mounted) return;
    if (instructionResult.isLeft()) {
      await _finishFailedSave(context, instructionResult.left?.message);
      return;
    }

    // Mark the recipe as AI-generated
    await sl<CompleteAddRecipeUseCase>().execute(
      recipeId: savedRecipeId,
      mode: 'ai_generated',
    );
    if (!context.mounted) return;
    setState(() => _isSavingAiDraft = false);

    // Show success message
    await showRecipeErrorDialog(
      context: context,
      title: "Recipe Saved",
      message: "Recipe saved.",
    );
  }

  /// Handles failed AI draft save by resetting loading state and showing error
  Future<void> _finishFailedSave(BuildContext context, String? message) async {
    // Failed AI draft saves reset loading state before displaying the error dialog.
    setState(() => _isSavingAiDraft = false);
    await showRecipeErrorDialog(
      context: context,
      message: message ?? "Unable to save recipe.",
    );
  }

  // ============================================================
  // Instructions Widget Builder
  // ============================================================

  /// Builds instruction widgets based on the layout mode (flat or sectioned)
  List<Widget> _instructionsWidgets(AddRecipeReview review) {
    if (!review.instructionUseSection) {
      // Flat instructions render directly without section headers.
      return review.instructions
          .map(
            (instruction) => ReviewInstructionItem(
              instruction: instruction,
              useSection: review.instructionUseSection,
            ),
          )
          .toList();
    }

    // Sectioned instructions are grouped by section index before rendering headers.
    final grouped = <int, List<AddRecipeReviewInstruction>>{};
    for (final instruction in review.instructions) {
      grouped.putIfAbsent(instruction.sectionIndex ?? 0, () => []);
      grouped[instruction.sectionIndex ?? 0]!.add(instruction);
    }

    // Build widgets for each section with a header
    return grouped.entries.expand((entry) {
      final title = entry.value.first.sectionTitle ?? "Section";
      return <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ...entry.value.map(
          (step) => ReviewInstructionItem(
            instruction: step,
            useSection: review.instructionUseSection,
          ),
        ),
      ];
    }).toList();
  }

  // ============================================================
  // Display Helpers
  // ============================================================

  /// Formats a list of strings as a comma-separated list or returns "-" if empty.
  String _joinOrDash(List<String> values) {
    final visibleValues = values.where((value) => value.trim().isNotEmpty);
    return visibleValues.isEmpty ? "-" : visibleValues.join(", ");
  }

  /// Converts micronutrient data to a list of info rows.
  List<Widget> _nutrientRows(List<AddRecipeReviewMicronutrient> nutrients) {
    return nutrients
        .map(
          (nutrient) => ReviewInfoRow(
            label: nutrient.label,
            value: '${nutrient.amount} (${nutrient.dailyValue})',
          ),
        )
        .toList(growable: false);
  }
}

// ============================================================
// Helper Widgets
// ============================================================

/// Subheader widget for organizing nutritional information
/// Used to group vitamins and minerals under their respective categories.
class _NutritionSubheader extends StatelessWidget {
  final String title;

  const _NutritionSubheader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF4B8),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Text(
        title,
        style: context.text.labelLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// Loading and Error Page
// ============================================================

// Loading Page
class _AddRecipePageLoading extends StatelessWidget {
  const _AddRecipePageLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingDialog(message: "Loading...", inline: true),
    );
  }
}

// Error Page
class _RecipeErrorState extends StatelessWidget {
  final String? message;

  const _RecipeErrorState({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/images/empty_page.png", height: 140),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message ?? "Unable to load page",
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

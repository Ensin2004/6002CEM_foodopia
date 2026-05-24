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
import '../../domain/entities/add_recipe_review.dart';
import '../../domain/usecases/complete_add_recipe_usecase.dart';
import '../../domain/usecases/get_add_recipe_review_usecase.dart';
import '../../domain/usecases/save_add_recipe_basic_info_usecase.dart';
import '../../domain/usecases/save_add_recipe_ingredients_usecase.dart';
import '../../domain/usecases/save_add_recipe_instructions_usecase.dart';
import '../viewmodel/add_recipe_review_viewmodel.dart';
import '../viewmodel/add_recipe_visibility_viewmodel.dart';
import '../widgets/recipe_visibility_confirm_action.dart';
import '../widgets/review/review_hero_image.dart';
import '../widgets/review/review_info_row.dart';
import '../widgets/review/review_ingredient_item.dart';
import '../widgets/review/review_instruction_item.dart';
import '../widgets/review/review_section_row.dart';

class AddRecipeReviewPage extends StatelessWidget {
  final String recipeId;
  final AddMealAiRecipe? initialAiRecipe;
  final AddMealAiGenerationRequest? initialAiRequest;
  final String? userId;
  final AddRecipeBasicInfo? aiDraftBasicInfo;
  final List<AddRecipeIngredient> aiDraftIngredients;
  final List<AddRecipeInstruction> aiDraftInstructions;
  final bool aiDraftUseSections;

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
  });

  @override
  Widget build(BuildContext context) {
    final aiReview = _buildAiReview();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final viewModel = AddRecipeReviewViewModel(
              getReviewUseCase: sl<GetAddRecipeReviewUseCase>(),
              deleteRecipeUseCase: sl(),
            );
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
      ),
    );
  }

  AddRecipeReview? _buildAiReview() {
    final basicInfo = aiDraftBasicInfo;
    final aiRecipe = initialAiRecipe;
    if (aiRecipe == null || basicInfo == null) return null;

    return AddRecipeReview(
      recipeId: '',
      media: basicInfo.existingMediaUrls,
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
        carbohydrates: '-',
        proteins: '-',
        fats: '-',
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

  String _formatAmount(double amount) {
    return amount % 1 == 0 ? amount.toInt().toString() : amount.toString();
  }
}

class _AddRecipeReviewView extends StatefulWidget {
  final String recipeId;
  final AddRecipeReview? aiReview;
  final AddRecipeBasicInfo? aiDraftBasicInfo;
  final List<AddRecipeIngredient> aiDraftIngredients;
  final List<AddRecipeInstruction> aiDraftInstructions;
  final bool aiDraftUseSections;

  const _AddRecipeReviewView({
    required this.recipeId,
    this.aiReview,
    this.aiDraftBasicInfo,
    this.aiDraftIngredients = const [],
    this.aiDraftInstructions = const [],
    this.aiDraftUseSections = false,
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
      return const LoadingDialog();
    }

    final review = widget.aiReview ?? viewModel.review;
    if (review == null) {
      return _RecipeErrorState(message: viewModel.errorMessage);
    }

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
      appBar: CustomAppBar(
        title: widget.aiReview == null ? "New Recipe" : "Customize AI Recipe",
        actions: widget.aiReview == null
            ? [
                Consumer<AddRecipeVisibilityViewModel>(
                  builder: (context, visibilityViewModel, _) {
                    return RecipeVisibilityActionButton(
                      visibility: visibilityViewModel.visibility,
                      isSaving: visibilityViewModel.isSaving,
                      onChanged: (value) async {
                        final success = await visibilityViewModel
                            .updateVisibility(
                              recipeId: widget.recipeId,
                              value: value,
                            );
                        if (!context.mounted || success) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              visibilityViewModel.errorMessage ??
                                  "Unable to update visibility.",
                            ),
                          ),
                        );
                      },
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
                labels: ["Basic Info", "Ingredients", "Instructions", "Review"],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.sm,
                horizontalPadding,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Label(text: "Review")),
                      if (widget.aiReview == null)
                        IconButton(
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
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  0,
                ),
                children: [
                  ReviewHeroImage(media: review.media),
                  const SizedBox(height: AppSpacing.lg),
                  ReviewSectionRow(
                    icon: Icons.info_rounded,
                    title: "Basic Info",
                    onEdit: widget.aiReview == null
                        ? () => context.push(
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
                        value: review.servings == 1
                            ? "${review.servings} serving"
                            : "${review.servings} servings",
                      ),
                      ReviewInfoRow(
                        label: "Allergen Info",
                        value: _joinOrDash(review.allergens),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ReviewSectionRow(
                    icon: Icons.science_rounded,
                    title: "Nutrients (AI Estimated)",
                    children: [
                      ReviewInfoRow(
                        label: "Calories",
                        value: review.nutrients.calories,
                      ),
                      ReviewInfoRow(
                        label: "Carbohydrates",
                        value: review.nutrients.carbohydrates,
                      ),
                      ReviewInfoRow(
                        label: "Proteins",
                        value: review.nutrients.proteins,
                      ),
                      ReviewInfoRow(
                        label: "Fats",
                        value: review.nutrients.fats,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ReviewSectionRow(
                    icon: Icons.eco_rounded,
                    title: "Ingredients",
                    onEdit: widget.aiReview == null
                        ? () => context.push(
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
                    children: review.ingredients
                        .map((item) => ReviewIngredientItem(ingredient: item))
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ReviewSectionRow(
                    icon: Icons.menu_book_rounded,
                    title: "Instructions",
                    onEdit: widget.aiReview == null
                        ? () => context.push(
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
                text: widget.aiReview == null ? "Save" : "Add Recipe",
                isLoading: _isSavingAiDraft,
                onPressed: _isSavingAiDraft
                    ? null
                    : widget.aiReview == null
                    ? () => _finishSavedRecipe(context)
                    : () => _saveAiDraft(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finishSavedRecipe(BuildContext context) {
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

  Future<void> _confirmDeleteRecipe(
    BuildContext context,
    AddRecipeReviewViewModel viewModel,
    AddRecipeReview review,
  ) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? "Unable to delete recipe."),
        ),
      );
      return;
    }

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

  Future<void> _saveAiDraft(BuildContext context) async {
    final basicInfo = widget.aiDraftBasicInfo;
    if (basicInfo == null) return;

    setState(() => _isSavingAiDraft = true);

    final basicResult = await sl<SaveAddRecipeBasicInfoUseCase>().execute(
      basicInfo,
    );
    if (!context.mounted) return;
    if (basicResult.isLeft()) {
      _finishFailedSave(context, basicResult.left?.message);
      return;
    }

    final savedRecipeId = basicResult.right!;
    final ingredientResult = await sl<SaveAddRecipeIngredientsUseCase>()
        .execute(
          recipeId: savedRecipeId,
          ingredients: widget.aiDraftIngredients,
        );
    if (!context.mounted) return;
    if (ingredientResult.isLeft()) {
      _finishFailedSave(context, ingredientResult.left?.message);
      return;
    }

    final instructionResult = await sl<SaveAddRecipeInstructionsUseCase>()
        .execute(
          recipeId: savedRecipeId,
          useSections: widget.aiDraftUseSections,
          instructions: widget.aiDraftInstructions,
        );
    if (!context.mounted) return;
    if (instructionResult.isLeft()) {
      _finishFailedSave(context, instructionResult.left?.message);
      return;
    }

    await sl<CompleteAddRecipeUseCase>().execute(
      recipeId: savedRecipeId,
      mode: 'ai_generated',
    );
    if (!context.mounted) return;
    setState(() => _isSavingAiDraft = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Recipe saved.")));
  }

  void _finishFailedSave(BuildContext context, String? message) {
    setState(() => _isSavingAiDraft = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? "Unable to save recipe.")),
    );
  }

  List<Widget> _instructionsWidgets(AddRecipeReview review) {
    if (!review.instructionUseSection) {
      return review.instructions
          .map(
            (instruction) => ReviewInstructionItem(
              instruction: instruction,
              useSection: review.instructionUseSection,
            ),
          )
          .toList();
    }

    final grouped = <int, List<AddRecipeReviewInstruction>>{};
    for (final instruction in review.instructions) {
      grouped.putIfAbsent(instruction.sectionIndex ?? 0, () => []);
      grouped[instruction.sectionIndex ?? 0]!.add(instruction);
    }

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

  String _joinOrDash(List<String> values) {
    final visibleValues = values.where((value) => value.trim().isNotEmpty);
    return visibleValues.isEmpty ? "-" : visibleValues.join(", ");
  }
}

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

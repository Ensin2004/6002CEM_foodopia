import 'package:flutter/material.dart';
import 'package:foodopia/features/recipe/presentation/widgets/label.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/progress_bar/app_step_progress_bar.dart';
import '../../domain/entities/add_recipe_review.dart';
import '../../domain/usecases/get_add_recipe_review_usecase.dart';
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

  const AddRecipeReviewPage({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AddRecipeReviewViewModel(
            getReviewUseCase: sl<GetAddRecipeReviewUseCase>(),
            deleteRecipeUseCase: sl(),
          )..loadReview(recipeId),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              AddRecipeVisibilityViewModel(updateVisibilityUseCase: sl()),
        ),
      ],
      child: _AddRecipeReviewView(recipeId: recipeId),
    );
  }
}

class _AddRecipeReviewView extends StatelessWidget {
  final String recipeId;

  const _AddRecipeReviewView({required this.recipeId});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddRecipeReviewViewModel>();
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 600
        ? 48.0
        : AppSpacing.lg;

    if (viewModel.isLoading) {
      return const LoadingDialog();
    }

    final review = viewModel.review;
    if (review == null) {
      return _RecipeErrorState(message: viewModel.errorMessage);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.read<AddRecipeVisibilityViewModel>().seedVisibility(
        review.visibility,
      );
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "New Recipe",
        actions: [
          Consumer<AddRecipeVisibilityViewModel>(
            builder: (context, visibilityViewModel, _) {
              return RecipeVisibilityConfirmAction(
                recipeId: recipeId,
                viewModel: visibilityViewModel,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Bar
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

            // Recipe Information
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  0,
                ),
                children: [
                  // Recipe Image
                  ReviewHeroImage(media: review.media),
                  const SizedBox(height: AppSpacing.lg),

                  // Basic Info Section
                  ReviewSectionRow(
                    icon: Icons.info_rounded,
                    title: "Basic Info",
                    onEdit: () => _openEditSection(
                      context,
                      viewModel,
                      route: AppRouter.addRecipeBasicInfo,
                      extra: AddRecipeBasicInfoArgs(
                        recipeId: recipeId,
                        returnToReview: true,
                      ),
                    ),
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

                  // Nutrients Section
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

                  // Ingredients Section
                  ReviewSectionRow(
                    icon: Icons.eco_rounded,
                    title: "Ingredients",
                    onEdit: () => _openEditSection(
                      context,
                      viewModel,
                      route: AppRouter.addRecipeIngredients,
                      extra: AddRecipeIngredientsArgs(
                        recipeId: recipeId,
                        visibility: context
                            .read<AddRecipeVisibilityViewModel>()
                            .visibility,
                        returnToReview: true,
                      ),
                    ),
                    children: review.ingredients
                        .map((item) => ReviewIngredientItem(ingredient: item))
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Instructions Section
                  ReviewSectionRow(
                    icon: Icons.menu_book_rounded,
                    title: "Instructions",
                    onEdit: () => _openEditSection(
                      context,
                      viewModel,
                      route: AppRouter.addRecipeInstructions,
                      extra: AddRecipeInstructionsArgs(
                        recipeId: recipeId,
                        visibility: context
                            .read<AddRecipeVisibilityViewModel>()
                            .visibility,
                        returnToReview: true,
                      ),
                    ),
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
                text: "Save",
                onPressed: () {
                  final visibility = context
                      .read<AddRecipeVisibilityViewModel>()
                      .visibility;

                  context.go(
                    Uri(
                      path: AppRouter.home,
                      queryParameters: {
                        'tab': '4',
                        'focusedRecipeId': recipeId,
                        'focusedRecipeIsPublished': '${visibility == "public"}',
                        'createdAt': DateTime.now().microsecondsSinceEpoch
                            .toString(),
                      },
                    ).toString(),
                    extra: HomeArgs(
                      initialTabIndex: 4,
                      focusedRecipeId: recipeId,
                      focusedRecipeIsPublished: visibility == "public",
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditSection(
    BuildContext context,
    AddRecipeReviewViewModel viewModel, {
    required String route,
    required Object extra,
  }) async {
    final didSave = await context.push<bool>(route, extra: extra);
    if (!context.mounted || didSave != true) return;

    await viewModel.loadReview(recipeId);
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

  // Instruction Widget Helper
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

  // Join Helper
  String _joinOrDash(List<String> values) {
    final visibleValues = values.where((value) => value.trim().isNotEmpty);
    return visibleValues.isEmpty ? "-" : visibleValues.join(", ");
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

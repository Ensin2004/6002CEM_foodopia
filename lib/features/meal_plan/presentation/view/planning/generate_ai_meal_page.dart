import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../app/dependency_injection/injection_container.dart';
import '../../../../../app/routers/app_router.dart';
import '../../../../../app/routers/router_args.dart';
import '../../../../../core/extensions/either_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/box/app_tip_box.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../../core/widgets/progress_bar/app_step_progress_bar.dart';
import '../../../../recipe/domain/entities/add_recipe_basic_info.dart';
import '../../../../recipe/domain/usecases/complete_add_recipe_usecase.dart';
import '../../../../recipe/domain/usecases/save_add_recipe_basic_info_usecase.dart';
import '../../../../recipe/domain/usecases/save_add_recipe_ingredients_usecase.dart';
import '../../../../recipe/domain/usecases/save_add_recipe_instructions_usecase.dart';
import '../../../../recipe/presentation/view/add_recipe_basic_info_page.dart';
import '../../../../recipe/presentation/view/add_recipe_ingredients_page.dart';
import '../../../../recipe/presentation/view/add_recipe_instructions_page.dart';
import '../../../../recipe/presentation/view/add_recipe_review_page.dart';
import '../../../domain/entities/add_meal_ai_plan.dart';
import '../../../domain/entities/meal_calorie_guidance.dart';
import '../../../domain/entities/meal_plan_inspiration_input.dart';
import '../../../domain/entities/meal_serving_amount.dart';
import '../../../domain/usecases/generate_ai_meal_ideas_usecase.dart';
import '../../../domain/usecases/get_add_meal_ai_plan_usecase.dart';
import '../../../domain/usecases/get_meal_plan_default_ingredients_usecase.dart';
import '../../../domain/usecases/get_meal_plan_inspiration_options_usecase.dart';
import '../../../domain/usecases/get_meal_categories_usecase.dart';
import '../../../domain/usecases/save_ai_meal_plan_usecase.dart';
import '../../../domain/usecases/search_meal_plan_ingredients_usecase.dart';
import '../../viewmodel/ai/generate_ai_meal_viewmodel.dart';
import '../../widgets/planning/meal_serving_dialog.dart';

part '../../widgets/ai_meal/factor_step.dart';
part '../../widgets/ai_meal/ai_results_step.dart';
part '../../widgets/ai_meal/instructions_review_step.dart';
part '../../widgets/ai_meal/generate_ai_shared_form_widgets.dart';
part '../../widgets/ai_meal/recipe_result_card.dart';
part '../../widgets/ai_meal/generate_ai_planning_controls.dart';

/// Page for generating AI-powered meal plans.
/// Provides a multi-step wizard for configuring and generating AI meal ideas.
class GenerateAiMealPage extends StatelessWidget {
  /// User ID for the current user.
  final String userId;

  /// Type of meal to generate (e.g., breakfast, lunch, dinner).
  final String mealType;

  /// Optional meal category ID.
  final String? mealCategoryId;

  /// Optional selected date for the meal plan.
  final DateTime? selectedDate;

  /// Optional initial generation request.
  final AddMealAiGenerationRequest? initialRequest;

  /// Whether to auto-generate on page load.
  final bool autoGenerate;

  /// Calorie budget for the selected day.
  final MealCalorieBudget calorieBudget;

  /// Existing planned meal names to avoid repeating.
  final List<String> existingMealNames;

  /// Creates a new generate AI meal page instance.
  const GenerateAiMealPage({
    super.key,
    required this.userId,
    required this.mealType,
    this.mealCategoryId,
    this.selectedDate,
    this.initialRequest,
    this.autoGenerate = false,
    this.calorieBudget = const MealCalorieBudget.empty(),
    this.existingMealNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Provide the view model to the widget tree.
    return ChangeNotifierProvider(
      create: (_) => GenerateAiMealViewModel(
        userId: userId,
        mealType: mealType,
        mealCategoryId: mealCategoryId,
        selectedDate: selectedDate,
        initialRequest: initialRequest,
        autoGenerate: autoGenerate,
        calorieBudget: calorieBudget,
        existingMealNames: existingMealNames,
        getPlanUseCase: sl<GetAddMealAiPlanUseCase>(),
        generateIdeasUseCase: sl<GenerateAiMealIdeasUseCase>(),
        getMealCategoriesUseCase: sl<GetMealCategoriesUseCase>(),
        saveAiMealPlanUseCase: sl<SaveAiMealPlanUseCase>(),
        getDefaultIngredientsUseCase:
            sl<GetMealPlanDefaultIngredientsUseCase>(),
        getInspirationOptionsUseCase:
            sl<GetMealPlanInspirationOptionsUseCase>(),
        searchIngredientsUseCase: sl<SearchMealPlanIngredientsUseCase>(),
      ),
      child: const _GenerateAiMealView(),
    );
  }
}

/// Inline AI generation form that reuses the same factor form as the page flow.
class GenerateAiMealInlineRequestForm extends StatelessWidget {
  /// User ID for the current user.
  final String userId;

  /// Type of meal to generate.
  final String mealType;

  /// Optional meal category ID.
  final String? mealCategoryId;

  /// Optional selected date for the meal plan.
  final DateTime? selectedDate;

  /// Optional initial generation request.
  final AddMealAiGenerationRequest? initialRequest;

  /// Calorie budget for the selected day.
  final MealCalorieBudget calorieBudget;

  /// Existing planned meal names to avoid repeating.
  final List<String> existingMealNames;

  /// Callback with the shared form request when generate is pressed.
  final ValueChanged<AddMealAiGenerationRequest> onGenerateRequest;

  /// Creates a new inline AI generation form.
  const GenerateAiMealInlineRequestForm({
    super.key,
    required this.userId,
    required this.mealType,
    this.mealCategoryId,
    this.selectedDate,
    this.initialRequest,
    this.calorieBudget = const MealCalorieBudget.empty(),
    this.existingMealNames = const [],
    required this.onGenerateRequest,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GenerateAiMealViewModel(
        userId: userId,
        mealType: mealType,
        mealCategoryId: mealCategoryId,
        selectedDate: selectedDate,
        initialRequest: initialRequest,
        calorieBudget: calorieBudget,
        existingMealNames: existingMealNames,
        getPlanUseCase: sl<GetAddMealAiPlanUseCase>(),
        generateIdeasUseCase: sl<GenerateAiMealIdeasUseCase>(),
        getMealCategoriesUseCase: sl<GetMealCategoriesUseCase>(),
        saveAiMealPlanUseCase: sl<SaveAiMealPlanUseCase>(),
        getDefaultIngredientsUseCase:
            sl<GetMealPlanDefaultIngredientsUseCase>(),
        getInspirationOptionsUseCase:
            sl<GetMealPlanInspirationOptionsUseCase>(),
        searchIngredientsUseCase: sl<SearchMealPlanIngredientsUseCase>(),
      ),
      child: _InlineGenerateAiMealFormView(
        onGenerateRequest: onGenerateRequest,
      ),
    );
  }
}

/// Internal inline form view.
class _InlineGenerateAiMealFormView extends StatelessWidget {
  /// Callback with the shared form request when generate is pressed.
  final ValueChanged<AddMealAiGenerationRequest> onGenerateRequest;

  /// Creates a new inline form view.
  const _InlineGenerateAiMealFormView({required this.onGenerateRequest});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenerateAiMealViewModel>();

    if (viewModel.isLoading && viewModel.plan == null) {
      return const SizedBox(
        height: 160,
        child: LoadingDialog(inline: true, message: 'Loading AI meal setup...'),
      );
    }

    final plan = viewModel.plan;
    if (plan == null) {
      return _ErrorState(
        message: viewModel.errorMessage ?? 'Unable to load AI meal setup',
        onRetry: viewModel.loadPlan,
      );
    }

    return _GenerateAiFactorFormContent(
      plan: plan,
      onGenerate: () => onGenerateRequest(
        context.read<GenerateAiMealViewModel>().generationRequest,
      ),
    );
  }
}

/// Internal view widget for the AI meal generation page.
class _GenerateAiMealView extends StatelessWidget {
  /// Creates a new generate AI meal view instance.
  const _GenerateAiMealView();

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Show loading dialog while plan is loading.
    if (viewModel.isLoading && viewModel.plan == null) {
      return const Scaffold(
        body: LoadingDialog(message: 'Loading AI meal setup...'),
      );
    }

    // Get the current plan.
    final plan = viewModel.plan;

    // Show error state if plan is null.
    if (plan == null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Generate with AI',
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.chevron_left),
          ),
        ),
        body: _ErrorState(
          message: viewModel.errorMessage ?? 'Unable to load AI meal setup',
          onRetry: viewModel.loadPlan,
        ),
      );
    }

    // Determine if this is an inspiration flow.
    final isInspirationFlow = viewModel.sourceRequest != null;

    // Define progress labels based on flow type.
    final progressLabels = isInspirationFlow
        ? const ['AI Result', 'Instructions', 'Review']
        : const ['Factor', 'AI Result', 'Instructions', 'Review'];

    // Calculate current progress step.
    final progressStep = isInspirationFlow
        ? (viewModel.currentStep - 1).clamp(1, 3)
        : viewModel.currentStep;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: viewModel.currentStep == 4
            ? 'Add to Meal Plan'
            : isInspirationFlow
            ? 'Inspiration'
            : 'Generate with AI',
        leading: IconButton(
          onPressed: () {
            if (viewModel.currentStep > 1) {
              // Go back to previous step.
              context.read<GenerateAiMealViewModel>().goToPreviousStep();
            } else {
              // Pop the page.
              context.pop();
            }
          },
          icon: const Icon(Icons.chevron_left),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Progress bar at the top.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.md,
                  ),
                  child: AppStepProgressBar(
                    totalSteps: progressLabels.length,
                    currentStep: progressStep,
                    labels: progressLabels,
                  ),
                ),
                // Dynamic step body.
                Expanded(child: _StepBody(plan: plan)),
              ],
            ),
          ),
          // Loading overlay when generating.
          if (viewModel.isGenerating) ...[
            const Positioned.fill(child: ColoredBox(color: Colors.white)),
            const Positioned.fill(
              child: LoadingDialog(
                message: 'Generating AI recipes and images...',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget that displays the current step's content.

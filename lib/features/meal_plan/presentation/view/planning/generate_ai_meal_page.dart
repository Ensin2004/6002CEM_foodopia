import 'dart:convert';

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
import '../../../domain/entities/meal_plan_inspiration_input.dart';
import '../../../domain/usecases/generate_ai_meal_ideas_usecase.dart';
import '../../../domain/usecases/get_add_meal_ai_plan_usecase.dart';
import '../../../domain/usecases/get_meal_plan_default_ingredients_usecase.dart';
import '../../../domain/usecases/get_meal_plan_inspiration_options_usecase.dart';
import '../../../domain/usecases/get_meal_categories_usecase.dart';
import '../../../domain/usecases/save_ai_meal_plan_usecase.dart';
import '../../../domain/usecases/search_meal_plan_ingredients_usecase.dart';
import '../../viewmodel/generate_ai_meal_viewmodel.dart';

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

  /// Creates a new generate AI meal page instance.
  const GenerateAiMealPage({
    super.key,
    required this.userId,
    required this.mealType,
    this.mealCategoryId,
    this.selectedDate,
    this.initialRequest,
    this.autoGenerate = false,
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
        body: LoadingDialog(inline: true, message: 'Loading AI meal setup...'),
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
class _AiResultsStep extends StatefulWidget {
  /// The meal plan data.
  final AddMealAiPlan plan;

  /// Creates a new AI results step instance.
  const _AiResultsStep({required this.plan});

  @override
  State<_AiResultsStep> createState() => _AiResultsStepState();
}

/// State for the AI results step.
class _AiResultsStepState extends State<_AiResultsStep>
    with SingleTickerProviderStateMixin {
  /// Tab controller for switching between database and AI results.
  TabController? _tabController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get the view model.
    final showDatabase = context
        .read<GenerateAiMealViewModel>()
        .showDatabaseResults;

    // Determine expected tab length.
    final expectedLength = showDatabase ? 2 : 1;

    // Skip if controller already has correct length.
    if (_tabController?.length == expectedLength) return;

    // Dispose old controller and create new one.
    _tabController?.dispose();
    _tabController = TabController(length: expectedLength, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Get the plan.
    final plan = widget.plan;

    // Determine if database results should be shown.
    final showDatabase = viewModel.showDatabaseResults;

    // Get the tab controller.
    final tabController = _tabController;

    return Column(
      children: [
        // Header section.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              // Tip box.
              const AppTipBox(
                title: 'Foodopia AI will suggest meal ideas',
                message:
                'Review AI-created ideas before customising or adding them to your meal plan.',
                backgroundColor: Color(0xFFFFF8E1),
                iconColor: AppColors.secondary,
                icon: Icons.tips_and_updates_outlined,
              ),
              const SizedBox(height: AppSpacing.md),

              // Filter pills.
              if (showDatabase)
                Row(
                  children: [
                    _Pill(icon: Icons.wb_sunny_outlined, label: plan.mealType),
                    const SizedBox(width: AppSpacing.sm),
                    _Pill(
                      icon: Icons.calendar_today_outlined,
                      label: DateFormat('d MMM yyyy').format(plan.planningDate),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _Pill(
                      icon: Icons.people_outline,
                      label: viewModel.selectedServingSize,
                    ),
                  ],
                ),

              // Tab bar for switching views.
              if (showDatabase && tabController != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: context.text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    tabs: const [
                      Tab(text: 'Recipe Database'),
                      Tab(text: 'AI Ideas'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Tab content.
        Expanded(
          child: showDatabase && tabController != null
              ? TabBarView(
            controller: tabController,
            children: [
              _DatabaseRecipeResults(recipes: plan.topMatches),
              _AiCreatedRecipeResults(recipes: plan.aiIdeas),
            ],
          )
              : _AiCreatedRecipeResults(recipes: plan.aiIdeas),
        ),
      ],
    );
  }
}

/// Database recipe results view.
class _DatabaseRecipeResults extends StatelessWidget {
  /// List of recipes.
  final List<AddMealAiRecipe> recipes;

  /// Creates a new database recipe results instance.
  const _DatabaseRecipeResults({required this.recipes});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Show empty state if no recipes.
    if (recipes.isEmpty) {
      return _NoDatabaseRecipes(onNext: viewModel.goToNextStep);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Text(
          'Top Matches from Recipe Database',
          style: context.text.titleMedium,
        ),
        Text(
          'Relevant recipes are found in your recipe database.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...recipes.map((recipe) => _RecipeResultCard(recipe: recipe)),
        const SizedBox(height: AppSpacing.lg),
        _PrimaryActionButton(
          label: 'Next',
          onPressed: viewModel.selectedRecipes.isEmpty
              ? null
              : viewModel.goToNextStep,
        ),
      ],
    );
  }
}

/// Empty state for database recipes.
class _NoDatabaseRecipes extends StatelessWidget {
  /// Callback for next button.
  final VoidCallback onNext;

  /// Creates a new no database recipes instance.
  const _NoDatabaseRecipes({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Image.asset('assets/images/empty_page.png', height: 140),
        const SizedBox(height: AppSpacing.md),
        Text(
          'No matching recipes found',
          textAlign: TextAlign.center,
          style: context.text.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'There are no database recipes matching these factors yet. Try the AI Ideas tab for generated suggestions.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xl),
        _PrimaryActionButton(label: 'Next', onPressed: onNext),
      ],
    );
  }
}

/// AI created recipe results view.
class _AiCreatedRecipeResults extends StatelessWidget {
  /// List of recipes.
  final List<AddMealAiRecipe> recipes;

  /// Creates a new AI created recipe results instance.
  const _AiCreatedRecipeResults({required this.recipes});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Show error state if no recipes.
    if (recipes.isEmpty) {
      return _ErrorState(
        message:
        viewModel.errorMessage ??
            'No AI ideas generated yet. Try generating again.',
        onRetry: viewModel.generateIdeas,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Text('AI-Created Ideas', style: context.text.titleMedium),
        Text(
          'AI has helped you create some ideas from your factors.',
          style: context.text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),

        // Recipe cards.
        ...recipes.map((recipe) => _RecipeResultCard(recipe: recipe)),
        const SizedBox(height: AppSpacing.md),

        // Generate more button.
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            border: Border.all(color: AppColors.secondary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Not satisfied with the results?',
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Let AI create more ideas based on your preferences.',
                style: context.text.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton(
                onPressed: viewModel.generateIdeas,
                child: const Text('Generate More'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Next button.
        _PrimaryActionButton(
          label: 'Next',
          onPressed: viewModel.selectedRecipes.isEmpty
              ? null
              : viewModel.goToNextStep,
        ),
      ],
    );
  }
}

/// Step 3: Instructions step.
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
class _MiniInfoTile extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Label text.
  final String label;

  /// Value text.
  final String value;

  /// Creates a new mini info tile instance.
  const _MiniInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.text.bodySmall),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Expandable factor card widget.
class _ExpandableFactorCard extends StatefulWidget {
  /// Icon to display.
  final IconData icon;

  /// Title text.
  final String title;

  /// Subtitle text.
  final String subtitle;

  /// Selected labels to display.
  final List<String> selectedLabels;

  /// Children widgets.
  final List<Widget> children;

  /// Creates a new expandable factor card instance.
  const _ExpandableFactorCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selectedLabels,
    required this.children,
  });

  @override
  State<_ExpandableFactorCard> createState() => _ExpandableFactorCardState();
}

/// State for the expandable factor card.
class _ExpandableFactorCardState extends State<_ExpandableFactorCard> {
  /// Whether the card is expanded.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Filter out empty labels.
    final labels = widget.selectedLabels
        .where((label) => label.trim().isNotEmpty)
        .toSet()
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header with expand/collapse toggle.
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(widget.icon, color: AppColors.textSecondary, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: context.text.titleMedium),
                        const SizedBox(height: 2),
                        Text(widget.subtitle, style: context.text.bodySmall),
                        if (labels.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _ChipWrap(values: labels, selectedValues: labels),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down, size: 18),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content.
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children,
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

/// Word limited text input widget.
class _WordLimitedTextInput extends StatefulWidget {
  /// Hint text.
  final String hintText;

  /// Callback when text changes.
  final ValueChanged<String> onChanged;

  /// Creates a new word limited text input instance.
  const _WordLimitedTextInput({
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<_WordLimitedTextInput> createState() => _WordLimitedTextInputState();
}

/// State for the word limited text input.
class _WordLimitedTextInputState extends State<_WordLimitedTextInput> {
  /// Maximum number of words allowed.
  static const _maxWords = 30;

  /// Text controller.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Count words in the current text.
    final count = _wordCount(_controller.text);

    return TextField(
      controller: _controller,
      onChanged: (value) {
        // Limit the number of words.
        final limited = _limitWords(value);

        // Update controller if limited.
        if (limited != value) {
          _controller.value = TextEditingValue(
            text: limited,
            selection: TextSelection.collapsed(offset: limited.length),
          );
        }

        // Call the onChanged callback.
        widget.onChanged(limited);

        // Update the state.
        setState(() {});
      },
      minLines: 1,
      maxLines: 3,
      style: context.text.bodySmall?.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hintText,
        helperText: '$count/$_maxWords words',
        hintStyle: context.text.bodySmall?.copyWith(
          color: AppColors.textSecondary.withValues(alpha: 0.65),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  /// Counts the number of words in a string.
  int _wordCount(String value) {
    return value.trim().isEmpty ? 0 : value.trim().split(RegExp(r'\s+')).length;
  }

  /// Limits a string to the maximum number of words.
  String _limitWords(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    if (value.trim().isEmpty || words.length <= _maxWords) return value;
    return words.take(_maxWords).join(' ');
  }
}

/// Difficulty level picker widget.
class _DifficultyLevelPicker extends StatelessWidget {
  /// Selected difficulty level.
  final int selectedLevel;

  /// Callback when a level is selected.
  final ValueChanged<int> onSelected;

  /// Creates a new difficulty level picker instance.
  const _DifficultyLevelPicker({
    required this.selectedLevel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Define difficulty levels.
    const levels = ['Novice', 'Beginner', 'Intermediate', 'Advanced', 'Master'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Difficulty Level'),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: levels.asMap().entries.map((entry) {
              final levelValue = entry.key + 1;
              final selected = levelValue <= selectedLevel;
              return Expanded(
                child: InkWell(
                  onTap: () => onSelected(levelValue),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        size: 24,
                        color: selected
                            ? AppColors.secondary
                            : AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          entry.value,
                          maxLines: 1,
                          style: context.text.bodySmall?.copyWith(
                            fontSize: 9,
                            color: selected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Cooking minutes input widget.
class _CookingMinutesInput extends StatelessWidget {
  /// Current minutes value.
  final int minutes;

  /// Callback when minutes change.
  final ValueChanged<String> onChanged;

  /// Creates a new cooking minutes input instance.
  const _CookingMinutesInput({required this.minutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Cooking Time'),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          initialValue: minutes.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: context.text.bodySmall?.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. 30',
            suffixText: 'minutes',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Serving size input widget.
class _ServingSizeInput extends StatelessWidget {
  /// Current servings value.
  final int servings;

  /// Callback when servings change.
  final ValueChanged<String> onChanged;

  /// Creates a new serving size input instance.
  const _ServingSizeInput({required this.servings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Servings'),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          initialValue: servings.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: context.text.bodySmall?.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. 1',
            suffixText: 'servings',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Chip wrap widget.
class _ChipWrap extends StatelessWidget {
  /// List of values to display as chips.
  final List<String> values;

  /// List of selected values.
  final List<String> selectedValues;

  /// Callback when a chip is selected.
  final ValueChanged<String>? onSelected;

  /// Whether to use danger styling.
  final bool danger;

  /// Creates a new chip wrap instance.
  const _ChipWrap({
    required this.values,
    required this.selectedValues,
    this.onSelected,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    // Create a set of selected values for quick lookup.
    final selectedSet = selectedValues.toSet();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: values.map((value) {
        final selected = selectedSet.contains(value);
        return InkWell(
          onTap: onSelected == null ? null : () => onSelected!(value),
          borderRadius: BorderRadius.circular(12),
          child: _SmallChip(label: value, selected: selected, danger: danger),
        );
      }).toList(),
    );
  }
}

/// Section label widget.
class _SectionLabel extends StatelessWidget {
  /// Label text.
  final String label;

  /// Creates a new section label instance.
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.text.bodySmall?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

/// Selected summary text widget.
class _SelectedSummaryText extends StatelessWidget {
  /// Text to display.
  final String text;

  /// Creates a new selected summary text instance.
  const _SelectedSummaryText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.text.bodySmall?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

/// Factor card widget.
class _FactorCard extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Title text.
  final String title;

  /// Subtitle text.
  final String subtitle;

  /// Whether to highlight the card.
  final bool highlighted;

  /// Creates a new factor card instance.
  const _FactorCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.secondary.withValues(alpha: 0.18)
            : Colors.white,
        border: Border.all(
          color: highlighted
              ? AppColors.secondary.withValues(alpha: 0.75)
              : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: highlighted
                ? const Color(0xFF8A6400)
                : AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Recipe result card widget.
class _RecipeResultCard extends StatelessWidget {
  /// Recipe data.
  final AddMealAiRecipe recipe;

  /// Creates a new recipe result card instance.
  const _RecipeResultCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<GenerateAiMealViewModel>();

    // Check if recipe is selected.
    final selected = viewModel.isRecipeSelected(recipe.id);

    // Determine border color.
    final borderColor = selected ? AppColors.primary : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFFAF1) : Colors.white,
        border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: selected
            ? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ]
            : null,
      ),
      child: Column(
        children: [
          // Recipe header.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _RecipeThumb(recipe: recipe, size: 68),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.title, style: context.text.titleMedium),
                    Text(
                      '${recipe.durationLabel}   ${recipe.difficultyLabel}',
                      style: context.text.bodySmall,
                    ),
                    Text(
                      _nutritionSummary(recipe),
                      style: context.text.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(recipe.description, style: context.text.bodySmall),
                  ],
                ),
              ),
              if (selected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Recommendation reasons.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFAF1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why we recommend this:',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                ...recipe.reasons.map(
                      (reason) => Text(
                    '- $reason',
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Select button.
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  onPressed: () {
                    context.read<GenerateAiMealViewModel>().toggleRecipe(
                      recipe.id,
                    );
                  },
                  text: selected ? 'Selected' : 'Select',
                  verticalPadding: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Review recipe card widget.
class _ReviewRecipeCard extends StatelessWidget {
  /// Recipe data.
  final AddMealAiRecipe recipe;

  /// Creates a new review recipe card instance.
  const _ReviewRecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    // Define macro stats.
    final macros = [
      _MacroStat(
        label: 'Carbs',
        value: recipe.carbohydrates,
        color: AppColors.primary,
      ),
      _MacroStat(label: 'Protein', value: recipe.protein, color: Colors.blue),
      _MacroStat(label: 'Fat', value: recipe.fat, color: AppColors.secondary),
    ];

    // Calculate total macros.
    final totalMacros = macros.fold<double>(0, (sum, item) => sum + item.value);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe image.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: _RecipeThumb(recipe: recipe, size: double.infinity),
                ),
                Positioned(
                  left: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: _ReviewBadge(
                    icon: Icons.local_fire_department_outlined,
                    label: '${recipe.calories} kcal',
                    emphasized: true,
                  ),
                ),
              ],
            ),
          ),

          // Recipe details.
          Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  recipe.title,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  recipe.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(height: 1.35),
                ),
                const SizedBox(height: AppSpacing.md),

                // Badges.
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _ReviewBadge(
                      icon: Icons.schedule,
                      label: recipe.durationLabel,
                    ),
                    _ReviewBadge(
                      icon: Icons.signal_cellular_alt,
                      label: recipe.difficultyLabel,
                    ),
                    _ReviewBadge(
                      icon: Icons.room_service_outlined,
                      label: recipe.servingLabel,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Macro summary.
                Row(
                  children: [
                    for (final macro in macros) ...[
                      Expanded(
                        child: _MacroSummaryItem(
                          label: macro.label,
                          value: macro.value,
                          color: macro.color,
                        ),
                      ),
                      if (macro != macros.last)
                        const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Macro progress bar.
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Row(
                    children: [
                      for (final macro in macros)
                        Expanded(
                          flex: totalMacros <= 0
                              ? 1
                              : (macro.value / totalMacros * 100).round().clamp(
                            1,
                            100,
                          ),
                          child: Container(height: 8, color: macro.color),
                        ),
                    ],
                  ),
                ),

                // Reasons.
                if (recipe.reasons.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Why this fits',
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final reason in recipe.reasons.take(3))
                        _ReasonChip(reason: reason),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Macro stat data class.
class _MacroStat {
  /// Label text.
  final String label;

  /// Value.
  final double value;

  /// Color.
  final Color color;

  /// Creates a new macro stat instance.
  const _MacroStat({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Review badge widget.
class _ReviewBadge extends StatelessWidget {
  /// Icon to display.
  final IconData icon;

  /// Label text.
  final String label;

  /// Whether to emphasize the badge.
  final bool emphasized;

  /// Creates a new review badge instance.
  const _ReviewBadge({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine foreground color.
    final foreground = emphasized ? Colors.white : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: emphasized ? AppColors.primary : const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(8),
        border: emphasized ? null : Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Macro summary item widget.
class _MacroSummaryItem extends StatelessWidget {
  /// Label text.
  final String label;

  /// Value.
  final double value;

  /// Color.
  final Color color;

  /// Creates a new macro summary item instance.
  const _MacroSummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_macroValue(value)}g',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reason chip widget.
class _ReasonChip extends StatelessWidget {
  /// Reason text.
  final String reason;

  /// Creates a new reason chip instance.
  const _ReasonChip({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
      ),
      child: Text(
        reason,
        style: context.text.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Builds a nutrition summary string.
String _nutritionSummary(AddMealAiRecipe recipe) {
  final macros = [
    '${recipe.calories} kcal',
    'C ${_macroValue(recipe.carbohydrates)}g',
    'P ${_macroValue(recipe.protein)}g',
    'F ${_macroValue(recipe.fat)}g',
  ];
  return macros.join(' | ');
}

/// Formats a macro value with appropriate decimal places.
String _macroValue(double value) {
  return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
}

/// Date scroller widget.
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
    final activeColor = danger ? AppColors.error : AppColors.primary;

    // Determine fill color.
    final selectedFill = danger
        ? AppColors.error.withValues(alpha: 0.08)
        : const Color(0xFFEAF7EC);
    final inactiveColor = danger
        ? AppColors.error.withValues(alpha: 0.035)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: selected ? selectedFill : inactiveColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? activeColor.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: context.text.bodySmall?.copyWith(
          color: selected ? activeColor : AppColors.textSecondary,
          fontSize: 10,
        ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
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
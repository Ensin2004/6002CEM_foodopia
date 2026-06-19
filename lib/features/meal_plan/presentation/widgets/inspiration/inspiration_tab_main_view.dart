import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../app/routers/router_args.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../domain/entities/meal_plan_inspiration_input.dart';
import '../../../domain/entities/meal_plan_dashboard.dart';
import '../../../domain/entities/add_meal_ai_plan.dart';
import '../../../domain/entities/meal_calorie_guidance.dart';
import '../../viewmodel/meal_plan_viewmodel.dart';

part 'smart_inspiration_box.dart';
part 'inspiration_input_cards.dart';
part 'ingredient_picker_sheet.dart';
part 'preference_editor_sheet.dart';
part 'quick_inspiration_grid.dart';

/// List of quick inspiration items.
const _quickInspirationItems = [
  MealPlanQuickInspiration(
    title: 'What can I cook with what I have?',
    subtitle: 'Use ingredients you already have.',
    imagePath: 'assets/images/inspiration_what_can_i_cook_with_what_i_have.png',
  ),
  MealPlanQuickInspiration(
    title: 'Surprise me!',
    subtitle: 'Get AI-picked recipes for you.',
    imagePath: 'assets/images/inspiration_surprise_me.png',
  ),
  MealPlanQuickInspiration(
    title: 'Healthy Ideas',
    subtitle: 'Nutritious and balanced meals.',
    imagePath: 'assets/images/inspiration_healthy_ideas.png',
  ),
  MealPlanQuickInspiration(
    title: 'Quick & Easy',
    subtitle: 'Recipes you can make in no time.',
    imagePath: 'assets/images/inspiration_quick_and_easy.png',
  ),
  MealPlanQuickInspiration(
    title: 'Rainy Day Comfort',
    subtitle: 'Warm bowls and cozy meal ideas.',
    imagePath: 'assets/images/inspiration_rainy_day_comfort.png',
  ),
  MealPlanQuickInspiration(
    title: 'High Protein Picks',
    subtitle: 'Filling meals with simple prep.',
    imagePath: 'assets/images/inspiration_high_protein_picks.png',
  ),
];

/// Main view for the Inspiration tab in the meal plan page.
/// Provides AI recipe generation and quick inspiration cards.
class InspirationTabMainView extends StatelessWidget {
  /// The meal plan dashboard data.
  final MealPlanDashboard dashboard;

  /// Creates a new inspiration tab main view instance.
  const InspirationTabMainView({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    // Watch the view model for state changes.
    final viewModel = context.watch<MealPlanViewModel>();

    // Get preferences and weather.
    final preferences = viewModel.effectivePreferences;
    final weather = dashboard.weather;

    return ExcludeSemantics(
      child: ListView(
        key: const PageStorageKey<String>('meal_plan_inspiration_tab'),
        addSemanticIndexes: false,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          // Smart inspiration box.
          _SmartInspirationBox(
            weather: weather,
            preferences: preferences,
            ingredientsLabel: viewModel.selectedIngredientsLabel,
            isWeatherLoading: viewModel.isWeatherLoading,
            isPreferencesLoading: viewModel.isPreferencesLoading,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Build inspiration request section.
          Text(
            'Build your inspiration request',
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Tune the weather, ingredients and preferences before generating ideas.',
            style: context.text.bodyMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: AppSpacing.md),

          // Weather input card.
          _WeatherInputCard(
            weather: weather,
            isLoading: viewModel.isWeatherLoading,
            errorMessage: viewModel.weatherErrorMessage,
            selectedCategoryId: viewModel.selectedWeatherCategoryId,
            onChanged: viewModel.selectWeatherCategory,
          ),
          const SizedBox(height: AppSpacing.md),

          // Ingredient input card.
          _IngredientInputCard(viewModel: viewModel),
          const SizedBox(height: AppSpacing.md),

          // Preference input card.
          _PreferenceInputCard(
            preferences: preferences,
            onExpand: () => _showPreferenceEditor(context, viewModel),
          ),
          const SizedBox(height: AppSpacing.md),

          // Generate button.
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                _openAiGeneration(
                  context,
                  viewModel: viewModel,
                  preferences: preferences,
                  weather: weather,
                  preset: _QuickInspirationPreset.defaultRequest(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Get AI Recipe Ideas',
                style: context.text.labelLarge?.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick inspiration section.
          Text(
            'Quick Inspiration',
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _QuickInspirationGrid(
            items: _quickInspirationItems,
            onSelected: (item) {
              _openAiGeneration(
                context,
                viewModel: viewModel,
                preferences: preferences,
                weather: weather,
                preset: _QuickInspirationPreset.fromTitle(item.title),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Opens AI generation with the selected inspiration preset.
  void _openAiGeneration(
    BuildContext context, {
    required MealPlanViewModel viewModel,
    required MealPlanPreferenceSummary preferences,
    required MealPlanWeather? weather,
    required _QuickInspirationPreset preset,
  }) {
    /*
     * Quick inspiration cards use the same request route as the main button.
     * Weather, preferences, ingredients, calorie budget, and alternatives stay aligned.
     */
    final calorieBudget = _calorieBudgetFor(dashboard, viewModel.preferences);
    final selectedIngredients = viewModel.selectedIngredients
        .map((item) => item.name)
        .toList();
    final existingMealNames = dashboard.sections
        .where(
          (section) =>
              section.mealType.toLowerCase() == preset.mealType.toLowerCase(),
        )
        .expand((section) => section.meals)
        .map((meal) => meal.title.trim())
        .where((title) => title.isNotEmpty)
        .toList();
    final weatherSnapshot = weather;
    final request = AddMealAiGenerationRequest(
      planningDate: dashboard.selectedDate,
      mealType: preset.mealType,
      weather: AddMealWeather(
        temperature: weatherSnapshot?.currentTemp ?? 28,
        condition:
            weatherSnapshot?.condition ??
            viewModel.selectedWeatherCategory.label,
        summary:
            weatherSnapshot?.summary ?? 'Use the selected weather category.',
      ),
      preferences: AddMealPreferenceSnapshot(
        diet: preferences.diet,
        allergies: preferences.allergies,
        dislikes: preferences.dislikes,
      ),
      ingredientsToInclude: selectedIngredients,
      ingredientsToAvoid: preferences.dislikes,
      dishIncludes: preset.dishIncludes,
      dishAvoids: const [],
      cookingTime: preset.cookingTime,
      difficultyLevel: preset.difficultyLevel,
      difficulty: preset.difficulty,
      servingCount: 1,
      servingSize: '1 serving',
      calorieBudget: calorieBudget,
      existingMealNames: existingMealNames,
    );

    // Route to AI page with auto-generation enabled.
    context.push(
      AppRouter.generateAiMeal,
      extra: GenerateAiMealArgs(
        userId: viewModel.userId,
        mealType: request.mealType,
        initialRequest: request,
        autoGenerate: true,
        calorieBudget: calorieBudget,
        existingMealNames: existingMealNames,
      ),
    );
  }

  /// Shows the preference editor bottom sheet.
  void _showPreferenceEditor(
    BuildContext context,
    MealPlanViewModel viewModel,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: viewModel,
        child: const _PreferenceEditorSheet(),
      ),
    );
  }

  /// Builds the calorie budget for the selected dashboard date.
  MealCalorieBudget _calorieBudgetFor(
    MealPlanDashboard dashboard,
    MealPlanPreferenceSummary? preferences,
  ) {
    /*
     * Inspiration generation uses the same selected-date budget as planning.
     * Dashboard sections already represent the currently selected day.
     */
    final plannedCalories = dashboard.sections.fold<int>(0, (
      sectionTotal,
      section,
    ) {
      return sectionTotal +
          section.meals.fold<int>(
            0,
            (mealTotal, meal) => mealTotal + meal.calories,
          );
    });

    return MealCalorieBudget(
      plannedCalories: plannedCalories,
      targetCalories: preferences?.targetCalories,
      calorieUnit: preferences?.calorieUnit ?? 'kcal',
      targetEnabled: preferences?.calorieTargetEnabled ?? false,
    );
  }
}

/// Quick inspiration preset values.
class _QuickInspirationPreset {
  /// Meal type sent to the AI generation flow.
  final String mealType;

  /// Dish include hints sent to the AI prompt.
  final List<String> dishIncludes;

  /// Cooking time target in minutes.
  final int cookingTime;

  /// Difficulty level value.
  final int difficultyLevel;

  /// Difficulty label.
  final String difficulty;

  /// Creates a new quick inspiration preset.
  const _QuickInspirationPreset({
    required this.mealType,
    required this.dishIncludes,
    required this.cookingTime,
    required this.difficultyLevel,
    required this.difficulty,
  });

  /// Default request values used by the main generate button.
  factory _QuickInspirationPreset.defaultRequest() {
    return const _QuickInspirationPreset(
      mealType: 'Breakfast',
      dishIncludes: [],
      cookingTime: 30,
      difficultyLevel: 1,
      difficulty: 'Any',
    );
  }

  /// Preset values based on quick inspiration title.
  factory _QuickInspirationPreset.fromTitle(String title) {
    switch (title) {
      case 'What can I cook with what I have?':
        return const _QuickInspirationPreset(
          mealType: 'Breakfast',
          dishIncludes: ['prioritize available ingredients'],
          cookingTime: 30,
          difficultyLevel: 1,
          difficulty: 'Any',
        );
      case 'Surprise me!':
        return const _QuickInspirationPreset(
          mealType: 'Breakfast',
          dishIncludes: ['creative surprise meal'],
          cookingTime: 30,
          difficultyLevel: 1,
          difficulty: 'Any',
        );
      case 'Healthy Ideas':
        return const _QuickInspirationPreset(
          mealType: 'Breakfast',
          dishIncludes: ['healthy balanced meal'],
          cookingTime: 35,
          difficultyLevel: 1,
          difficulty: 'Any',
        );
      case 'Quick & Easy':
        return const _QuickInspirationPreset(
          mealType: 'Breakfast',
          dishIncludes: ['quick and easy meal'],
          cookingTime: 15,
          difficultyLevel: 1,
          difficulty: 'Easy',
        );
      case 'Rainy Day Comfort':
        return const _QuickInspirationPreset(
          mealType: 'Breakfast',
          dishIncludes: ['warm comfort food'],
          cookingTime: 35,
          difficultyLevel: 2,
          difficulty: 'Easy',
        );
      case 'High Protein Picks':
        return const _QuickInspirationPreset(
          mealType: 'Breakfast',
          dishIncludes: ['high protein meal'],
          cookingTime: 30,
          difficultyLevel: 1,
          difficulty: 'Any',
        );
      default:
        return _QuickInspirationPreset.defaultRequest();
    }
  }
}

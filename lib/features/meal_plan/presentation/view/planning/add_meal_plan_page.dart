import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../app/routers/router_args.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/custom_app_bar.dart';
import '../../../domain/entities/meal_calorie_guidance.dart';
import '../../../domain/entities/meal_serving_amount.dart';
import '../../widgets/planning/meal_serving_dialog.dart';

/// Page for adding a meal plan with multiple entry options.
/// Displays three options: community recipes, user library, and AI generation.
class AddMealPlanPage extends StatefulWidget {
  /// Type of meal to plan (e.g., breakfast, lunch, dinner).
  final String mealType;

  /// Category ID of the meal.
  final String mealCategoryId;

  /// Date selected for the meal plan.
  final DateTime selectedDate;

  /// List of recipe IDs already planned for this category/date.
  final List<String> existingRecipeIds;

  /// List of meal names already planned for this category/date.
  final List<String> existingMealNames;

  /// ID of the user creating the meal plan.
  final String userId;

  /// Calorie budget for the selected day.
  final MealCalorieBudget calorieBudget;

  /// Creates a new add meal plan page instance.
  const AddMealPlanPage({
    super.key,
    required this.mealType,
    required this.mealCategoryId,
    required this.selectedDate,
    required this.existingRecipeIds,
    required this.existingMealNames,
    required this.userId,
    required this.calorieBudget,
  });

  @override
  State<AddMealPlanPage> createState() => _AddMealPlanPageState();
}

class _AddMealPlanPageState extends State<AddMealPlanPage> {
  double _plannedServings = 1;

  void _setPlannedServings(double value) {
    setState(() => _plannedServings = MealServingAmount.normalize(value));
  }

  Future<double?> _choosePlannedServings() async {
    final selected = await showDialog<double>(
      context: context,
      builder: (_) => MealServingDialog(initialValue: _plannedServings),
    );
    if (selected == null || !mounted) return null;
    _setPlannedServings(selected);
    return MealServingAmount.normalize(selected);
  }

  Future<void> _openExploreRecipes() async {
    final plannedServings = await _choosePlannedServings();
    if (plannedServings == null || !mounted) return;

    final result = await context.push(
      AppRouter.explore,
      extra: MealPlanSelectionArgs(
        userId: widget.userId,
        selectedDate: widget.selectedDate,
        mealCategoryId: widget.mealCategoryId,
        mealCategoryName: widget.mealType,
        source: 'method1_explore_community_recipes',
        existingRecipeIds: widget.existingRecipeIds,
        calorieBudget: widget.calorieBudget,
        plannedServings: plannedServings,
      ),
    );
    if (result == true && mounted) context.pop(true);
  }

  Future<void> _openLibraryRecipes() async {
    final plannedServings = await _choosePlannedServings();
    if (plannedServings == null || !mounted) return;

    final result = await context.push(
      AppRouter.library,
      extra: LibraryArgs(
        mealPlanSelection: MealPlanSelectionArgs(
          userId: widget.userId,
          selectedDate: widget.selectedDate,
          mealCategoryId: widget.mealCategoryId,
          mealCategoryName: widget.mealType,
          source: 'method2_add_from_your_library',
          existingRecipeIds: widget.existingRecipeIds,
          calorieBudget: widget.calorieBudget,
          plannedServings: plannedServings,
        ),
      ),
    );
    if (result == true && mounted) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Add Meal Plan',
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Page header text.
            Text(
              'How would you like to add your meal plan?',
              style: context.text.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Calorie budget summary.
            _CalorieBudgetSummary(budget: widget.calorieBudget),
            const SizedBox(height: AppSpacing.lg),

            // Option 1: Community recipes.
            _AddMealOptionCard(
              title: 'Explore Community Recipes',
              imagePath: 'assets/images/meal1.png',
              description:
                  'Browse and add popular dishes shared by other Foodopia cooks to your meal plan.',
              enabled: true,
              onTap: _openExploreRecipes,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Option 2: User library.
            _AddMealOptionCard(
              title: 'Add from Your Library',
              imagePath: 'assets/images/meal2.png',
              description:
                  'Quickly schedule meals using your personal collection of saved or self-created recipes.',
              enabled: true,
              onTap: _openLibraryRecipes,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Option 3: AI generation.
            _AddMealOptionCard(
              title: 'Generate with AI',
              subtitle: 'by Foodopia AI',
              imagePath: 'assets/images/meal3.png',
              description:
                  'Tell our AI what ingredients and your preferences, and it will suggest creative recipes with weather factor.',
              enabled: true,
              onTap: () async {
                final result = await context.push(
                  AppRouter.generateAiMeal,
                  extra: GenerateAiMealArgs(
                    userId: widget.userId,
                    mealType: widget.mealType,
                    selectedDate: widget.selectedDate,
                    mealCategoryId: widget.mealCategoryId,
                    calorieBudget: widget.calorieBudget,
                    existingMealNames: widget.existingMealNames,
                  ),
                );
                if (result == true && context.mounted) context.pop(true);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Calorie budget summary for meal selection methods.
class _CalorieBudgetSummary extends StatelessWidget {
  /// Calorie budget for the selected day.
  final MealCalorieBudget budget;

  /// Creates a new calorie budget summary instance.
  const _CalorieBudgetSummary({required this.budget});

  @override
  Widget build(BuildContext context) {
    // Disabled targets show planned calories only.
    final target = budget.hasTarget ? budget.targetCalories : null;
    final unit = budget.calorieUnit;
    final planned = _displayCalories(budget.plannedCalories, unit);
    final remaining = target == null ? null : (target - planned);
    final subtitle = target == null
        ? '$planned $unit planned today'
        : remaining! >= 0
        ? '$remaining $unit left today'
        : '${remaining.abs()} $unit over target';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_fire_department_outlined,
              color: AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calorie Budget',
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  target == null
                      ? subtitle
                      : '$planned / $target $unit used - $subtitle',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Converts stored kcal into the selected display unit.
  int _displayCalories(int kcal, String unit) {
    if (unit.toLowerCase() == 'kj') return (kcal * 4.184).round();
    return kcal;
  }
}

/// Card widget for displaying a meal addition option.
/// Contains title, image, description, and tap handling.
class _AddMealOptionCard extends StatelessWidget {
  /// Main title of the option.
  final String title;

  /// Optional subtitle displayed below the title.
  final String? subtitle;

  /// Path to the option's image asset.
  final String imagePath;

  /// Description text explaining the option.
  final String description;

  /// Whether the option is enabled and tappable.
  final bool enabled;

  /// Callback function when the card is tapped.
  final VoidCallback onTap;

  /// Creates a new add meal option card instance.
  const _AddMealOptionCard({
    required this.title,
    this.subtitle,
    required this.imagePath,
    required this.description,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Only respond to taps if enabled.
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            // Title text.
            Text(
              title,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),

            // Subtitle if provided.
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Option image with grayscale filter when disabled.
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ColorFiltered(
                colorFilter: enabled
                    // No filter when enabled.
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    // Grayscale overlay when disabled.
                    : ColorFilter.mode(
                        Colors.white.withValues(alpha: 0.45),
                        BlendMode.srcATop,
                      ),
                child: Image.asset(
                  imagePath,
                  width: 96,
                  height: 82,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Description text.
            Text(
              description,
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

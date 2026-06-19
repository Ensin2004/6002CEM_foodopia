import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../../../core/widgets/recipe/planned_ai_recipe_sheet.dart';
import '../../domain/entities/user_home_dashboard.dart';

/// List of meal sections for the user home page.
/// Displays meals grouped by meal type with cards.
class UserMealPlanList extends StatelessWidget {
  /// List of meal sections to display.
  final List<UserHomeMealSection> sections;

  /// Daily calorie target.
  final int? targetCalories;

  /// Calorie unit label.
  final String calorieUnit;

  /// Creates a new user meal plan list instance.
  const UserMealPlanList({
    super.key,
    required this.sections,
    this.targetCalories,
    this.calorieUnit = 'kcal',
  });

  @override
  Widget build(BuildContext context) {
    // Show empty state if no sections.
    if (sections.isEmpty) {
      return Column(
        children: [
          Image.asset('assets/images/empty_page.png', height: 120),
          const SizedBox(height: AppSpacing.sm),
          Text('No meals planned yet', style: context.text.bodyMedium),
        ],
      );
    }

    final plannedCalories = sections.fold<int>(0, (sectionTotal, section) {
      return sectionTotal +
          section.meals.fold<int>(
            0,
            (mealTotal, meal) => mealTotal + meal.calories,
          );
    });

    // Build calorie summary and sections with meal type tiles and meal cards.
    return Column(
      children: [
        _CalorieTargetCard(
          plannedCalories: plannedCalories,
          targetCalories: targetCalories,
          calorieUnit: calorieUnit,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...sections.map((section) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal type tile.
                _MealTypeTile(section: section),
                const SizedBox(width: AppSpacing.sm),

                // Meal cards column.
                Expanded(
                  child: Column(
                    children: section.meals
                        .map(
                          (meal) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _MealCard(meal: meal),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Daily calorie target summary for the home meal plan.
class _CalorieTargetCard extends StatelessWidget {
  /// Planned calories from today's meals.
  final int plannedCalories;

  /// Daily target calories.
  final int? targetCalories;

  /// Calorie unit label.
  final String calorieUnit;

  /// Creates a calorie target summary card.
  const _CalorieTargetCard({
    required this.plannedCalories,
    required this.targetCalories,
    required this.calorieUnit,
  });

  @override
  Widget build(BuildContext context) {
    final target = targetCalories;
    final hasTarget = target != null && target > 0;
    final progress = hasTarget
        ? (plannedCalories / target).clamp(0.0, 1.0)
        : 0.0;
    final label = hasTarget
        ? '$plannedCalories / $target $calorieUnit'
        : '$plannedCalories $calorieUnit planned';
    final status = _HomeCalorieStatus.from(
      plannedCalories: plannedCalories,
      targetCalories: target,
      unit: calorieUnit,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_fire_department_outlined,
                  size: 21,
                  color: status.color,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Calories',
                      style: context.text.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    label,
                    style: context.text.labelMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _HomeCalorieStatusChip(status: status),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: hasTarget ? progress : 0,
              minHeight: 8,
              backgroundColor: AppColors.border.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(status.color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status chip for home daily calories.
class _HomeCalorieStatusChip extends StatelessWidget {
  /// Status data.
  final _HomeCalorieStatus status;

  /// Creates a status chip.
  const _HomeCalorieStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.16)),
      ),
      child: Text(
        status.label,
        style: context.text.labelSmall?.copyWith(
          color: status.color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Presentation status for home calorie summary.
class _HomeCalorieStatus {
  /// Short label.
  final String label;

  /// Helpful message.
  final String message;

  /// Status color.
  final Color color;

  /// Creates a home calorie status.
  const _HomeCalorieStatus({
    required this.label,
    required this.message,
    required this.color,
  });

  factory _HomeCalorieStatus.from({
    required int plannedCalories,
    required int? targetCalories,
    required String unit,
  }) {
    final target = targetCalories;
    if (target == null || target <= 0) {
      return _HomeCalorieStatus(
        label: 'Set target',
        message: '$plannedCalories $unit planned today.',
        color: AppColors.textSecondary,
      );
    }

    if (plannedCalories > target) {
      final over = plannedCalories - target;
      return _HomeCalorieStatus(
        label: '+$over $unit',
        message: 'Over target. Choose lighter meals next.',
        color: AppColors.error,
      );
    }

    final remaining = target - plannedCalories;
    final ratio = plannedCalories / target;
    if (ratio >= 0.85) {
      return _HomeCalorieStatus(
        label: '$remaining left',
        message: 'Close to target. Keep the rest light.',
        color: AppColors.secondary,
      );
    }

    return _HomeCalorieStatus(
      label: '$remaining left',
      message: 'On track. You still have room today.',
      color: AppColors.primary,
    );
  }
}

/// Meal type tile widget.
/// Displays the meal category icon, name, and count.
class _MealTypeTile extends StatelessWidget {
  /// The meal section data.
  final UserHomeMealSection section;

  /// Creates a new meal type tile instance.
  const _MealTypeTile({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: section.accentColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Meal type icon.
          Icon(section.icon, color: context.colors.primary, size: 22),
          const SizedBox(height: AppSpacing.xs),

          // Meal type name.
          Text(
            section.mealType,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Meal count label.
          Text(
            section.countLabel,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall?.copyWith(
              color: Colors.grey.shade700,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Meal card widget.
/// Displays a single meal with image, title, subtitle, and duration.
class _MealCard extends StatelessWidget {
  /// The meal data.
  final UserHomeMeal meal;

  /// Creates a new meal card instance.
  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openRecipe(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Meal image.
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: AppRemoteOrAssetImage(
                  imagePath: meal.imagePath,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Meal details.
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title.
                    Text(
                      meal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Meal metadata.
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _MealInfoChip(
                          icon: Icons.people_alt_outlined,
                          label: meal.subtitle,
                          color: context.colors.primary,
                        ),
                        _MealInfoChip(
                          icon: Icons.schedule_outlined,
                          label: meal.duration,
                          color: AppColors.textSecondary,
                        ),
                        if (meal.calories > 0)
                          _MealInfoChip(
                            icon: Icons.local_fire_department_outlined,
                            label: '${meal.calories} kcal',
                            color: AppColors.secondary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chevron icon.
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the planned meal's recipe detail page.
  void _openRecipe(BuildContext context) {
    final aiPreview = PlannedAiRecipePreview(
      title: meal.title,
      description: meal.aiDescription,
      durationLabel: meal.duration,
      servingLabel: meal.subtitle,
      imagePath: meal.imagePath,
      ingredients: meal.aiIngredients,
      instructions: meal.aiInstructions,
    );
    if (aiPreview.hasDetails) {
      showPlannedAiRecipeSheet(context, aiPreview);
      return;
    }

    final recipeId = meal.recipeId.trim();
    if (recipeId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Recipe details are unavailable.')),
        );
      return;
    }

    context.push(
      AppRouter.exploreRecipeDetail,
      extra: ExploreRecipeDetailArgs(recipeId: recipeId),
    );
  }
}

/// Compact chip for home meal metadata.
class _MealInfoChip extends StatelessWidget {
  /// Chip icon.
  final IconData icon;

  /// Chip label.
  final String label;

  /// Accent color.
  final Color color;

  /// Creates a meal info chip.
  const _MealInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 88),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

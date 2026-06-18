import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../app/routers/router_args.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../../core/widgets/media/app_recipe_media.dart';
import '../../../domain/entities/meal_plan_dashboard.dart';
import '../../viewmodel/meal_plan_viewmodel.dart';

/// Card widget for a meal plan section.
/// Displays meals in a category with add and remove functionality.
class MealPlanSectionCard extends StatelessWidget {
  /// The meal plan section to display.
  final MealPlanSection section;

  /// Creates a new meal plan section card instance.
  const MealPlanSectionCard({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    // Determine meal label.
    final mealLabel = section.meals.length == 1
        ? '1 meal'
        : '${section.meals.length} meals';

    // Calculate remaining slots (max 5 per category per date).
    final remainingCount = (5 - section.meals.length).clamp(0, 5);

    // Extract existing recipe IDs for duplicate prevention.
    final existingRecipeIds = section.meals
        .map((meal) => meal.recipeId)
        .where((id) => id.trim().isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        shape: const Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
        collapsedShape: const Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        title: Text(section.mealType, style: context.text.titleMedium),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mealLabel,
              style: context.text.labelLarge?.copyWith(
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.keyboard_arrow_down, size: 20),
          ],
        ),
        children: [
          // List of meals.
          ...section.meals.map((meal) => _MealRow(meal: meal)),
          const SizedBox(height: AppSpacing.sm),

          // Slot status indicator.
          _MealLimitStatus(
            remainingCount: remainingCount,
            mealType: section.mealType,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Add meal button.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: remainingCount <= 0
                  ? null
                  : () {
                // Get required data from view model.
                final userId = context.read<MealPlanViewModel>().userId;
                final selectedDate = context
                    .read<MealPlanViewModel>()
                    .dashboard
                    ?.selectedDate;

                // Navigate to add meal plan.
                context.push(
                  AppRouter.addMealPlan,
                  extra: AddMealPlanArgs(
                    userId: userId,
                    mealType: section.mealType,
                    mealCategoryId: section.mealCategoryId,
                    selectedDate: selectedDate,
                    existingRecipeIds: existingRecipeIds,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: remainingCount <= 0
                    ? AppColors.background
                    : Colors.white,
                side: BorderSide(
                  color: remainingCount <= 0
                      ? AppColors.border.withValues(alpha: 0.72)
                      : AppColors.border,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                remainingCount <= 0
                    ? '${section.mealType} limit reached'
                    : '+ Add ${section.mealType} Meal',
                style: context.text.bodySmall?.copyWith(
                  color: remainingCount <= 0
                      ? AppColors.textSecondary
                      : AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Meal limit status indicator widget.
class _MealLimitStatus extends StatelessWidget {
  /// Number of remaining slots.
  final int remainingCount;

  /// Meal type label.
  final String mealType;

  /// Creates a new meal limit status instance.
  const _MealLimitStatus({
    required this.remainingCount,
    required this.mealType,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the section is full.
    final isFull = remainingCount <= 0;

    // Determine color.
    final color = isFull ? AppColors.textSecondary : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isFull ? 0.08 : 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            isFull ? Icons.lock_outline : Icons.restaurant_menu,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              isFull
                  ? '$mealType is full for this date'
                  : '$remainingCount of 5 slots available',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Meal row widget.
class _MealRow extends StatelessWidget {
  /// The meal to display.
  final MealPlanMeal meal;

  /// Creates a new meal row instance.
  const _MealRow({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Meal image.
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: AppRecipeMediaPreview(
                mediaPath: meal.imagePath,
                fit: BoxFit.cover,
                playOverlaySize: 30,
                playIconSize: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Meal details.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${meal.servingLabel} • ${meal.durationLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Delete button.
          IconButton(
            tooltip: 'Remove meal',
            visualDensity: VisualDensity.compact,
            onPressed: () => _confirmRemoveMeal(context, meal),
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog before removing a meal.
  Future<void> _confirmRemoveMeal(
      BuildContext context,
      MealPlanMeal meal,
      ) async {
    // Show confirmation dialog.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove meal?', style: context.text.titleMedium),
        content: Text(
          'Remove ${meal.title} from this meal plan?',
          style: context.text.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    // Return if not confirmed or context is gone.
    if (confirmed != true || !context.mounted) return;

    // Show loading dialog.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingDialog(message: 'Removing meal...'),
    );

    // Execute deletion.
    final viewModel = context.read<MealPlanViewModel>();
    final removed = await viewModel.deleteMealPlan(meal.id);

    // Dismiss loading dialog.
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    // Show result message.
    final message = removed
        ? 'Meal removed from plan.'
        : viewModel.mealActionErrorMessage ?? 'Unable to remove meal.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../domain/entities/user_home_dashboard.dart';

/// List of meal sections for the user home page.
/// Displays meals grouped by meal type with cards.
class UserMealPlanList extends StatelessWidget {
  /// List of meal sections to display.
  final List<UserHomeMealSection> sections;

  /// Creates a new user meal plan list instance.
  const UserMealPlanList({super.key, required this.sections});

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

    // Build sections with meal type tiles and meal cards.
    return Column(
      children: sections.map((section) {
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
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _MealCard(meal: meal),
                    ),
                  )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
    return Container(
      height: 72,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Meal image.
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: AppRemoteOrAssetImage(
              imagePath: meal.imagePath,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Meal details.
          Expanded(
            child: Column(
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
                const SizedBox(height: AppSpacing.xs),

                // Subtitle badge.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    meal.subtitle,
                    style: context.text.labelSmall?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 2),

                // Duration.
                Text(
                  meal.duration,
                  style: context.text.labelSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Chevron icon.
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
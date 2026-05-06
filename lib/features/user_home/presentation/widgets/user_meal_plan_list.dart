import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/user_home_dashboard.dart';

class UserMealPlanList extends StatelessWidget {
  final List<UserHomeMealSection> sections;

  const UserMealPlanList({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return Column(
        children: [
          Image.asset('assets/images/empty_page.png', height: 120),
          const SizedBox(height: AppSpacing.sm),
          Text('No meals planned yet', style: context.text.bodyMedium),
        ],
      );
    }

    return Column(
      children: sections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MealTypeTile(section: section),
              const SizedBox(width: AppSpacing.sm),
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

class _MealTypeTile extends StatelessWidget {
  final UserHomeMealSection section;

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
          Icon(section.icon, color: context.colors.primary, size: 22),
          const SizedBox(height: AppSpacing.xs),
          Text(
            section.mealType,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
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

class _MealCard extends StatelessWidget {
  final UserHomeMeal meal;

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
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.asset(
              meal.imagePath,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  meal.duration,
                  style: context.text.labelSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}

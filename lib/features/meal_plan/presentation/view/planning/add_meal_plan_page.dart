import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/routers/app_router.dart';
import '../../../../../app/routers/router_args.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/custom_app_bar.dart';

class AddMealPlanPage extends StatelessWidget {
  final String mealType;
  final String userId;

  const AddMealPlanPage({
    super.key,
    required this.mealType,
    required this.userId,
  });

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
            Text(
              'How would you like to add your meal plan?',
              style: context.text.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _AddMealOptionCard(
              title: 'Explore Community Recipes',
              imagePath: 'assets/images/meal1.png',
              description:
                  'Browse and add popular dishes shared by other Foodopia cooks to your meal plan.',
              enabled: false,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.lg),
            _AddMealOptionCard(
              title: 'Add from Your Library',
              imagePath: 'assets/images/meal2.png',
              description:
                  'Quickly schedule meals using your personal collection of saved or self-created recipes.',
              enabled: false,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.lg),
            _AddMealOptionCard(
              title: 'Generate with AI',
              subtitle: 'by Foodopia AI',
              imagePath: 'assets/images/meal3.png',
              description:
                  'Tell our AI what ingredients and your preferences, and it will suggest creative recipes with weather factor.',
              enabled: true,
              onTap: () => context.push(
                AppRouter.generateAiMeal,
                extra: GenerateAiMealArgs(userId: userId, mealType: mealType),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMealOptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String imagePath;
  final String description;
  final bool enabled;
  final VoidCallback onTap;

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
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ColorFiltered(
                colorFilter: enabled
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
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

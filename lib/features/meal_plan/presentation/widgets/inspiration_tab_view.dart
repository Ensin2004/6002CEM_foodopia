import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/meal_plan_dashboard.dart';

class InspirationTabView extends StatelessWidget {
  final List<MealPlanInspiration> items;

  const InspirationTabView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Image.asset('assets/images/empty_page.png', height: 140),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
                child: Image.asset(
                  item.imagePath,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: context.text.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(item.subtitle, style: context.text.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

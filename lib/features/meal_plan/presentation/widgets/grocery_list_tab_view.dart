import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/meal_plan_dashboard.dart';

class GroceryListTabView extends StatelessWidget {
  final List<GroceryListGroup> groups;

  const GroceryListTabView({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Center(
        child: Image.asset('assets/images/empty_page.png', height: 140),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final group = groups[index];
        return Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.title, style: context.text.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              ...group.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_box_outline_blank,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(item, style: context.text.bodyMedium),
                      ),
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

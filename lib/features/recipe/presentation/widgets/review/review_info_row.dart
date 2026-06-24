import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';

/// Displays one labeled value row in the review page.
class ReviewInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final int? difficultyLevel;

  const ReviewInfoRow({
    super.key,
    required this.label,
    this.value = "",
    this.difficultyLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Value (Text or Difficulty Icon)
          if (difficultyLevel == null) ...[
            // Text
            Text(
              value,
              style: context.text.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (difficultyLevel != null) ...[
            // Difficulty Icon
            Row(
              children: List.generate(5, (index) {
                // Determine if this icon should be selected
                final selected = index < difficultyLevel!;

                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Icon(
                    Icons.restaurant_menu_rounded,
                    size: 24,
                    color: selected
                        ? AppColors.secondary
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

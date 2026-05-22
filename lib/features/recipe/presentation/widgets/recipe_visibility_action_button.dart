import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';

class RecipeVisibilityActionButton extends StatelessWidget {
  final String visibility;
  final bool isSaving;
  final ValueChanged<String> onChanged;

  const RecipeVisibilityActionButton({
    super.key,
    required this.visibility,
    required this.isSaving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isPublic = visibility == "public";

    return Padding(
      padding: EdgeInsets.only(right: AppSpacing.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isSaving ? null : () => onChanged(isPublic ? "private" : "public"),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isPublic ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPublic ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                size: 14,
                color: isPublic ? AppColors.primary : AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                isPublic ? "Public" : "Private",
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPublic ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

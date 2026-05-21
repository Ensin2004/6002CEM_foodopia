import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../viewmodel/add_recipe_basic_info_viewmodel.dart';

class RecipeDifficultyPicker extends StatelessWidget {
  final List<String> levels;

  const RecipeDifficultyPicker({super.key, required this.levels});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddRecipeBasicInfoViewModel>();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: levels.asMap().entries.map((entry) {
          final levelValue = entry.key + 1;
          final levelLabel = entry.value;
          final selected = levelValue <= viewModel.difficultyLevel;
          return Expanded(
            child: InkWell(
              onTap: () => context
                  .read<AddRecipeBasicInfoViewModel>()
                  .selectDifficulty(levelValue),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant_menu_rounded,
                    size: 24,
                    color: selected
                        ? AppColors.secondary
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      levelLabel,
                      maxLines: 1,
                      style: context.text.bodySmall?.copyWith(
                        fontSize: 9,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

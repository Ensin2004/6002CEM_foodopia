import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../../domain/entities/add_recipe_review.dart';

/// Displays one ingredient row in the review page.
class ReviewIngredientItem extends StatelessWidget {
  final AddRecipeReviewIngredient ingredient;

  const ReviewIngredientItem({super.key, required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final calories = _caloriesLabel(ingredient.nutrients);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Ingredient Image
          InkWell(
            onTap: () => _showExpandedImage(context, ingredient.image),
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AppRemoteOrAssetImage(
                imagePath: ingredient.image,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Ingredient Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ingredient Name
                Text(
                  ingredient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // Amount and Unit
                Text(
                  "${ingredient.amount} ${ingredient.unit}".trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // Calorie Information
                Text(
                  calories,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the ingredient image in a fullscreen dialog with zoom capabilities.
  Future<void> _showExpandedImage(
    BuildContext context,
    String imagePath,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                // Fullscreen Image
                Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: AppRemoteOrAssetImage(
                      imagePath: imagePath,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Top-right corner - close button
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Formats the calories from nutrient data into a display string.
  String _caloriesLabel(Map<String, dynamic>? nutrients) {
    final calories = _numericValue(nutrients?['calories']);
    if (calories == null) return 'Calories: -';
    return 'Calories: ${_formatNumber(calories)} kcal';
  }

  /// Extracts a numeric value from various data types.
  double? _numericValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is Map) return _numericValue(value['value'] ?? value['amount']);
    return double.tryParse(value?.toString() ?? '');
  }

  /// Formats a number for display with appropriate precision.
  String _formatNumber(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.05) return rounded.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

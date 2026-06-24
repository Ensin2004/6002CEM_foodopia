import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../../domain/entities/add_recipe_review.dart';

/// Displays one instruction row in the review page.
class ReviewInstructionItem extends StatelessWidget {
  final AddRecipeReviewInstruction instruction;
  final bool useSection;

  const ReviewInstructionItem({
    super.key,
    required this.instruction,
    required this.useSection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: useSection
          ? const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md)
          : const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: useSection ? null : const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruction Image
          InkWell(
            onTap: () => _showExpandedImage(context, instruction.image),
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AppRemoteOrAssetImage(
                imagePath: instruction.image,
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Instruction Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Number
                Text(
                  "Step ${instruction.stepIndex}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // Instruction Description
                Text(
                  instruction.description,
                  style: context.text.bodyMedium?.copyWith(
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

  /// Shows the instruction image in a fullscreen dialog with zoom capabilities.
  Future<void> _showExpandedImage(BuildContext context, String imagePath) async {
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
}

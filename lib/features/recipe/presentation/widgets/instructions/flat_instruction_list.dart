import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../view/add_recipe_instructions_page.dart';
import 'input_step_field.dart';

/// Reorderable list for recipe's instruction that use step-by-step method.
class FlatInstructionList extends StatelessWidget {
  final List<InstructionStepState> steps;
  final double horizontalPadding;
  final void Function(InstructionStepState step) onPickImage;
  final void Function() onAddStep;
  final void Function(int index) onRemoveStep;
  final void Function(int oldIndex, int newIndex) onReorderStep;

  const FlatInstructionList({
    super.key,
    required this.steps,
    required this.horizontalPadding,
    required this.onPickImage,
    required this.onAddStep,
    required this.onRemoveStep,
    required this.onReorderStep,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          0,
      ),
      children: [
        // Reorderable list of steps
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: steps.length,
          onReorder: onReorderStep,
          itemBuilder: (context, index) {
            final step = steps[index];
            return Padding(
              key: ValueKey(step.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _InstructionStepCard(
                index: index,
                title: "Step ${index + 1}",
                step: step,
                onPickImage: () => onPickImage(step),
                onDelete: () => onRemoveStep(index),
              ),
            );
          },
        ),

        // Add Step Button
        SecondaryButton(
          text: "+  Add Step",
          onPressed: onAddStep,
        ),
      ],
    );
  }
}

/// Card for one flat instruction step with reorder and delete actions.
class _InstructionStepCard extends StatelessWidget {
  final int index;
  final String title;
  final InstructionStepState step;
  final VoidCallback onPickImage;
  final VoidCallback onDelete;

  const _InstructionStepCard({
    required this.index,
    required this.title,
    required this.step,
    required this.onPickImage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),

            // Header Row
            Row(
              children: [
                // Drag handle for reordering
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(
                    Icons.drag_indicator,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Step Title
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Delete Button
                InkWell(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.sm),

            // Step Content
            InputStepField(
              index: index,
              step: step,
              showNumberBadge: false,
              onPickImage: onPickImage,
              onDelete: onDelete,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

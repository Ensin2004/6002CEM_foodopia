import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/buttons/secondary_button.dart';
import '../view/add_recipe_instructions_page.dart';
import 'input_step_field.dart';

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
    return ReorderableListView.builder(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        0,
      ),
      buildDefaultDragHandles: false,
      itemCount: steps.length + 1,
      onReorder: onReorderStep,
      itemBuilder: (context, index) {
        if(index == steps.length) {
          return Padding(
            key: const ValueKey("add_step_button"),
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: SecondaryButton(
              text: "+  Add Step",
              onPressed: onAddStep,
            ),
          );
        }
        final step = steps[index];
        return Padding(
          key: ValueKey(step.id),
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _InstructionStepCard(
            index: index,
            title: "Step ${index + 1}",
            step: step,
            onPickImage: () => onPickImage(step),
            onDelete: () => onRemoveStep(index),
          ),
        );
      },
    );
  }
}

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
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(
                    Icons.drag_indicator,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
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
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                ),
              ],
            ),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppSpacing.lg),
            InputStepField(
              index: index,
              step: step,
              showNumberBadge: false,
              onPickImage: onPickImage,
              onDelete: onDelete,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
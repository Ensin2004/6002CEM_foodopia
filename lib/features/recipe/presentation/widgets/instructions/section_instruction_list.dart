import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/buttons/secondary_button.dart';
import '../../view/add_recipe_instructions_page.dart';
import 'input_step_field.dart';

/// Reorderable list for recipe's instruction that use section method.
class SectionInstructionList extends StatelessWidget {
  final List<InstructionSectionState> sections;
  final double horizontalPadding;
  final void Function(InstructionStepState step) onPickImage;
  final void Function(InstructionSectionState section) onAddStep;
  final void Function(InstructionSectionState section, int index) onRemoveStep;
  final void Function() onAddSection;
  final void Function(int sectionIndex) onRemoveSection;
  final void Function(
    InstructionSectionState section,
    int oldIndex,
    int newIndex,
  )
  onReorderStep;
  final void Function(int oldIndex, int newIndex) onReorderSection;

  const SectionInstructionList({
    super.key,
    required this.sections,
    required this.horizontalPadding,
    required this.onPickImage,
    required this.onAddStep,
    required this.onRemoveStep,
    required this.onAddSection,
    required this.onRemoveSection,
    required this.onReorderStep,
    required this.onReorderSection,
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
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: sections.length,
          onReorder: onReorderSection,
          itemBuilder: (context, sectionIndex) {
            final section = sections[sectionIndex];
            return Padding(
              key: ValueKey(section.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _InstructionSectionCard(
                sectionIndex: sectionIndex,
                section: section,
                onPickImage: onPickImage,
                onAddStep: () => onAddStep(section),
                onRemoveStep: (stepIndex) => onRemoveStep(section, stepIndex),
                onRemoveSection: () => onRemoveSection(sectionIndex),
                onReorderStep: (oldIndex, newIndex) =>
                    onReorderStep(section, oldIndex, newIndex),
              ),
            );
          },
        ),
        SecondaryButton(
          text: "+  Add Section",
          onPressed: onAddSection,
        ),
      ],
    );
  }
}

/// Card for one section instruction with title input, nested steps, reorder controls and delete actions.
class _InstructionSectionCard extends StatelessWidget {
  final int sectionIndex;
  final InstructionSectionState section;
  final void Function(InstructionStepState step) onPickImage;
  final VoidCallback onAddStep;
  final void Function(int index) onRemoveStep;
  final VoidCallback onRemoveSection;
  final void Function(int oldIndex, int newIndex) onReorderStep;

  const _InstructionSectionCard({
    required this.sectionIndex,
    required this.section,
    required this.onPickImage,
    required this.onAddStep,
    required this.onRemoveStep,
    required this.onRemoveSection,
    required this.onReorderStep,
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
            Row(
              children: [
                ReorderableDragStartListener(
                  index: sectionIndex,
                  child: const Icon(
                    Icons.drag_indicator,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: section.titleController,
                    decoration: const InputDecoration(
                      hintText: "Section Header (e.g. Prepare the Pasta)",
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                InkWell(
                  onTap: onRemoveSection,
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
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: section.steps.length,
              onReorder: onReorderStep,
              itemBuilder: (context, stepIndex) {
                final step = section.steps[stepIndex];
                return Padding(
                  key: ValueKey(step.id),
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: InputStepField(
                    index: stepIndex,
                    step: step,
                    showNumberBadge: true,
                    onPickImage: () => onPickImage(step),
                    onDelete: () => onRemoveStep(stepIndex),
                  ),
                );
              },
            ),
            const Divider(color: AppColors.border),
            TextButton(
              onPressed: onAddStep,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text("+  Add Step"),
            ),
          ],
        ),
      ),
    );
  }
}

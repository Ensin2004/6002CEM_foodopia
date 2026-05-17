import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../view/add_recipe_instructions_page.dart';

class InputStepField extends StatelessWidget {
  final int index;
  final InstructionStepState step;
  final bool showNumberBadge;
  final VoidCallback onPickImage;
  final VoidCallback onDelete;

  const InputStepField({
    super.key,
    required this.index,
    required this.step,
    required this.showNumberBadge,
    required this.onPickImage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (showNumberBadge) ...[
              ReorderableDragStartListener(
                index: index,
                child: const Icon(
                  Icons.drag_indicator,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.primary,
                child: Text(
                  "${index + 1}",
                  style: context.text.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            _InstructionImageBox(imageFile: step.imageFile, onTap: onPickImage),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: step.descriptionController,
                minLines: 2,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: "Describe each step clearly (e.g. Boil water to 80°C)",
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            if (showNumberBadge) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _InstructionImageBox extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onTap;

  const _InstructionImageBox({required this.imageFile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 58,
          height: 58,
          color: const Color(0xFFF7F7F7),
          child: imageFile == null
              ? const Icon(
            Icons.add_photo_alternate_outlined,
            color: Color(0xFFC9CBCD),
            size: 30,
          )
              : Image.file(imageFile!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
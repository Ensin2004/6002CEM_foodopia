import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/widgets/images/app_remote_or_asset_image.dart';
import '../../view/add_recipe_instructions_page.dart';

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
              const SizedBox(width: AppSpacing.sm),
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
            _InstructionImageBox(
              imageFile: step.imageFile,
              imageUrl: step.existingImageUrl,
              onTap: onPickImage,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: 58,
                child: TextField(
                  controller: step.descriptionController,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.center,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hint: Text(
                      "Describe each step clearly (e.g. Boil water to 80°C)",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium?.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
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
            ),
            if (showNumberBadge) ...[
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
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
  final String? imageUrl;
  final VoidCallback onTap;

  const _InstructionImageBox({
    required this.imageFile,
    required this.imageUrl,
    required this.onTap,
  });

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
              ? imageUrl == null
                    ? const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Color(0xFFC9CBCD),
                        size: 30,
                      )
                    : AppRemoteOrAssetImage(imagePath: imageUrl!, fit: BoxFit.cover)
              : Image.file(imageFile!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

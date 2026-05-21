import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../view/add_recipe_ingredients_page.dart';

class InputIngredientField extends StatelessWidget {
  final int index;
  final IngredientRowState row;
  final VoidCallback onPickImage;
  final VoidCallback onSelectName;
  final VoidCallback onSelectUnit;
  final VoidCallback onDelete;

  const InputIngredientField({
    super.key,
    required this.index,
    required this.row,
    required this.onPickImage,
    required this.onSelectName,
    required this.onSelectUnit,
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
        child: Row(
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
            _IngredientImageBox(imageFile: row.imageFile, onTap: onPickImage),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                children: [
                  InkWell(
                    onTap: onSelectName,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        hintText: "Ingredient Name",
                        isDense: true,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.nameController.text.trim().isEmpty
                                  ? "Ingredient Name"
                                  : row.nameController.text.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodyMedium?.copyWith(
                                color: row.nameController.text.trim().isEmpty
                                    ? AppColors.textSecondary.withValues(
                                        alpha: 0.5,
                                      )
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: row.amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: "Amount",
                            isDense: true,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: InkWell(
                          onTap: onSelectUnit,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              hintText: "Unit",
                              isDense: true,
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    row.unitDisplayName.isEmpty
                                        ? "Unit"
                                        : row.unitDisplayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.bodyMedium?.copyWith(
                                      color: row.unitDisplayName.isEmpty
                                          ? AppColors.textSecondary.withValues(
                                              alpha: 0.5,
                                            )
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientImageBox extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onTap;

  const _IngredientImageBox({required this.imageFile, required this.onTap});

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

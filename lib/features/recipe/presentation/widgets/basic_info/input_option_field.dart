import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../view/add_recipe_basic_info_page.dart';

/// Form field widget for displaying and managing selected categories or allergen info.
class InputOptionField extends StatelessWidget {
  final String placeholder;
  final List<SelectedRecipeOption> values;
  final ValueChanged<SelectedRecipeOption> onDelete;
  final VoidCallback onTap;

  const InputOptionField({
    super.key,
    required this.placeholder,
    required this.values,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Show placeholder when no options are selected
    if (values.isEmpty) {
      return _OptionField(
        text: placeholder,
        isPlaceholder: true,
        onTap: onTap,
      );
    }

    // Show each selected option as a separate field with delete button
    return Column(
      children: values.asMap().entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: entry.key == values.length - 1 ? 0 : AppSpacing.sm,
          ),
          child: _OptionField(
            text: entry.value.name,
            onTap: onTap,
            onDelete: () => onDelete(entry.value),
          ),
        );
      }).toList(),
    );
  }
}

/// Displays one selected category or allergen info with an optional delete button.
class _OptionField extends StatelessWidget {
  final String text;
  final bool isPlaceholder;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _OptionField({
    required this.text,
    this.isPlaceholder = false,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
        ),
        child: Row(
          children: [
            // Text content - expands to fill available space
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium?.copyWith(
                  color: isPlaceholder
                      ? AppColors.textSecondary.withValues(alpha: 0.5)
                      : AppColors.textPrimary,
                ),
              ),
            ),

            // Dropdown arrow indicates this is a selectable field
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),

            // Delete icon - only shown when a delete callback is provided
            if (onDelete != null) ...[
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
      ),
    );
  }
}

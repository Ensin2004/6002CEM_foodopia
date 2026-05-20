import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';

class InputTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? suffixText;
  final VoidCallback? onDelete;
  final int? maxLines;

  const InputTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.suffixText,
    this.onDelete,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (suffixText != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: Text(
                  suffixText!,
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
          ],
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_extension.dart';

/// Choice chip widget for user setup selection.
/// Displays a selectable chip with label and visual feedback.
class UserSetupChoiceChip extends StatelessWidget {
  /// Label text displayed on the chip.
  final String label;

  /// Whether the chip is selected.
  final bool selected;

  /// Callback when the chip is tapped.
  final VoidCallback onTap;

  /// Creates a new user setup choice chip instance.
  const UserSetupChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: context.text.labelLarge?.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
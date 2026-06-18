import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/theme_extension.dart';

/// Filter chip widget for selection and filtering.
/// Used in meal plan filters and other selection contexts.
class AppFilterChip extends StatelessWidget {
  /// Label text displayed on the chip.
  final String label;

  /// Whether the chip is selected.
  final bool selected;

  /// Callback when the chip is tapped.
  final VoidCallback onTap;

  /// Creates a new app filter chip instance.
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get the color scheme.
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? colorScheme.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: selected ? colorScheme.onPrimary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
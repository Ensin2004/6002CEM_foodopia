import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Step progress bar with a dynamic number of segments.
/// Used for multi-step forms and wizards.
class AppProgressBar extends StatelessWidget {
  /// Total number of steps.
  final int totalSteps;

  /// Current step (1-based).
  final int currentStep;

  /// Height of the progress bar.
  final double height;

  /// Creates a new app progress bar instance.
  const AppProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure at least one step.
    final safeTotal = totalSteps < 1 ? 1 : totalSteps;

    // Clamp current step to valid range.
    final safeCurrent = currentStep.clamp(1, safeTotal);

    return Row(
      children: List.generate(safeTotal, (index) {
        // Check if this segment is completed.
        final isCompleted = index < safeCurrent;

        return Expanded(
          child: Container(
            height: height,
            margin: EdgeInsets.only(right: index == safeTotal - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.secondary
                  : AppColors.border.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/theme_extension.dart';

/// Step progress bar with numbered steps and labels.
/// Used for multi-step wizards with visual step indicators.
class AppStepProgressBar extends StatelessWidget {
  /// Total number of steps.
  final int totalSteps;

  /// Current step (1-based).
  final int currentStep;

  /// Labels for each step.
  final List<String> labels;

  /// Creates a new app step progress bar instance.
  const AppStepProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure at least one step.
    final safeTotal = totalSteps < 1 ? 1 : totalSteps;

    // Clamp current step to valid range.
    final safeCurrent = currentStep.clamp(1, safeTotal);

    return Column(
      children: [
        // Step indicators and connecting lines.
        Row(
          children: List.generate(safeTotal, (index) {
            final step = index + 1;
            final isCompleted = step < safeCurrent;
            final isActive = step == safeCurrent;
            final isHighlighted = isCompleted || isActive;

            return Expanded(
              child: Row(
                children: [
                  // Left connecting line.
                  Expanded(
                    child: index == 0
                        ? const SizedBox.shrink()
                        : Container(
                      height: 4,
                      color: step <= safeCurrent
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  // Step circle.
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isHighlighted ? AppColors.primary : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isHighlighted
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : Text(
                      '$step',
                      style: context.text.labelLarge?.copyWith(
                        color: isActive
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  // Right connecting line.
                  Expanded(
                    child: index == safeTotal - 1
                        ? const SizedBox.shrink()
                        : Container(
                      height: 4,
                      color: step < safeCurrent
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // Step labels.
        Row(
          children: List.generate(safeTotal, (index) {
            final step = index + 1;
            final label = index < labels.length ? labels[index] : 'Step $step';
            final isHighlighted = step <= safeCurrent;

            return Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: isHighlighted
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
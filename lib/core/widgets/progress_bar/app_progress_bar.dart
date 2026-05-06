import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Step progress bar with a dynamic number of segments.
class AppProgressBar extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final double height;

  const AppProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = totalSteps < 1 ? 1 : totalSteps;
    final safeCurrent = currentStep.clamp(1, safeTotal);

    return Row(
      children: List.generate(safeTotal, (index) {
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

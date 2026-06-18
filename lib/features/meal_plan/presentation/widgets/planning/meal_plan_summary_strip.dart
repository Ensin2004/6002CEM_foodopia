import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../domain/entities/meal_plan_dashboard.dart';

/// Summary strip widget for the meal plan page.
/// Displays counts of past, today, and future meal plans.
class MealPlanSummaryStrip extends StatelessWidget {
  /// The meal plan summary data.
  final MealPlanSummary summary;

  /// Creates a new meal plan summary strip instance.
  const MealPlanSummaryStrip({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Past count.
          Expanded(
            child: _SummaryItem(label: 'Past', value: summary.pastCount),
          ),
          const SizedBox(width: 6),

          // Today count.
          Expanded(
            child: _SummaryItem(label: 'Today', value: summary.todayCount),
          ),
          const SizedBox(width: 6),

          // Future count.
          Expanded(
            child: _SummaryItem(label: 'Future', value: summary.futureCount),
          ),
        ],
      ),
    );
  }
}

/// Individual summary item widget.
class _SummaryItem extends StatelessWidget {
  /// Label text.
  final String label;

  /// Value count.
  final int value;

  /// Creates a new summary item instance.
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label.
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Value.
          Text(
            '$value',
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';

/// Shared back button used by every statistics detail page.
class StatisticsBackButton extends StatelessWidget {
  const StatisticsBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back),
      onPressed: () => context.pop(),
    );
  }
}

/// Common error layout with a retry action.
class StatisticsErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const StatisticsErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', height: 140),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try Again',
                style: context.text.labelLarge?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays the current date range and opens the date picker when tapped.
class StatisticsDateRangeBar extends StatelessWidget {
  final String dateRange;
  final VoidCallback onTap;

  const StatisticsDateRangeBar({
    super.key,
    required this.dateRange,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Date Range:',
          style: context.text.bodySmall?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dateRange,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_month, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> pickStatisticsDateRange({
  required BuildContext context,
  required DateTime? startDate,
  required DateTime? endDate,
  required Future<void> Function(DateTime startDate, DateTime endDate) onPicked,
}) async {
  // Use the current selection when possible, otherwise start from May 2026.
  final now = DateTime.now();
  final defaultEnd = DateTime(now.year, now.month, now.day);
  final defaultStart = DateTime(2026, 5);
  final pickedRange = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2026, 5),
    lastDate: defaultEnd,
    initialDateRange: DateTimeRange(
      start: startDate ?? defaultStart,
      end: endDate ?? defaultEnd,
    ),
  );

  // Closing the picker returns null. Also avoid using a disposed page.
  if (pickedRange == null || !context.mounted) return;
  await onPicked(pickedRange.start, pickedRange.end);
}

// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/entities/meal_planned_time_statistics.dart';
import '../../domain/usecases/get_meal_planned_time_statistics_usecase.dart';
import '../viewmodel/meal_planned_time_viewmodel.dart';
import '../widgets/statistics_page_helpers.dart';
import '../widgets/statistics_recipe_media_thumbnail.dart';
import '../widgets/statistics_pie_chart.dart';

/// Breaks planned meals into breakfast, lunch, and dinner groups.
// Handles MealPlannedTimePage for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class MealPlannedTimePage extends StatelessWidget {
  const MealPlannedTimePage({super.key});

  @override
  // Build the meal planned time page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    // The ViewModel controls date filtering and the open meal-time group.
    return ChangeNotifierProvider(
      create: (_) => MealPlannedTimeViewModel(
        getStatisticsUseCase: sl<GetMealPlannedTimeStatisticsUseCase>(),
      ),
      child: const _MealPlannedTimeView(),
    );
  }
}

// This widget builds the main content for the meal planned time view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
// Handles _MealPlannedTimeView for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _MealPlannedTimeView extends StatelessWidget {
  const _MealPlannedTimeView();

  @override
  // Build the meal planned time view with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    final viewModel = context.watch<MealPlannedTimeViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Meal Time Plan',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  // Handles _buildBody for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget _buildBody(BuildContext context, MealPlannedTimeViewModel viewModel) {
    // Wait for data before reading totals for the pie chart.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(inline: true, message: 'Loading meal time...');
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return _MealTimeError(
        message: viewModel.errorMessage ?? 'Unable to load meal time plan',
        onRetry: viewModel.loadStatistics,
      );
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The selected period is passed back to the ViewModel.
            StatisticsDateRangeBar(
              dateRange: statistics.dateRange,
              onTap: () => pickStatisticsDateRange(
                context: context,
                startDate: viewModel.startDate,
                endDate: viewModel.endDate,
                onPicked: (startDate, endDate) => viewModel.selectDateRange(
                  startDate: startDate,
                  endDate: endDate,
                ),
              ),
            ),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.event_available,
                    title: 'Meal Time',
                    value: statistics.totalDays.toString(),
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.room_service_outlined,
                    title: 'Total Meals',
                    value: statistics.totalMeals.toString(),
                  ),
                ),
              ],
            ),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.lg),
            _MealPlannedCard(statistics: statistics),
            const SizedBox(height: AppSpacing.lg),
            // Expand a meal-time group to show its individual meals.
            _MealBreakdown(
              segments: statistics.segments,
              expandedIndex: viewModel.expandedIndex,
              onToggle: viewModel.toggleBreakdown,
            ),
          ],
        ),
      ),
    );
  }
}

// This helper is responsible for the date range bar part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
// Handles DateRangeBar for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class DateRangeBar extends StatelessWidget {
  final String dateRange;

  const DateRangeBar({super.key, required this.dateRange});

  @override
  // Build the date range bar with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
        // Handles SizedBox for this part of the statistics page.
        // This makes the purpose clearer when reading or updating the code.
        const SizedBox(width: AppSpacing.sm),
        Expanded(
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
                // Handles Icon for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
                const Icon(Icons.calendar_month, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// This small widget draws one summary tile.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _SummaryTile for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  // Handles _SummaryTile for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  // Build the visual layout for this summary tile.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _SoftIcon(icon: icon),
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
                const SizedBox(height: 2),
                Text(
                  value,
                  style: context.text.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// This widget groups related information inside the meal planned card.
// The card gives the section a clear visual boundary on the page.
// Its parent supplies all values, labels, and interaction callbacks.
// Handles _MealPlannedCard for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _MealPlannedCard extends StatelessWidget {
  final MealPlannedTimeStatistics statistics;

  const _MealPlannedCard({required this.statistics});

  @override
  // Build the meal planned card with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    final chartSize = MediaQuery.sizeOf(context).width < 360 ? 238.0 : 260.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'Meal Planned',
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
          const SizedBox(height: AppSpacing.md),
          // MEAL-PLANNED-TIME PIE-CHART UI CALL STARTS HERE.
          // Breakfast, lunch, and dinner totals become pie segments.
          // Draws a pie chart of planned breakfast, lunch, and dinner meals.
          // Link: MealPlannedTimePage -> StatisticsPieChart.
          // Widget file: ../widgets/statistics_pie_chart.dart.
          StatisticsPieChart(
            size: chartSize,
            centerTitle: 'Total\nMeals',
            centerValue: statistics.totalMeals.toString(),
            segments: statistics.segments
                .map(
                  (segment) => StatisticsPieChartSegment(
                    label: segment.title,
                    value: segment.totalTaken,
                    color: segment.color,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// This widget displays the detailed meal breakdown.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
// Handles _MealBreakdown for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _MealBreakdown extends StatelessWidget {
  final List<MealPlannedTimeSegment> segments;
  final int? expandedIndex;
  final ValueChanged<int> onToggle;

  // Handles _MealBreakdown for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _MealBreakdown({
    required this.segments,
    required this.expandedIndex,
    required this.onToggle,
  });

  @override
  // Build the visible rows for the meal breakdown.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Meal Breakdown',
            style: context.text.titleMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: List.generate(segments.length, (index) {
                final segment = segments[index];
                final isExpanded = expandedIndex == index;
                return _BreakdownSection(
                  segment: segment,
                  isExpanded: isExpanded,
                  showDivider: index != segments.length - 1,
                  onTap: () => onToggle(index),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// This widget displays the detailed breakdown section.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
// Handles _BreakdownSection for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _BreakdownSection extends StatelessWidget {
  final MealPlannedTimeSegment segment;
  final bool isExpanded;
  final bool showDivider;
  final VoidCallback onTap;

  // Handles _BreakdownSection for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _BreakdownSection({
    required this.segment,
    required this.isExpanded,
    required this.showDivider,
    required this.onTap,
  });

  @override
  // Build the visible rows for the breakdown section.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _SoftIcon(icon: segment.icon),
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        segment.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Meals planned',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
                const SizedBox(width: AppSpacing.sm),
                Text(
                  segment.totalTaken.toString(),
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
                const SizedBox(width: AppSpacing.md),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...segment.meals.map((meal) => _MealItemRow(meal: meal)),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

// This small widget draws one meal item row.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _MealItemRow for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _MealItemRow extends StatelessWidget {
  final MealPlannedItem meal;

  const _MealItemRow({required this.meal});

  @override
  // Build the visual layout for this meal item row.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    final plannedDate = DateFormat('MMM d, yyyy').format(meal.plannedDate);

    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 7,
      ),
      child: Row(
        children: [
          _FoodIcon(icon: meal.icon, imageUrl: meal.imageUrl),
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  plannedDate,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
          const SizedBox(width: AppSpacing.sm),
          Text(
            meal.amount.toString(),
            style: context.text.bodyMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// This helper draws the reusable food icon.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
// Handles _FoodIcon for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _FoodIcon extends StatelessWidget {
  final IconData icon;
  final String? imageUrl;

  // Handles _FoodIcon for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _FoodIcon({required this.icon, this.imageUrl});

  @override
  // Build the visual layout for this food icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return StatisticsRecipeMediaThumbnail(
      mediaPath: imageUrl,
      fallbackIcon: icon,
      size: 32,
      backgroundColor: const Color(0xFFECE7CF),
      iconColor: const Color(0xFF6D642C),
      borderColor: const Color(0xFFD7C98D),
    );
  }
}

// This helper draws the reusable soft icon.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
// Handles _SoftIcon for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _SoftIcon extends StatelessWidget {
  final IconData icon;

  const _SoftIcon({required this.icon});

  @override
  // Build the visual layout for this soft icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF8F0),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

// This widget shows the meal time error when report data is unavailable.
// It explains the problem and gives the user a retry action.
// The retry callback asks the ViewModel to load the report again.
// Handles _MealTimeError for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _MealTimeError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  // Handles _MealTimeError for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _MealTimeError({required this.message, required this.onRetry});

  @override
  // Build the meal time error with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', height: 140),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
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

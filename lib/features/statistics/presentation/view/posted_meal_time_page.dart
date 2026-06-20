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
import '../../domain/entities/posted_meal_time_statistics.dart';
import '../../domain/usecases/get_posted_meal_time_statistics_usecase.dart';
import '../viewmodel/posted_meal_time_viewmodel.dart';
import '../widgets/statistics_page_helpers.dart';
import '../widgets/statistics_pie_chart.dart';

/// Groups shared recipe posts by breakfast, lunch, and dinner time.
// Handles PostedMealTimePage for this part of the statistics page.
class PostedMealTimePage extends StatelessWidget {
  const PostedMealTimePage({super.key});

  @override
  // Build the posted meal time page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    // The ViewModel loads the report and tracks the expanded time group.
    return ChangeNotifierProvider(
      create: (_) => PostedMealTimeViewModel(
        getStatisticsUseCase: sl<GetPostedMealTimeStatisticsUseCase>(),
      ),
      child: const _PostedMealTimeView(),
    );
  }
}

// This widget builds the main content for the posted meal time view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
// Handles _PostedMealTimeView for this part of the statistics page.
class _PostedMealTimeView extends StatelessWidget {
  const _PostedMealTimeView();

  @override
  // Build the posted meal time view with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final viewModel = context.watch<PostedMealTimeViewModel>();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Most Posted Meal Time',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  // Handles _buildBody for this part of the statistics page.
  Widget _buildBody(BuildContext context, PostedMealTimeViewModel viewModel) {
    // Wait for grouped post data before drawing the pie chart.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(inline: true, message: 'Loading meal time...');
    }
    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load meal time',
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
          children: [
            // Reload posted meal-time totals for the chosen period.
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
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.article_outlined,
                    title: 'Total Post',
                    value: statistics.totalPost.toString(),
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.room_service_outlined,
                    title: 'Most Posted Meal Time',
                    value: statistics.mostPostedMealTime,
                  ),
                ),
              ],
            ),
            // Handles SizedBox for this part of the statistics page.
            const SizedBox(height: AppSpacing.lg),
            _PieCard(statistics: statistics),
            const SizedBox(height: AppSpacing.lg),
            // Open a time group to see the posts counted inside it.
            _Breakdown(
              segments: statistics.segments,
              expandedIndex: viewModel.expandedIndex,
              onToggle: viewModel.toggleSegment,
            ),
          ],
        ),
      ),
    );
  }
}

// This widget groups related information inside the pie card.
// The card gives the section a clear visual boundary on the page.
// Its parent supplies all values, labels, and interaction callbacks.
// Handles _PieCard for this part of the statistics page.
class _PieCard extends StatelessWidget {
  final PostedMealTimeStatistics statistics;

  const _PieCard({required this.statistics});

  @override
  // Build the pie card with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final chartSize = MediaQuery.sizeOf(context).width < 360 ? 238.0 : 260.0;
    return _SectionCard(
      child: Column(
        children: [
          Text(
            'Meal Time Posted',
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(height: AppSpacing.md),
          // POSTED-MEAL-TIME PIE-CHART UI CALL STARTS HERE.
          // Breakfast, lunch, and dinner totals become pie segments.
          // Draws a pie chart of posts shared for each meal time.
          // Link: PostedMealTimePage -> StatisticsPieChart.
          // Widget file: ../widgets/statistics_pie_chart.dart.
          StatisticsPieChart(
            size: chartSize,
            centerTitle: 'Total\nPosts',
            centerValue: statistics.totalPost.toString(),
            segments: statistics.segments
                .map(
                  (segment) => StatisticsPieChartSegment(
                    label: segment.title,
                    value: segment.totalPosted,
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

// This widget displays the detailed breakdown.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
// Handles _Breakdown for this part of the statistics page.
class _Breakdown extends StatelessWidget {
  final List<PostedMealTimeSegment> segments;
  final int? expandedIndex;
  final ValueChanged<int> onToggle;

  // Handles _Breakdown for this part of the statistics page.
  const _Breakdown({
    required this.segments,
    required this.expandedIndex,
    required this.onToggle,
  });

  @override
  // Build the visible rows for the breakdown.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return _SectionCard(
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
                return _SegmentSection(
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

// This widget represents one segment section in the report.
// It owns the header and the content that belongs to this group.
// The expanded state decides whether the detailed rows are visible.
// Handles _SegmentSection for this part of the statistics page.
class _SegmentSection extends StatelessWidget {
  final PostedMealTimeSegment segment;
  final bool isExpanded;
  final bool showDivider;
  final VoidCallback onTap;

  // Handles _SegmentSection for this part of the statistics page.
  const _SegmentSection({
    required this.segment,
    required this.isExpanded,
    required this.showDivider,
    required this.onTap,
  });

  @override
  // Build the visible rows for the segment section.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _SoftIcon(icon: segment.icon),
                // Handles SizedBox for this part of the statistics page.
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        segment.title,
                        style: context.text.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Total Posted',
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  segment.totalPosted.toString(),
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
                const SizedBox(width: AppSpacing.md),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...segment.meals.map((meal) => _MealRow(meal: meal)),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

// This small widget draws one meal row.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _MealRow for this part of the statistics page.
class _MealRow extends StatelessWidget {
  final PostedMealTimeItem meal;

  const _MealRow({required this.meal});

  @override
  // Build the visual layout for this meal row.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, yyyy').format(meal.date);
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 7,
      ),
      child: Row(
        children: [
          _FoodIcon(icon: meal.icon),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.recipeName,
                  style: context.text.bodyMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  date,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            meal.quantity.toString(),
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

// This helper is responsible for the date range bar part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
// Handles DateRangeBar for this part of the statistics page.
class DateRangeBar extends StatelessWidget {
  final String dateRange;

  const DateRangeBar({super.key, required this.dateRange});

  @override
  // Build the date range bar with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Date Range:', style: context.text.bodySmall),
        // Handles SizedBox for this part of the statistics page.
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
                  child: Text(dateRange, overflow: TextOverflow.ellipsis),
                ),
                // Handles Icon for this part of the statistics page.
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
class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  // Handles _SummaryTile for this part of the statistics page.
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
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _SoftIcon(icon: icon),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, overflow: TextOverflow.ellipsis),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
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

// This widget represents one section card in the report.
// It owns the header and the content that belongs to this group.
// The expanded state decides whether the detailed rows are visible.
// Handles _SectionCard for this part of the statistics page.
class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  // Build the visible rows for the section card.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}

// This helper draws the reusable food icon.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
// Handles _FoodIcon for this part of the statistics page.
class _FoodIcon extends StatelessWidget {
  final IconData icon;

  const _FoodIcon({required this.icon});

  @override
  // Build the visual layout for this food icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFECE7CF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD7C98D)),
      ),
      child: Icon(icon, color: const Color(0xFF6D642C), size: 18),
    );
  }
}

// This helper draws the reusable soft icon.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
// Handles _SoftIcon for this part of the statistics page.
class _SoftIcon extends StatelessWidget {
  final IconData icon;

  const _SoftIcon({required this.icon});

  @override
  // Build the visual layout for this soft icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
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

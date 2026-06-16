import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/entities/admin_statistics.dart';
import '../../domain/usecases/get_admin_hub_rating_statistics_usecase.dart';
import '../viewmodel/admin_hub_rating_viewmodel.dart';
import '../widgets/admin_statistics_detail_widgets.dart';
import '../widgets/statistics_line_chart.dart';
import '../widgets/statistics_page_helpers.dart';

/// Admin report showing how users rated the application hub.
class AdminHubRatingPage extends StatelessWidget {
  const AdminHubRatingPage({super.key});

  @override
  // Build the admin hub rating page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  Widget build(BuildContext context) {
    // The ViewModel loads rating history for the selected date range.
    return ChangeNotifierProvider(
      create: (_) => AdminHubRatingViewModel(
        getStatisticsUseCase: sl<GetAdminHubRatingStatisticsUseCase>(),
      ),
      child: const _AdminHubRatingView(),
    );
  }
}

// This widget builds the main content for the admin hub rating view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
class _AdminHubRatingView extends StatefulWidget {
  const _AdminHubRatingView();

  @override
  State<_AdminHubRatingView> createState() => _AdminHubRatingViewState();
}

// This state object manages the changing parts of the admin hub rating view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
class _AdminHubRatingViewState extends State<_AdminHubRatingView> {
  @override
  // Build the admin hub rating view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminHubRatingViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Hub Rating',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(viewModel),
    );
  }

  Widget _buildBody(AdminHubRatingViewModel viewModel) {
    // Wait for monthly rating values before building the report.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading hub rating...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load hub rating',
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
            // Reload rating history when the admin changes the period.
            AdminStatisticDateRangeBar(
              dateRange: statistics.dateRange,
              onTap: () => _pickDateRange(viewModel),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AdminStatisticSummaryTile(
                    icon: Icons.star_border,
                    title: 'Total User Rating',
                    value: statistics.totalRatings.toString(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AdminStatisticSummaryTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Average Rating',
                    value: statistics.averageRating.toStringAsFixed(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _HubRatingChart(months: statistics.monthlyRatings),
            const SizedBox(height: AppSpacing.lg),
            _HubRatingBreakdown(months: statistics.monthlyRatings),
          ],
        ),
      ),
    );
  }

  // Open the calendar with the current range already selected.
  // Send confirmed dates to the ViewModel so it can reload the report.
  Future<void> _pickDateRange(AdminHubRatingViewModel viewModel) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final defaultStart = DateTime(2026, 5);
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: defaultStart,
      lastDate: today,
      initialDateRange: DateTimeRange(
        start: viewModel.startDate ?? defaultStart,
        end: viewModel.endDate ?? today,
      ),
    );

    if (pickedRange == null || !mounted) return;
    await viewModel.selectDateRange(
      startDate: pickedRange.start,
      endDate: pickedRange.end,
    );
  }
}

// This widget turns the report values into the hub rating chart.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
class _HubRatingChart extends StatelessWidget {
  final List<AdminMonthlyRatingStatistic> months;

  const _HubRatingChart({required this.months});

  @override
  // Build the hub rating chart from the values supplied by the parent.
  // Labels, scale, and spacing are prepared before the chart is displayed.
  // This method only handles presentation and does not change report data.
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM yy');
    return _SectionCard(
      title: 'Hub Rating Vs Month',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: (months.length * 64.0).clamp(
            MediaQuery.sizeOf(context).width - 52,
            double.infinity,
          ),
          // HUB-RATING LINE-CHART UI CALL STARTS HERE.
          // Monthly rating values are passed into the shared line chart.
          // Draws a line chart showing the average hub rating for each month.
          // Link: AdminHubRatingPage -> StatisticsLineChart.
          // Widget file: ../widgets/statistics_line_chart.dart.
          child: StatisticsLineChart(
            points: months
                .map(
                  (month) => StatisticsLineChartPoint(
                    label: formatter.format(month.month),
                    value: month.ratingCount,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

// This widget displays the detailed hub rating breakdown.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
class _HubRatingBreakdown extends StatelessWidget {
  final List<AdminMonthlyRatingStatistic> months;

  const _HubRatingBreakdown({required this.months});

  @override
  // Build the visible rows for the hub rating breakdown.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMMM yyyy');
    return _SectionCard(
      title: 'Hub Rating Breakdown',
      alignTitleLeft: true,
      child: Column(
        children: months
            .map(
              (month) => _RatingBreakdownRow(
                label: formatter.format(month.month),
                averageRating: month.averageRating,
                ratingCount: month.ratingCount,
              ),
            )
            .toList(),
      ),
    );
  }
}

// This widget represents one section card in the report.
// It owns the header and the content that belongs to this group.
// The expanded state decides whether the detailed rows are visible.
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool alignTitleLeft;

  const _SectionCard({
    required this.title,
    required this.child,
    this.alignTitleLeft = false,
  });

  @override
  // Build the visible rows for the section card.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: alignTitleLeft
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: alignTitleLeft ? TextAlign.start : TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

// This widget displays the detailed rating breakdown row.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
class _RatingBreakdownRow extends StatelessWidget {
  final String label;
  final double averageRating;
  final int ratingCount;

  const _RatingBreakdownRow({
    required this.label,
    required this.averageRating,
    required this.ratingCount,
  });

  @override
  // Build the visible rows for the rating breakdown row.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Stars(rating: averageRating),
              const SizedBox(width: 4),
              _RatingPill(rating: averageRating),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            ratingCount.toString(),
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// This helper draws the reusable stars.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
class _Stars extends StatelessWidget {
  final double rating;

  const _Stars({required this.rating});

  @override
  // Build the visual layout for this stars.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final filled = index < rating.round();
        return Icon(
          filled ? Icons.star : Icons.star_border,
          color: filled ? AppColors.primary : AppColors.border,
          size: 13,
        );
      }),
    );
  }
}

// This helper draws the reusable rating pill.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
class _RatingPill extends StatelessWidget {
  final double rating;

  const _RatingPill({required this.rating});

  @override
  // Build the visual layout for this rating pill.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rating.toStringAsFixed(1),
        style: context.text.bodySmall?.copyWith(
          color: AppColors.primary,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

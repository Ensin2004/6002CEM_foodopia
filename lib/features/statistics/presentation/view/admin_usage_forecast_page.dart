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
import '../../domain/usecases/get_admin_usage_forecast_statistics_usecase.dart';
import '../viewmodel/admin_usage_forecast_viewmodel.dart';
import '../widgets/admin_statistics_detail_widgets.dart';
import '../widgets/statistics_line_chart.dart';
import '../widgets/statistics_page_helpers.dart';

/// Admin report comparing actual user growth with a simple forecast.
class AdminUsageForecastPage extends StatelessWidget {
  const AdminUsageForecastPage({super.key});

  @override
  // Build the admin usage forecast page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  Widget build(BuildContext context) {
    // The ViewModel loads the history used by the forecast widgets.
    return ChangeNotifierProvider(
      create: (_) => AdminUsageForecastViewModel(
        getStatisticsUseCase: sl<GetAdminUsageForecastStatisticsUseCase>(),
      ),
      child: const _AdminUsageForecastView(),
    );
  }
}

// This widget builds the main content for the admin usage forecast view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
class _AdminUsageForecastView extends StatefulWidget {
  const _AdminUsageForecastView();

  @override
  State<_AdminUsageForecastView> createState() =>
      _AdminUsageForecastViewState();
}

// This state object manages the changing parts of the admin usage forecast view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
class _AdminUsageForecastViewState extends State<_AdminUsageForecastView> {
  @override
  // Build the admin usage forecast view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminUsageForecastViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Usage Forecast',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(viewModel),
    );
  }

  Widget _buildBody(AdminUsageForecastViewModel viewModel) {
    // Wait for enough monthly values before calculating a prediction.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading usage forecast...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load usage forecast',
        onRetry: viewModel.loadStatistics,
      );
    }

    AdminMonthlyUserStatistic? prediction;
    for (final month in statistics.monthlyUsers) {
      if (month.isPrediction) {
        prediction = month;
        break;
      }
    }
    final actualMonths = statistics.monthlyUsers
        .where((month) => !month.isPrediction)
        .toList(growable: false);
    final confidence = _confidenceLabel(actualMonths);

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
            // A new range changes both the history and its forecast.
            AdminStatisticDateRangeBar(
              dateRange: statistics.dateRange,
              onTap: () => _pickDateRange(viewModel),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AdminStatisticSummaryTile(
                    icon: Icons.people_outline,
                    title: 'Current New User',
                    value: statistics.totalUsers.toString(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AdminStatisticSummaryTile(
                    icon: Icons.trending_up,
                    title: 'Predict Next Month',
                    value: prediction == null
                        ? '-'
                        : prediction.newUsers.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _ForecastResultCard(prediction: prediction, confidence: confidence),
            const SizedBox(height: AppSpacing.lg),
            _ForecastChart(months: statistics.monthlyUsers),
            const SizedBox(height: AppSpacing.lg),
            _ForecastBreakdown(
              months: statistics.monthlyUsers,
              confidence: confidence,
            ),
          ],
        ),
      ),
    );
  }

  // This helper prepares a value used by the visible report.
  // Keeping it outside build makes the widget tree easier to follow.
  String _confidenceLabel(List<AdminMonthlyUserStatistic> months) {
    final totalUsers = months.fold<int>(0, (sum, item) => sum + item.newUsers);
    if (totalUsers < 7) return 'Low confidence';
    if (totalUsers < 20) return 'Medium confidence';
    return 'High confidence';
  }

  // Open the calendar with the current range already selected.
  // Send confirmed dates to the ViewModel so it can reload the report.
  Future<void> _pickDateRange(AdminUsageForecastViewModel viewModel) async {
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

// This widget groups related information inside the forecast result card.
// The card gives the section a clear visual boundary on the page.
// Its parent supplies all values, labels, and interaction callbacks.
class _ForecastResultCard extends StatelessWidget {
  final AdminMonthlyUserStatistic? prediction;
  final String confidence;

  const _ForecastResultCard({
    required this.prediction,
    required this.confidence,
  });

  @override
  // Build the forecast result card with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMMM yyyy');
    final month = prediction == null
        ? '-'
        : formatter.format(prediction!.month);
    final value = prediction?.newUsers ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F0),
        border: Border.all(color: const Color(0xFFC8EBD7)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const _SoftIcon(icon: Icons.insights_outlined),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forecast Result',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$value new users expected in $month',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            confidence,
            maxLines: 2,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// This widget turns the report values into the forecast chart.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
class _ForecastChart extends StatelessWidget {
  final List<AdminMonthlyUserStatistic> months;

  const _ForecastChart({required this.months});

  @override
  // Build the forecast chart from the values supplied by the parent.
  // Labels, scale, and spacing are prepared before the chart is displayed.
  // This method only handles presentation and does not change report data.
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM yy');
    return _SectionCard(
      title: 'Actual Vs Predicted User Growth',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: (months.length * 70.0).clamp(
            MediaQuery.sizeOf(context).width - 52,
            double.infinity,
          ),
          // USAGE-FORECAST LINE-CHART UI CALL STARTS HERE.
          // Actual and prepared forecast values are displayed as chart points.
          // Draws a line chart showing actual and predicted user growth.
          // Link: AdminUsageForecastPage -> StatisticsLineChart.
          // Widget file: ../widgets/statistics_line_chart.dart.
          child: StatisticsLineChart(
            points: months
                .map(
                  (month) => StatisticsLineChartPoint(
                    label: month.isPrediction
                        ? 'Next'
                        : formatter.format(month.month),
                    value: month.newUsers,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

// This widget displays the detailed forecast breakdown.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
class _ForecastBreakdown extends StatelessWidget {
  final List<AdminMonthlyUserStatistic> months;
  final String confidence;

  const _ForecastBreakdown({required this.months, required this.confidence});

  @override
  // Build the visible rows for the forecast breakdown.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMMM yyyy');

    return _SectionCard(
      title: 'Forecast Breakdown',
      alignTitleLeft: true,
      child: Column(
        children: months.map((month) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    month.isPrediction
                        ? 'Prediction - ${formatter.format(month.month)}'
                        : formatter.format(month.month),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${month.newUsers} user',
                      style: context.text.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    if (month.isPrediction)
                      Text(
                        confidence,
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
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

// This helper draws the reusable soft icon.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
class _SoftIcon extends StatelessWidget {
  final IconData icon;

  const _SoftIcon({required this.icon});

  @override
  // Build the visual layout for this soft icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

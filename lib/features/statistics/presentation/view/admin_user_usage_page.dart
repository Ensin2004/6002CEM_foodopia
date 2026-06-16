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
import '../../domain/usecases/get_admin_user_usage_statistics_usecase.dart';
import '../viewmodel/admin_user_usage_viewmodel.dart';
import '../widgets/admin_statistics_detail_widgets.dart';
import '../widgets/statistics_line_chart.dart';
import '../widgets/statistics_page_helpers.dart';

/// Admin report showing new-user growth over time.
class AdminUserUsagePage extends StatelessWidget {
  const AdminUserUsagePage({super.key});

  @override
  // Build the admin user usage page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  Widget build(BuildContext context) {
    // The ViewModel loads monthly usage values for the selected date range.
    return ChangeNotifierProvider(
      create: (_) => AdminUserUsageViewModel(
        getStatisticsUseCase: sl<GetAdminUserUsageStatisticsUseCase>(),
      ),
      child: const _AdminUserUsageView(),
    );
  }
}

// This widget builds the main content for the admin user usage view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
class _AdminUserUsageView extends StatefulWidget {
  const _AdminUserUsageView();

  @override
  State<_AdminUserUsageView> createState() => _AdminUserUsageViewState();
}

// This state object manages the changing parts of the admin user usage view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
class _AdminUserUsageViewState extends State<_AdminUserUsageView> {
  @override
  // Build the admin user usage view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminUserUsageViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'User Usage',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(viewModel),
    );
  }

  Widget _buildBody(AdminUserUsageViewModel viewModel) {
    // Wait for monthly values before drawing the growth line.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading user usage...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load user usage',
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
            // Reload monthly values when the admin changes the date range.
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
                    title: 'Total User',
                    value: statistics.totalUsers.toString(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AdminStatisticSummaryTile(
                    icon: Icons.calendar_month,
                    title: 'Most New User',
                    value: statistics.topMonth,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _MonthlyUserChart(months: statistics.monthlyUsers),
            const SizedBox(height: AppSpacing.lg),
            _MonthlyUserBreakdown(months: statistics.monthlyUsers),
          ],
        ),
      ),
    );
  }

  // Open the calendar with the current range already selected.
  // Send confirmed dates to the ViewModel so it can reload the report.
  Future<void> _pickDateRange(AdminUserUsageViewModel viewModel) async {
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

// This widget turns the report values into the monthly user chart.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
class _MonthlyUserChart extends StatelessWidget {
  final List<AdminMonthlyUserStatistic> months;

  const _MonthlyUserChart({required this.months});

  @override
  // Build the monthly user chart from the values supplied by the parent.
  // Labels, scale, and spacing are prepared before the chart is displayed.
  // This method only handles presentation and does not change report data.
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM yy');
    return _SectionCard(
      title: 'New User Vs Month',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: (months.length * 64.0).clamp(
            MediaQuery.sizeOf(context).width - 52,
            double.infinity,
          ),
          // USER-USAGE LINE-CHART UI CALL STARTS HERE.
          // Monthly new-user totals are passed into the shared line chart.
          // Draws a line chart showing how many new users joined each month.
          // Link: AdminUserUsagePage -> StatisticsLineChart.
          // Widget file: ../widgets/statistics_line_chart.dart.
          child: StatisticsLineChart(
            points: months
                .map(
                  (month) => StatisticsLineChartPoint(
                    label: formatter.format(month.month),
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

// This widget displays the detailed monthly user breakdown.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
class _MonthlyUserBreakdown extends StatelessWidget {
  final List<AdminMonthlyUserStatistic> months;

  const _MonthlyUserBreakdown({required this.months});

  @override
  // Build the visible rows for the monthly user breakdown.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMMM yyyy');
    final totalUsers = months.fold<int>(
      0,
      (total, month) => total + month.newUsers,
    );
    var runningTotal = 0;

    return _SectionCard(
      title: 'New User Breakdown',
      alignTitleLeft: true,
      child: Column(
        children: [
          if (months.isEmpty)
            Text(
              'No user data in this date range',
              textAlign: TextAlign.center,
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...months.map((month) {
              runningTotal += month.newUsers;
              final percent = totalUsers == 0
                  ? 0
                  : ((month.newUsers / totalUsers) * 100).round();
              return _BreakdownRow(
                label: formatter.format(month.month),
                newUsers: month.newUsers,
                runningTotal: runningTotal,
                percent: percent,
              );
            }),
        ],
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

// This widget displays the detailed breakdown row.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
class _BreakdownRow extends StatelessWidget {
  final String label;
  final int newUsers;
  final int runningTotal;
  final int percent;

  const _BreakdownRow({
    required this.label,
    required this.newUsers,
    required this.runningTotal,
    required this.percent,
  });

  @override
  // Build the visible rows for the breakdown row.
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$newUsers new',
                style: context.text.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$runningTotal total - $percent%',
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
  }
}

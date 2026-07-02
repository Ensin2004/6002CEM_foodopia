// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/usecases/get_admin_post_analytic_statistics_usecase.dart';
import '../viewmodel/admin_post_analytic_viewmodel.dart';
import '../widgets/admin_statistics_detail_widgets.dart';
import '../widgets/statistics_page_helpers.dart';

/// Admin report for post activity, ratings, and recipe performance.
// Handles AdminPostAnalyticPage for this part of the statistics page.
class AdminPostAnalyticPage extends StatelessWidget {
  const AdminPostAnalyticPage({super.key});

  @override
  // Build the admin post analytic page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    // The ViewModel owns section paging, sorting, and recipe selection.
    return ChangeNotifierProvider(
      create: (_) => AdminPostAnalyticViewModel(
        getStatisticsUseCase: sl<GetAdminPostAnalyticStatisticsUseCase>(),
      ),
      child: const _AdminPostAnalyticView(),
    );
  }
}

// This widget builds the main content for the admin post analytic view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
// Handles _AdminPostAnalyticView for this part of the statistics page.
class _AdminPostAnalyticView extends StatefulWidget {
  const _AdminPostAnalyticView();

  // Handles createState for this part of the statistics page.
  @override
  State<_AdminPostAnalyticView> createState() => _AdminPostAnalyticViewState();
}

// This state object manages the changing parts of the admin post analytic view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
// Handles _AdminPostAnalyticViewState for this part of the statistics page.
class _AdminPostAnalyticViewState extends State<_AdminPostAnalyticView> {
  late final PageController _sectionController;
  final DateFormat _summaryDateFormatter = DateFormat('MMM d, yyyy');

  // Handles initState for this part of the statistics page.
  @override
  void initState() {
    super.initState();
    _sectionController = PageController();
  }

  // Handles dispose for this part of the statistics page.
  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  @override
  // Build the admin post analytic view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminPostAnalyticViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Post Analytic',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(viewModel),
    );
  }

  // Handles _buildBody for this part of the statistics page.
  Widget _buildBody(AdminPostAnalyticViewModel viewModel) {
    // Wait for post data before building the system report.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading post analytic...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load post analytic',
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
            // Reload the daily chart and all post sections for this period.
            AdminStatisticDateRangeBar(
              dateRange: statistics.dateRange,
              onTap: () => _pickDateRange(viewModel),
            ),
            // Handles SizedBox for this part of the statistics page.
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AdminStatisticSummaryTile(
                    icon: Icons.trending_up,
                    title: 'Top Posted Day',
                    value:
                        '${_summaryDateFormatter.format(statistics.topDay.date)} (${statistics.topDay.value})',
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AdminStatisticSummaryTile(
                    icon: Icons.trending_down,
                    title: 'Least Posted Day',
                    value:
                        '${_summaryDateFormatter.format(statistics.leastDay.date)} (${statistics.leastDay.value})',
                  ),
                ),
              ],
            ),
            // Handles SizedBox for this part of the statistics page.
            const SizedBox(height: AppSpacing.lg),
            // ADMIN POST LINE-CHART UI CALL STARTS HERE.
            // The shared card converts dailyPosts into line-chart points.
            // Draws a line chart showing the number of posts created each day.
            // Link: AdminPostAnalyticPage -> AdminLineChartCard.
            // Next: admin_statistics_detail_widgets.dart -> StatisticsLineChart.
            AdminLineChartCard(
              title: 'Posted Vs Day',
              values: statistics.dailyPosts,
            ),
            // Handles SizedBox for this part of the statistics page.
            const SizedBox(height: AppSpacing.lg),
            // Most sections use this pager; performance has a custom view.
            // ADMIN POST SECTION UI CALL STARTS HERE.
            // The pager builds the selected section and asks _SectionChart to
            // choose the correct pie or bar chart.
            // Draws the selected post-analysis pie chart or bar chart.
            // Link: AdminPostAnalyticPage -> AdminAnalyticSectionPager.
            // Next: admin_statistics_detail_widgets.dart -> _SectionChart.
            AdminAnalyticSectionPager(
              controller: _sectionController,
              sections: statistics.sections,
              selectedIndex: viewModel.selectedSectionIndex,
              sortOrder: viewModel.sortOrder,
              onPageChanged: viewModel.selectSection,
              onSortChanged: viewModel.setSortOrder,
            ),
          ],
        ),
      ),
    );
  }

  // Open the calendar with the current range already selected.
  // Send confirmed dates to the ViewModel so it can reload the report.
  // Handles _pickDateRange for this part of the statistics page.
  Future<void> _pickDateRange(AdminPostAnalyticViewModel viewModel) async {
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

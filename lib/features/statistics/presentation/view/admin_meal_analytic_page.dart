// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/usecases/get_admin_meal_analytic_statistics_usecase.dart';
import '../viewmodel/admin_meal_analytic_viewmodel.dart';
import '../widgets/admin_statistics_detail_widgets.dart';
import '../widgets/statistics_page_helpers.dart';

/// Admin report for meal-plan activity across the whole system.
// Handles AdminMealAnalyticPage for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class AdminMealAnalyticPage extends StatelessWidget {
  const AdminMealAnalyticPage({super.key});

  @override
  // Build the admin meal analytic page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    // The ViewModel owns the date range, selected section, and sort order.
    return ChangeNotifierProvider(
      create: (_) => AdminMealAnalyticViewModel(
        getStatisticsUseCase: sl<GetAdminMealAnalyticStatisticsUseCase>(),
      ),
      child: const _AdminMealAnalyticView(),
    );
  }
}

// This widget builds the main content for the admin meal analytic view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
// Handles _AdminMealAnalyticView for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _AdminMealAnalyticView extends StatefulWidget {
  const _AdminMealAnalyticView();

  // Handles createState for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  State<_AdminMealAnalyticView> createState() => _AdminMealAnalyticViewState();
}

// This state object manages the changing parts of the admin meal analytic view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
// Handles _AdminMealAnalyticViewState for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _AdminMealAnalyticViewState extends State<_AdminMealAnalyticView> {
  late final PageController _sectionController;
  final DateFormat _summaryDateFormatter = DateFormat('MMM d, yyyy');

  // Handles initState for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  void initState() {
    super.initState();
    _sectionController = PageController();
  }

  // Handles dispose for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  @override
  // Build the admin meal analytic view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminMealAnalyticViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Planned Meal Analytic',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(viewModel),
    );
  }

  // Handles _buildBody for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget _buildBody(AdminMealAnalyticViewModel viewModel) {
    // Wait for system-wide meal data before building charts.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading meal analytic...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load meal analytic',
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
            // A new range reloads the daily chart and every report section.
            AdminStatisticDateRangeBar(
              dateRange: statistics.dateRange,
              onTap: () => _pickDateRange(viewModel),
            ),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AdminStatisticSummaryTile(
                    icon: Icons.trending_up,
                    title: 'Top Planned Day',
                    value:
                        '${_summaryDateFormatter.format(statistics.topDay.date)} (${statistics.topDay.value})',
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AdminStatisticSummaryTile(
                    icon: Icons.trending_down,
                    title: 'Least Planned Day',
                    value:
                        '${_summaryDateFormatter.format(statistics.leastDay.date)} (${statistics.leastDay.value})',
                  ),
                ),
              ],
            ),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.lg),
            // ADMIN MEAL LINE-CHART UI CALL STARTS HERE.
            // The shared card converts dailyPlans into line-chart points.
            // Draws a line chart showing the number of meals planned each day.
            // Link: AdminMealAnalyticPage -> AdminLineChartCard.
            // Next: admin_statistics_detail_widgets.dart -> StatisticsLineChart.
            AdminLineChartCard(
              title: 'Meal Planned Vs Day',
              values: statistics.dailyPlans,
            ),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.lg),
            // Swipe or tap tabs to move through the different meal reports.
            // ADMIN MEAL SECTION UI CALL STARTS HERE.
            // Inside this pager, _SectionChart chooses a pie chart or bar chart
            // based on the title of the currently selected report section.
            // Draws the selected meal-analysis pie chart or bar chart.
            // Link: AdminMealAnalyticPage -> AdminAnalyticSectionPager.
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
  // This makes the purpose clearer when reading or updating the code.
  Future<void> _pickDateRange(AdminMealAnalyticViewModel viewModel) async {
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/usecases/get_admin_gender_statistics_usecase.dart';
import '../viewmodel/admin_gender_viewmodel.dart';
import '../widgets/admin_statistics_detail_widgets.dart';
import '../widgets/statistics_page_helpers.dart';

/// Admin report showing the gender distribution of users.
class AdminGenderPage extends StatelessWidget {
  const AdminGenderPage({super.key});

  @override
  // Build the admin gender page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  Widget build(BuildContext context) {
    // The ViewModel loads gender totals for the selected period.
    return ChangeNotifierProvider(
      create: (_) => AdminGenderViewModel(
        getStatisticsUseCase: sl<GetAdminGenderStatisticsUseCase>(),
      ),
      child: const _AdminGenderView(),
    );
  }
}

// This widget builds the main content for the admin gender view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
class _AdminGenderView extends StatefulWidget {
  const _AdminGenderView();

  @override
  State<_AdminGenderView> createState() => _AdminGenderViewState();
}

// This state object manages the changing parts of the admin gender view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
class _AdminGenderViewState extends State<_AdminGenderView> {
  @override
  // Build the admin gender view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminGenderViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Gender',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(viewModel),
    );
  }

  Widget _buildBody(AdminGenderViewModel viewModel) {
    // Wait for gender data before drawing the summary and pie chart.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(inline: true, message: 'Loading gender...');
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load gender',
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
                    icon: Icons.workspace_premium_outlined,
                    title: 'Most Gender',
                    value: statistics.mostGender,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Reuse the preference pie widget because the data shape is the same.
            // GENDER PIE-CHART UI CALL STARTS HERE.
            // This page passes gender values into the shared admin pie card.
            // The card later calls StatisticsPieChart to draw the slices.
            // Draws a pie chart showing the gender distribution of users.
            // Link: AdminGenderPage -> AdminPreferencePieCard.
            // Next: admin_statistics_detail_widgets.dart -> StatisticsPieChart.
            AdminPreferencePieCard(
              title: 'Gender',
              totalUsers: statistics.totalUsers,
              preferences: statistics.genders,
            ),
            const SizedBox(height: AppSpacing.lg),
            AdminRankedStatisticList(
              title: 'Gender Quantity',
              items: statistics.genders,
            ),
          ],
        ),
      ),
    );
  }

  // Open the calendar with the current range already selected.
  // Send confirmed dates to the ViewModel so it can reload the report.
  Future<void> _pickDateRange(AdminGenderViewModel viewModel) async {
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

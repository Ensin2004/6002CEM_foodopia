// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/usecases/get_admin_dietary_preference_statistics_usecase.dart';
import '../viewmodel/admin_dietary_preference_viewmodel.dart';
import '../widgets/admin_statistics_detail_widgets.dart';
import '../widgets/statistics_page_helpers.dart';

/// Admin report showing the dietary preferences chosen by users.
// Handles AdminDietaryPreferencePage for this part of the statistics page.
class AdminDietaryPreferencePage extends StatelessWidget {
  const AdminDietaryPreferencePage({super.key});

  @override
  // Build the admin dietary preference page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    // The ViewModel loads preference totals for the selected date range.
    return ChangeNotifierProvider(
      create: (_) => AdminDietaryPreferenceViewModel(
        getStatisticsUseCase: sl<GetAdminDietaryPreferenceStatisticsUseCase>(),
      ),
      child: const _AdminDietaryPreferenceView(),
    );
  }
}

// This widget builds the main content for the admin dietary preference view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
// Handles _AdminDietaryPreferenceView for this part of the statistics page.
class _AdminDietaryPreferenceView extends StatefulWidget {
  const _AdminDietaryPreferenceView();

  // Handles createState for this part of the statistics page.
  @override
  State<_AdminDietaryPreferenceView> createState() =>
      _AdminDietaryPreferenceViewState();
}

// This state object manages the changing parts of the admin dietary preference view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
// Handles _AdminDietaryPreferenceViewState for this part of the statistics page.
class _AdminDietaryPreferenceViewState
    extends State<_AdminDietaryPreferenceView> {
  @override
  // Build the admin dietary preference view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminDietaryPreferenceViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Dietary Preference',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(viewModel),
    );
  }

  // Handles _buildBody for this part of the statistics page.
  Widget _buildBody(AdminDietaryPreferenceViewModel viewModel) {
    // Wait for preference data before drawing the pie chart.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading dietary preference...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load dietary preference',
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
            // Handles SizedBox for this part of the statistics page.
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
                // Handles SizedBox for this part of the statistics page.
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AdminStatisticSummaryTile(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Top Preference',
                    value: statistics.topPreference,
                  ),
                ),
              ],
            ),
            // Handles SizedBox for this part of the statistics page.
            const SizedBox(height: AppSpacing.lg),
            // The pie chart and ranked list use the same preference values.
            // DIETARY-PREFERENCE PIE-CHART UI CALL STARTS HERE.
            // The shared card receives the preference values and turns them
            // into segments for StatisticsPieChart.
            // Draws a pie chart showing users in each dietary preference.
            // Link: AdminDietaryPreferencePage -> AdminPreferencePieCard.
            // Next: admin_statistics_detail_widgets.dart -> StatisticsPieChart.
            AdminPreferencePieCard(
              totalUsers: statistics.totalUsers,
              preferences: statistics.preferences,
            ),
            // Handles SizedBox for this part of the statistics page.
            const SizedBox(height: AppSpacing.lg),
            AdminRankedStatisticList(
              title: 'Preference Quantity',
              items: statistics.preferences,
            ),
          ],
        ),
      ),
    );
  }

  // Open the calendar with the current range already selected.
  // Send confirmed dates to the ViewModel so it can reload the report.
  // Handles _pickDateRange for this part of the statistics page.
  Future<void> _pickDateRange(AdminDietaryPreferenceViewModel viewModel) async {
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

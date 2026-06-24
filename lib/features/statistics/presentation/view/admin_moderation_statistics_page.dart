// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/entities/admin_statistics.dart';
import '../../domain/usecases/get_admin_moderation_statistics_usecase.dart';
import '../viewmodel/admin_moderation_statistics_viewmodel.dart';
import '../widgets/admin_statistics_detail_widgets.dart';
import '../widgets/statistics_bar_chart.dart';
import '../widgets/statistics_page_helpers.dart';

// Handles AdminModerationStatisticsPage for this part of the statistics page.
class AdminModerationStatisticsPage extends StatelessWidget {
  const AdminModerationStatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminModerationStatisticsViewModel(
        getStatisticsUseCase: sl<GetAdminModerationStatisticsUseCase>(),
      ),
      child: const _AdminModerationStatisticsView(),
    );
  }
}

class _AdminModerationStatisticsView extends StatefulWidget {
  const _AdminModerationStatisticsView();

  @override
  State<_AdminModerationStatisticsView> createState() =>
      _AdminModerationStatisticsViewState();
}

class _AdminModerationStatisticsViewState
    extends State<_AdminModerationStatisticsView> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminModerationStatisticsViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Moderation Statistics',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(viewModel),
    );
  }

  Widget _buildBody(AdminModerationStatisticsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading moderation statistics...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message:
            viewModel.errorMessage ?? 'Unable to load moderation statistics',
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
                    icon: Icons.restaurant_menu,
                    title: 'Total Recipes',
                    value: statistics.totalRecipes.toString(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AdminStatisticSummaryTile(
                    icon: Icons.flag_outlined,
                    title: 'Top Status',
                    value: statistics.topStatus,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _ModerationStatusBarCard(statistics: statistics),
            const SizedBox(height: AppSpacing.lg),
            AdminRankedStatisticList(
              title: 'Moderation Status Quantity',
              items: statistics.statuses,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange(
    AdminModerationStatisticsViewModel viewModel,
  ) async {
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

class _ModerationStatusBarCard extends StatelessWidget {
  final AdminModerationStatistics statistics;

  const _ModerationStatusBarCard({required this.statistics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'Recipes By Moderation Status',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StatisticsBarChart(
            height: 220,
            items: statistics.statuses
                .map(
                  (status) => StatisticsBarChartItem(
                    label: status.label,
                    value: status.value,
                    icon: status.icon,
                    color: status.color,
                    markerText: status.label,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

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

class AdminPostAnalyticPage extends StatelessWidget {
  const AdminPostAnalyticPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminPostAnalyticViewModel(
        getStatisticsUseCase: sl<GetAdminPostAnalyticStatisticsUseCase>(),
      ),
      child: const _AdminPostAnalyticView(),
    );
  }
}

class _AdminPostAnalyticView extends StatefulWidget {
  const _AdminPostAnalyticView();

  @override
  State<_AdminPostAnalyticView> createState() => _AdminPostAnalyticViewState();
}

class _AdminPostAnalyticViewState extends State<_AdminPostAnalyticView> {
  late final PageController _sectionController;
  final DateFormat _summaryDateFormatter = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _sectionController = PageController();
  }

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  @override
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

  Widget _buildBody(AdminPostAnalyticViewModel viewModel) {
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
            AdminStatisticDateRangeBar(
              dateRange: statistics.dateRange,
              onTap: () => _pickDateRange(viewModel),
            ),
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
            const SizedBox(height: AppSpacing.lg),
            AdminLineChartCard(
              title: 'Posted Vs Day',
              values: statistics.dailyPosts,
            ),
            const SizedBox(height: AppSpacing.lg),
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

  Future<void> _pickDateRange(AdminPostAnalyticViewModel viewModel) async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2026, 12, 31),
      initialDateRange: DateTimeRange(
        start: viewModel.startDate ?? DateTime(2024, 5, 12),
        end: viewModel.endDate ?? DateTime(2024, 5, 18),
      ),
    );

    if (pickedRange == null || !mounted) return;
    await viewModel.selectDateRange(
      startDate: pickedRange.start,
      endDate: pickedRange.end,
    );
  }
}

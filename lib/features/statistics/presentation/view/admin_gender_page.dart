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

class AdminGenderPage extends StatelessWidget {
  const AdminGenderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminGenderViewModel(
        getStatisticsUseCase: sl<GetAdminGenderStatisticsUseCase>(),
      ),
      child: const _AdminGenderView(),
    );
  }
}

class _AdminGenderView extends StatefulWidget {
  const _AdminGenderView();

  @override
  State<_AdminGenderView> createState() => _AdminGenderViewState();
}

class _AdminGenderViewState extends State<_AdminGenderView> {
  @override
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

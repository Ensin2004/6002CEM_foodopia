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

class AdminDietaryPreferencePage extends StatelessWidget {
  const AdminDietaryPreferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminDietaryPreferenceViewModel(
        getStatisticsUseCase: sl<GetAdminDietaryPreferenceStatisticsUseCase>(),
      ),
      child: const _AdminDietaryPreferenceView(),
    );
  }
}

class _AdminDietaryPreferenceView extends StatefulWidget {
  const _AdminDietaryPreferenceView();

  @override
  State<_AdminDietaryPreferenceView> createState() =>
      _AdminDietaryPreferenceViewState();
}

class _AdminDietaryPreferenceViewState
    extends State<_AdminDietaryPreferenceView> {
  @override
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

  Widget _buildBody(AdminDietaryPreferenceViewModel viewModel) {
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
                    title: 'Top Preference',
                    value: statistics.topPreference,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AdminPreferencePieCard(
              totalUsers: statistics.totalUsers,
              preferences: statistics.preferences,
            ),
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

  Future<void> _pickDateRange(AdminDietaryPreferenceViewModel viewModel) async {
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

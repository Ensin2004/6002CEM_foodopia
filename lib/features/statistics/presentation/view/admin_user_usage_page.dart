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

class AdminUserUsagePage extends StatelessWidget {
  const AdminUserUsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminUserUsageViewModel(
        getStatisticsUseCase: sl<GetAdminUserUsageStatisticsUseCase>(),
      ),
      child: const _AdminUserUsageView(),
    );
  }
}

class _AdminUserUsageView extends StatefulWidget {
  const _AdminUserUsageView();

  @override
  State<_AdminUserUsageView> createState() => _AdminUserUsageViewState();
}

class _AdminUserUsageViewState extends State<_AdminUserUsageView> {
  @override
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

class _MonthlyUserChart extends StatelessWidget {
  final List<AdminMonthlyUserStatistic> months;

  const _MonthlyUserChart({required this.months});

  @override
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

class _MonthlyUserBreakdown extends StatelessWidget {
  final List<AdminMonthlyUserStatistic> months;

  const _MonthlyUserBreakdown({required this.months});

  @override
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

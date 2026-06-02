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
import '../../domain/usecases/get_admin_usage_forecast_statistics_usecase.dart';
import '../viewmodel/admin_usage_forecast_viewmodel.dart';
import '../widgets/admin_statistics_detail_widgets.dart';
import '../widgets/statistics_line_chart.dart';
import '../widgets/statistics_page_helpers.dart';

class AdminUsageForecastPage extends StatelessWidget {
  const AdminUsageForecastPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminUsageForecastViewModel(
        getStatisticsUseCase: sl<GetAdminUsageForecastStatisticsUseCase>(),
      ),
      child: const _AdminUsageForecastView(),
    );
  }
}

class _AdminUsageForecastView extends StatefulWidget {
  const _AdminUsageForecastView();

  @override
  State<_AdminUsageForecastView> createState() =>
      _AdminUsageForecastViewState();
}

class _AdminUsageForecastViewState extends State<_AdminUsageForecastView> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminUsageForecastViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Usage Forecast',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(viewModel),
    );
  }

  Widget _buildBody(AdminUsageForecastViewModel viewModel) {
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading usage forecast...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load usage forecast',
        onRetry: viewModel.loadStatistics,
      );
    }

    AdminMonthlyUserStatistic? prediction;
    for (final month in statistics.monthlyUsers) {
      if (month.isPrediction) {
        prediction = month;
        break;
      }
    }
    final actualMonths = statistics.monthlyUsers
        .where((month) => !month.isPrediction)
        .toList(growable: false);
    final confidence = _confidenceLabel(actualMonths);

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
                    title: 'Current New User',
                    value: statistics.totalUsers.toString(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AdminStatisticSummaryTile(
                    icon: Icons.trending_up,
                    title: 'Predict Next Month',
                    value: prediction == null
                        ? '-'
                        : prediction.newUsers.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _ForecastResultCard(prediction: prediction, confidence: confidence),
            const SizedBox(height: AppSpacing.lg),
            _ForecastChart(months: statistics.monthlyUsers),
            const SizedBox(height: AppSpacing.lg),
            _ForecastBreakdown(
              months: statistics.monthlyUsers,
              confidence: confidence,
            ),
          ],
        ),
      ),
    );
  }

  String _confidenceLabel(List<AdminMonthlyUserStatistic> months) {
    final totalUsers = months.fold<int>(0, (sum, item) => sum + item.newUsers);
    if (totalUsers < 7) return 'Low confidence';
    if (totalUsers < 20) return 'Medium confidence';
    return 'High confidence';
  }

  Future<void> _pickDateRange(AdminUsageForecastViewModel viewModel) async {
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

class _ForecastResultCard extends StatelessWidget {
  final AdminMonthlyUserStatistic? prediction;
  final String confidence;

  const _ForecastResultCard({
    required this.prediction,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMMM yyyy');
    final month = prediction == null
        ? '-'
        : formatter.format(prediction!.month);
    final value = prediction?.newUsers ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F0),
        border: Border.all(color: const Color(0xFFC8EBD7)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const _SoftIcon(icon: Icons.insights_outlined),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forecast Result',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$value new users expected in $month',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            confidence,
            maxLines: 2,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastChart extends StatelessWidget {
  final List<AdminMonthlyUserStatistic> months;

  const _ForecastChart({required this.months});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM yy');
    return _SectionCard(
      title: 'Actual Vs Predicted User Growth',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: (months.length * 70.0).clamp(
            MediaQuery.sizeOf(context).width - 52,
            double.infinity,
          ),
          child: StatisticsLineChart(
            points: months
                .map(
                  (month) => StatisticsLineChartPoint(
                    label: month.isPrediction
                        ? 'Next'
                        : formatter.format(month.month),
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

class _ForecastBreakdown extends StatelessWidget {
  final List<AdminMonthlyUserStatistic> months;
  final String confidence;

  const _ForecastBreakdown({required this.months, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMMM yyyy');

    return _SectionCard(
      title: 'Forecast Breakdown',
      alignTitleLeft: true,
      child: Column(
        children: months.map((month) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    month.isPrediction
                        ? 'Prediction - ${formatter.format(month.month)}'
                        : formatter.format(month.month),
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
                      '${month.newUsers} user',
                      style: context.text.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    if (month.isPrediction)
                      Text(
                        confidence,
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
        }).toList(),
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

class _SoftIcon extends StatelessWidget {
  final IconData icon;

  const _SoftIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

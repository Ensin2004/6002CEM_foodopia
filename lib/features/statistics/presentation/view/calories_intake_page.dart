import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/entities/calories_intake_statistics.dart';
import '../../domain/usecases/get_calories_intake_statistics_usecase.dart';
import '../viewmodel/calories_intake_viewmodel.dart';
import '../widgets/statistics_page_helpers.dart';
import '../widgets/statistics_line_chart.dart';

class CaloriesIntakePage extends StatelessWidget {
  const CaloriesIntakePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaloriesIntakeViewModel(
        getStatisticsUseCase: sl<GetCaloriesIntakeStatisticsUseCase>(),
      ),
      child: const _CaloriesIntakeView(),
    );
  }
}

class _CaloriesIntakeView extends StatefulWidget {
  const _CaloriesIntakeView();

  @override
  State<_CaloriesIntakeView> createState() => _CaloriesIntakeViewState();
}

class _CaloriesIntakeViewState extends State<_CaloriesIntakeView> {
  int _selectedChart = 0;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CaloriesIntakeViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Daily Calories Intake',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, CaloriesIntakeViewModel viewModel) {
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(inline: true, message: 'Loading calories...');
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return _CaloriesError(
        message: viewModel.errorMessage ?? 'Unable to load calories intake',
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
            StatisticsDateRangeBar(
              dateRange: statistics.dateRange,
              onTap: () => pickStatisticsDateRange(
                context: context,
                startDate: viewModel.startDate,
                endDate: viewModel.endDate,
                onPicked: (startDate, endDate) => viewModel.selectDateRange(
                  startDate: startDate,
                  endDate: endDate,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.room_service_outlined,
                    title: 'Total Meal',
                    value: statistics.totalMeal.toString(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.favorite_border,
                    title: _averageTitle,
                    value: _averageValue(statistics, viewModel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _CaloriesMetricPager(
              statistics: statistics,
              viewModel: viewModel,
              selectedChart: _selectedChart,
              onChartChanged: (index) => setState(() {
                _selectedChart = index;
              }),
            ),
          ],
        ),
      ),
    );
  }

  String get _averageTitle {
    switch (_selectedChart) {
      case 1:
        return 'Average Carbohydrate';
      case 2:
        return 'Average Protein';
      case 3:
        return 'Average Fat';
      default:
        return 'Average Calories';
    }
  }

  String _averageValue(
    CaloriesIntakeStatistics statistics,
    CaloriesIntakeViewModel viewModel,
  ) {
    switch (_selectedChart) {
      case 1:
        return '${_averageInt(statistics.dailyIntakes, (day) => day.totalCarbohydrateGram)} g';
      case 2:
        return '${_averageInt(statistics.dailyIntakes, (day) => day.totalProteinGram)} g';
      case 3:
        return '${_averageInt(statistics.dailyIntakes, (day) => day.totalFatGram)} g';
      default:
        return '${viewModel.convertCalories(statistics.averageCaloriesKcal)} ${viewModel.unitLabel}';
    }
  }

  int _averageInt(
    List<CaloriesDailyIntake> days,
    int Function(CaloriesDailyIntake day) valueForDay,
  ) {
    if (days.isEmpty) return 0;
    final total = days.fold<int>(0, (sum, day) => sum + valueForDay(day));
    return (total / days.length).round();
  }
}

class DateRangeBar extends StatelessWidget {
  final String dateRange;

  const DateRangeBar({super.key, required this.dateRange});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Date Range:',
          style: context.text.bodySmall?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dateRange,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_month, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _SoftIcon(icon: icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: context.text.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CaloriesChartMetric {
  final String title;
  final String breakdownTitle;
  final String unit;
  final int Function(CaloriesDailyIntake day) valueForDay;
  final int Function(CaloriesMealItem meal) valueForMeal;
  final bool allowUnitChange;

  const _CaloriesChartMetric({
    required this.title,
    required this.breakdownTitle,
    required this.unit,
    required this.valueForDay,
    required this.valueForMeal,
    this.allowUnitChange = false,
  });
}

class _CaloriesMetricPager extends StatelessWidget {
  final CaloriesIntakeStatistics statistics;
  final CaloriesIntakeViewModel viewModel;
  final int selectedChart;
  final ValueChanged<int> onChartChanged;

  const _CaloriesMetricPager({
    required this.statistics,
    required this.viewModel,
    required this.selectedChart,
    required this.onChartChanged,
  });

  List<_CaloriesChartMetric> get _metrics => [
    _CaloriesChartMetric(
      title: 'Calories Intake Vs Day',
      breakdownTitle: 'Calories Breakdown',
      unit: viewModel.unitLabel,
      valueForDay: (day) => viewModel.convertCalories(day.totalCaloriesKcal),
      valueForMeal: (meal) => viewModel.convertCalories(meal.caloriesKcal),
      allowUnitChange: true,
    ),
    const _CaloriesChartMetric(
      title: 'Carbohydrate Intake Vs Day',
      breakdownTitle: 'Carbohydrate Breakdown',
      unit: 'g',
      valueForDay: _carbohydrateForDay,
      valueForMeal: _carbohydrateForMeal,
    ),
    const _CaloriesChartMetric(
      title: 'Protein Intake Vs Day',
      breakdownTitle: 'Protein Breakdown',
      unit: 'g',
      valueForDay: _proteinForDay,
      valueForMeal: _proteinForMeal,
    ),
    const _CaloriesChartMetric(
      title: 'Fat Intake Vs Day',
      breakdownTitle: 'Fat Breakdown',
      unit: 'g',
      valueForDay: _fatForDay,
      valueForMeal: _fatForMeal,
    ),
  ];

  static int _carbohydrateForDay(CaloriesDailyIntake day) {
    return day.totalCarbohydrateGram;
  }

  static int _proteinForDay(CaloriesDailyIntake day) {
    return day.totalProteinGram;
  }

  static int _fatForDay(CaloriesDailyIntake day) {
    return day.totalFatGram;
  }

  static int _carbohydrateForMeal(CaloriesMealItem meal) {
    return meal.carbohydrateGram;
  }

  static int _proteinForMeal(CaloriesMealItem meal) {
    return meal.proteinGram;
  }

  static int _fatForMeal(CaloriesMealItem meal) {
    return meal.fatGram;
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics;
    final metric = metrics[selectedChart];

    return Column(
      children: [
        _MetricTabs(selectedIndex: selectedChart, onSelected: onChartChanged),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) => _handleSwipe(details, metrics),
          child: Column(
            children: [
              _CaloriesChartCard(statistics: statistics, metric: metric),
              const SizedBox(height: AppSpacing.lg),
              _CaloriesBreakdown(
                dailyIntakes: statistics.dailyIntakes,
                expandedIndex: viewModel.expandedIndex,
                metric: metric,
                onUnitChanged: viewModel.setDisplayUnit,
                onToggle: viewModel.toggleDay,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MetricDots(count: metrics.length, selectedIndex: selectedChart),
      ],
    );
  }

  void _handleSwipe(
    DragEndDetails details,
    List<_CaloriesChartMetric> metrics,
  ) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 220) return;

    final nextIndex = velocity < 0 ? selectedChart + 1 : selectedChart - 1;
    if (nextIndex < 0 || nextIndex >= metrics.length) return;
    onChartChanged(nextIndex);
  }
}

class _MetricTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _MetricTabs({required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const labels = ['Calories', 'Carbohydrate', 'Protein', 'Fat'];
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MetricDots extends StatelessWidget {
  final int count;
  final int selectedIndex;

  const _MetricDots({required this.count, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = index == selectedIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 16 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _CaloriesChartCard extends StatelessWidget {
  final CaloriesIntakeStatistics statistics;
  final _CaloriesChartMetric metric;

  const _CaloriesChartCard({required this.statistics, required this.metric});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d');

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            metric.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = (statistics.dailyIntakes.length * 52.0).clamp(
                constraints.maxWidth,
                double.infinity,
              );

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  child: StatisticsLineChart(
                    height: 220,
                    points: statistics.dailyIntakes
                        .map(
                          (day) => StatisticsLineChartPoint(
                            label: formatter.format(day.date),
                            value: metric.valueForDay(day),
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            metric.unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _CaloriesBreakdown extends StatelessWidget {
  final List<CaloriesDailyIntake> dailyIntakes;
  final int? expandedIndex;
  final _CaloriesChartMetric metric;
  final ValueChanged<CaloriesDisplayUnit> onUnitChanged;
  final ValueChanged<int> onToggle;

  const _CaloriesBreakdown({
    required this.dailyIntakes,
    required this.expandedIndex,
    required this.metric,
    required this.onUnitChanged,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.breakdownTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              if (metric.allowUnitChange)
                _UnitButton(
                  displayUnit: metric.unit == 'kcal'
                      ? CaloriesDisplayUnit.kcal
                      : CaloriesDisplayUnit.cal,
                  onUnitChanged: onUnitChanged,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: List.generate(dailyIntakes.length, (index) {
                final day = dailyIntakes[index];
                final isExpanded = expandedIndex == index;
                return _DailyCaloriesSection(
                  day: day,
                  isExpanded: isExpanded,
                  showDivider: index != dailyIntakes.length - 1,
                  unitLabel: metric.unit,
                  onTap: () => onToggle(index),
                  valueForMeal: metric.valueForMeal,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitButton extends StatelessWidget {
  final CaloriesDisplayUnit displayUnit;
  final ValueChanged<CaloriesDisplayUnit> onUnitChanged;

  const _UnitButton({required this.displayUnit, required this.onUnitChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CaloriesDisplayUnit>(
      tooltip: 'Unit',
      initialValue: displayUnit,
      onSelected: onUnitChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: CaloriesDisplayUnit.kcal, child: Text('kcal')),
        PopupMenuItem(value: CaloriesDisplayUnit.cal, child: Text('cal')),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayUnit == CaloriesDisplayUnit.kcal ? 'kcal' : 'cal',
            style: context.text.bodySmall?.copyWith(
              color: Colors.black,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.tune, size: 17),
        ],
      ),
    );
  }
}

class _DailyCaloriesSection extends StatelessWidget {
  final CaloriesDailyIntake day;
  final bool isExpanded;
  final bool showDivider;
  final String unitLabel;
  final VoidCallback onTap;
  final int Function(CaloriesMealItem meal) valueForMeal;

  const _DailyCaloriesSection({
    required this.day,
    required this.isExpanded,
    required this.showDivider,
    required this.unitLabel,
    required this.onTap,
    required this.valueForMeal,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('MMM d, yyyy').format(day.date);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                const _SoftIcon(icon: Icons.event_available),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Total Taken',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  day.totalPlannedMeal.toString(),
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...day.meals.map(
            (meal) => _CaloriesMealRow(
              meal: meal,
              unitLabel: unitLabel,
              valueForMeal: valueForMeal,
            ),
          ),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _CaloriesMealRow extends StatelessWidget {
  final CaloriesMealItem meal;
  final String unitLabel;
  final int Function(CaloriesMealItem meal) valueForMeal;

  const _CaloriesMealRow({
    required this.meal,
    required this.unitLabel,
    required this.valueForMeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 7,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFECE7CF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD7C98D)),
            ),
            child: Icon(meal.icon, color: const Color(0xFF6D642C), size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              meal.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${valueForMeal(meal)} $unitLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
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
        color: Color(0xFFEAF8F0),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary, size: 20),
    );
  }
}

class _CaloriesError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _CaloriesError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', height: 140),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try Again',
                style: context.text.labelLarge?.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

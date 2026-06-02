import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/tabs/app_pill_segmented_control.dart';
import '../../domain/entities/calories_intake_statistics.dart';
import '../../domain/usecases/get_admin_nutrient_insight_statistics_usecase.dart';
import '../viewmodel/admin_nutrient_insight_viewmodel.dart';
import '../widgets/statistics_line_chart.dart';
import '../widgets/statistics_page_helpers.dart';

class AdminNutrientInsightPage extends StatelessWidget {
  const AdminNutrientInsightPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminNutrientInsightViewModel(
        getStatisticsUseCase: sl<GetAdminNutrientInsightStatisticsUseCase>(),
      ),
      child: const _AdminNutrientInsightView(),
    );
  }
}

class _AdminNutrientInsightView extends StatefulWidget {
  const _AdminNutrientInsightView();

  @override
  State<_AdminNutrientInsightView> createState() =>
      _AdminNutrientInsightViewState();
}

class _AdminNutrientInsightViewState extends State<_AdminNutrientInsightView> {
  int _selectedChart = 0;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminNutrientInsightViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Nutrient Insight',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(viewModel),
    );
  }

  Widget _buildBody(AdminNutrientInsightViewModel viewModel) {
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading nutrient insight...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load nutrient insight',
        onRetry: viewModel.loadStatistics,
      );
    }

    final prediction = _predictionForSelectedMetric(statistics, viewModel);

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
                    title: 'Total Planned Meal',
                    value: statistics.totalMeal.toString(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.insights_outlined,
                    title: 'Predict Next Month',
                    value: '${prediction.value} ${prediction.unit}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _PredictionNote(prediction: prediction),
            const SizedBox(height: AppSpacing.lg),
            _NutrientMetricPager(
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

  _NutrientPrediction _predictionForSelectedMetric(
    CaloriesIntakeStatistics statistics,
    AdminNutrientInsightViewModel viewModel,
  ) {
    final metrics = _NutrientMetricPager.metrics(viewModel);
    final metric = metrics[_selectedChart];
    final monthly = <DateTime, List<CaloriesDailyIntake>>{};
    for (final day in statistics.dailyIntakes) {
      final month = DateTime(day.date.year, day.date.month);
      monthly.putIfAbsent(month, () => <CaloriesDailyIntake>[]).add(day);
    }
    final values = monthly.entries.map((entry) {
      final days = entry.value;
      final total = days.fold<int>(
        0,
        (sum, day) => sum + metric.valueForDay(day),
      );
      return days.isEmpty ? 0 : (total / days.length).round();
    }).toList();
    final predicted = _predictNext(values);
    final confidence = statistics.totalMeal < 7
        ? 'Low confidence'
        : statistics.totalMeal < 20
        ? 'Medium confidence'
        : 'High confidence';

    return _NutrientPrediction(
      title: metric.title.replaceAll(' Vs Day', ''),
      value: predicted,
      unit: metric.unit,
      confidence: confidence,
    );
  }

  int _predictNext(List<int> values) {
    if (values.isEmpty) return 0;
    if (values.length == 1) return values.first;
    var totalChange = 0;
    for (var index = 1; index < values.length; index++) {
      totalChange += values[index] - values[index - 1];
    }
    final averageChange = totalChange / (values.length - 1);
    return (values.last + averageChange).round().clamp(0, 999999).toInt();
  }
}

class _NutrientPrediction {
  final String title;
  final int value;
  final String unit;
  final String confidence;

  const _NutrientPrediction({
    required this.title,
    required this.value,
    required this.unit,
    required this.confidence,
  });
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _NutrientChartMetric {
  final String title;
  final String breakdownTitle;
  final String unit;
  final int Function(CaloriesDailyIntake day) valueForDay;
  final int Function(CaloriesMealItem meal) valueForMeal;
  final bool allowUnitChange;

  const _NutrientChartMetric({
    required this.title,
    required this.breakdownTitle,
    required this.unit,
    required this.valueForDay,
    required this.valueForMeal,
    this.allowUnitChange = false,
  });
}

class _NutrientMetricPager extends StatelessWidget {
  final CaloriesIntakeStatistics statistics;
  final AdminNutrientInsightViewModel viewModel;
  final int selectedChart;
  final ValueChanged<int> onChartChanged;

  const _NutrientMetricPager({
    required this.statistics,
    required this.viewModel,
    required this.selectedChart,
    required this.onChartChanged,
  });

  static List<_NutrientChartMetric> metrics(
    AdminNutrientInsightViewModel viewModel,
  ) {
    return [
      _NutrientChartMetric(
        title: 'Calories Insight Vs Day',
        breakdownTitle: 'Calories Breakdown',
        unit: viewModel.unitLabel,
        valueForDay: (day) => viewModel.convertCalories(day.totalCaloriesKcal),
        valueForMeal: (meal) => viewModel.convertCalories(meal.caloriesKcal),
        allowUnitChange: true,
      ),
      const _NutrientChartMetric(
        title: 'Carbohydrate Insight Vs Day',
        breakdownTitle: 'Carbohydrate Breakdown',
        unit: 'g',
        valueForDay: _carbohydrateForDay,
        valueForMeal: _carbohydrateForMeal,
      ),
      const _NutrientChartMetric(
        title: 'Protein Insight Vs Day',
        breakdownTitle: 'Protein Breakdown',
        unit: 'g',
        valueForDay: _proteinForDay,
        valueForMeal: _proteinForMeal,
      ),
      const _NutrientChartMetric(
        title: 'Fat Insight Vs Day',
        breakdownTitle: 'Fat Breakdown',
        unit: 'g',
        valueForDay: _fatForDay,
        valueForMeal: _fatForMeal,
      ),
    ];
  }

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
    final chartMetrics = metrics(viewModel);
    final metric = chartMetrics[selectedChart];

    return Column(
      children: [
        AppPillSegmentedControl(
          labels: const ['Calories', 'Carbohydrate', 'Protein', 'Fat'],
          selectedIndex: selectedChart,
          onChanged: onChartChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) => _handleSwipe(details, chartMetrics),
          child: Column(
            children: [
              _NutrientChartCard(statistics: statistics, metric: metric),
              const SizedBox(height: AppSpacing.lg),
              _NutrientBreakdown(
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
        _MetricDots(count: chartMetrics.length, selectedIndex: selectedChart),
      ],
    );
  }

  void _handleSwipe(
    DragEndDetails details,
    List<_NutrientChartMetric> chartMetrics,
  ) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 220) return;

    final nextIndex = velocity < 0 ? selectedChart + 1 : selectedChart - 1;
    if (nextIndex < 0 || nextIndex >= chartMetrics.length) return;
    onChartChanged(nextIndex);
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

class _NutrientChartCard extends StatelessWidget {
  final CaloriesIntakeStatistics statistics;
  final _NutrientChartMetric metric;

  const _NutrientChartCard({required this.statistics, required this.metric});

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

class _NutrientBreakdown extends StatelessWidget {
  final List<CaloriesDailyIntake> dailyIntakes;
  final int? expandedIndex;
  final _NutrientChartMetric metric;
  final ValueChanged<CaloriesDisplayUnit> onUnitChanged;
  final ValueChanged<int> onToggle;

  const _NutrientBreakdown({
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
                return _DailyNutrientSection(
                  day: day,
                  isExpanded: expandedIndex == index,
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

class _DailyNutrientSection extends StatelessWidget {
  final CaloriesDailyIntake day;
  final bool isExpanded;
  final bool showDivider;
  final String unitLabel;
  final VoidCallback onTap;
  final int Function(CaloriesMealItem meal) valueForMeal;

  const _DailyNutrientSection({
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
                        'Total Planned',
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
            (meal) => _NutrientMealRow(
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

class _NutrientMealRow extends StatelessWidget {
  final CaloriesMealItem meal;
  final String unitLabel;
  final int Function(CaloriesMealItem meal) valueForMeal;

  const _NutrientMealRow({
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
          _FoodIcon(icon: meal.icon, imageUrl: meal.imageUrl),
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

class _PredictionNote extends StatelessWidget {
  final _NutrientPrediction prediction;

  const _PredictionNote({required this.prediction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F0),
        border: Border.all(color: const Color(0xFFC8EBD7)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const _SoftIcon(icon: Icons.trending_up),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '${prediction.title} is estimated at ${prediction.value} ${prediction.unit} next month.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            prediction.confidence,
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

class _FoodIcon extends StatelessWidget {
  final IconData icon;
  final String? imageUrl;

  const _FoodIcon({required this.icon, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    return Container(
      width: 32,
      height: 32,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFECE7CF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD7C98D)),
      ),
      child: url.isNotEmpty
          ? Image.network(
              url,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(icon, color: const Color(0xFF6D642C), size: 18),
            )
          : Icon(icon, color: const Color(0xFF6D642C), size: 18),
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

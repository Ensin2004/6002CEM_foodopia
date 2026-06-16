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

/// Admin report for system-wide nutrient trends and predictions.
class AdminNutrientInsightPage extends StatelessWidget {
  const AdminNutrientInsightPage({super.key});

  @override
  // Build the admin nutrient insight page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  Widget build(BuildContext context) {
    // The ViewModel controls filtering, units, and expanded daily details.
    return ChangeNotifierProvider(
      create: (_) => AdminNutrientInsightViewModel(
        getStatisticsUseCase: sl<GetAdminNutrientInsightStatisticsUseCase>(),
      ),
      child: const _AdminNutrientInsightView(),
    );
  }
}

// This widget builds the main content for the admin nutrient insight view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
class _AdminNutrientInsightView extends StatefulWidget {
  const _AdminNutrientInsightView();

  @override
  State<_AdminNutrientInsightView> createState() =>
      _AdminNutrientInsightViewState();
}

// This state object manages the changing parts of the admin nutrient insight view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
class _AdminNutrientInsightViewState extends State<_AdminNutrientInsightView> {
  int _selectedChart = 0;

  @override
  // Build the admin nutrient insight view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
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
    // Wait for daily nutrient values before creating insights.
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
            // A new period recalculates all nutrient charts and predictions.
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

  // Estimate the next value from the recent direction of the data.
  // This display forecast does not update any stored statistics.
  int _predictNext(List<int> values) {
    // Use the last two known values to find the most recent change.
    // Adding that change to the latest value creates the next estimate.
    // Negative predictions are prevented because nutrient totals cannot be less
    // than zero.
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

// This object keeps the values needed by the nutrient prediction together.
// It is only used to prepare display data for this page.
// No loading or database work happens inside this object.
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

// This small widget draws one summary tile.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
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
  // Build the visual layout for this summary tile.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
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

// This widget turns the report values into the nutrient chart metric.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
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

// This widget controls the nutrient metric pager used to move between report views.
// The selected index comes from the parent or ViewModel.
// User changes are sent back through the provided callback.
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
  // Build the nutrient metric pager with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
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

  // Convert the swipe or tap into a valid page index.
  // Store the index so tabs, content, and page dots stay matched.
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

// This widget controls the metric dots used to move between report views.
// The selected index comes from the parent or ViewModel.
// User changes are sent back through the provided callback.
class _MetricDots extends StatelessWidget {
  final int count;
  final int selectedIndex;

  const _MetricDots({required this.count, required this.selectedIndex});

  @override
  // Build the metric dots with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
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

// This widget turns the report values into the nutrient chart card.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
class _NutrientChartCard extends StatelessWidget {
  final CaloriesIntakeStatistics statistics;
  final _NutrientChartMetric metric;

  const _NutrientChartCard({required this.statistics, required this.metric});

  @override
  // Build the nutrient chart card from the values supplied by the parent.
  // Labels, scale, and spacing are prepared before the chart is displayed.
  // This method only handles presentation and does not change report data.
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
                  // ADMIN NUTRIENT LINE-CHART UI CALL STARTS HERE.
                  // The selected nutrient values are passed to the shared chart.
                  // Draws a line chart of the selected nutrient for each day.
                  // Link: AdminNutrientInsightPage -> StatisticsLineChart.
                  // Widget file: ../widgets/statistics_line_chart.dart.
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

// This widget displays the detailed nutrient breakdown.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
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
  // Build the visible rows for the nutrient breakdown.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
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

// This helper draws the reusable unit button.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
class _UnitButton extends StatelessWidget {
  final CaloriesDisplayUnit displayUnit;
  final ValueChanged<CaloriesDisplayUnit> onUnitChanged;

  const _UnitButton({required this.displayUnit, required this.onUnitChanged});

  @override
  // Build the visual layout for this unit button.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
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

// This widget represents one daily nutrient section in the report.
// It owns the header and the content that belongs to this group.
// The expanded state decides whether the detailed rows are visible.
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
  // Build the visible rows for the daily nutrient section.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
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

// This small widget draws one nutrient meal row.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
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
  // Build the visual layout for this nutrient meal row.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
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

// This object keeps the values needed by the prediction note together.
// It is only used to prepare display data for this page.
// No loading or database work happens inside this object.
class _PredictionNote extends StatelessWidget {
  final _NutrientPrediction prediction;

  const _PredictionNote({required this.prediction});

  @override
  // Build the prediction note with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
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

// This helper draws the reusable food icon.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
class _FoodIcon extends StatelessWidget {
  final IconData icon;
  final String? imageUrl;

  const _FoodIcon({required this.icon, this.imageUrl});

  @override
  // Build the visual layout for this food icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
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

// This helper draws the reusable soft icon.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
class _SoftIcon extends StatelessWidget {
  final IconData icon;

  const _SoftIcon({required this.icon});

  @override
  // Build the visual layout for this soft icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
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

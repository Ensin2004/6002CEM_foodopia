// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
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
import '../../domain/usecases/get_calories_intake_statistics_usecase.dart';
import '../viewmodel/calories_intake_viewmodel.dart';
import '../widgets/statistics_page_helpers.dart';
import '../widgets/statistics_recipe_media_thumbnail.dart';
import '../widgets/statistics_line_chart.dart';

/// Shows daily nutrient intake and optional prediction insights.
// Handles CaloriesIntakePage for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class CaloriesIntakePage extends StatelessWidget {
  final bool showInsight;

  const CaloriesIntakePage({super.key, this.showInsight = false});

  @override
  // Build the calories intake page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    // The same page is reused for normal intake and insight mode.
    return ChangeNotifierProvider(
      create: (_) => CaloriesIntakeViewModel(
        getStatisticsUseCase: sl<GetCaloriesIntakeStatisticsUseCase>(),
      ),
      child: _CaloriesIntakeView(showInsight: showInsight),
    );
  }
}

// This widget builds the main content for the calories intake view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
// Handles _CaloriesIntakeView for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _CaloriesIntakeView extends StatefulWidget {
  final bool showInsight;

  const _CaloriesIntakeView({required this.showInsight});

  // Handles createState for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  State<_CaloriesIntakeView> createState() => _CaloriesIntakeViewState();
}

// This state object manages the changing parts of the calories intake view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
// Handles _CaloriesIntakeViewState for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _CaloriesIntakeViewState extends State<_CaloriesIntakeView> {
  int _selectedChart = 0;

  @override
  // Build the calories intake view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    final viewModel = context.watch<CaloriesIntakeViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Daily Nutrient Intake',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  // Handles _buildBody for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget _buildBody(BuildContext context, CaloriesIntakeViewModel viewModel) {
    // Show the report only when its daily nutrient data is ready.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(inline: true, message: 'Loading nutrients...');
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return _CaloriesError(
        message: viewModel.errorMessage ?? 'Unable to load nutrient intake',
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
            // A new range reloads all nutrient totals and daily values.
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
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
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
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
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
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.lg),
            // Insight mode adds prediction content to the normal report.
            if (widget.showInsight) ...[
              _NutrientInsightNote(
                prediction: _predictionForSelectedMetric(statistics, viewModel),
              ),
              // Handles SizedBox for this part of the statistics page.
              // This makes the purpose clearer when reading or updating the code.
              const SizedBox(height: AppSpacing.lg),
            ],
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

  // Handles _averageTitle for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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

  // Calculate one average value from all visible daily records.
  // Empty data returns a safe zero instead of dividing by zero.
  // Handles _averageValue for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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

  // Calculate one average value from all visible daily records.
  // Empty data returns a safe zero instead of dividing by zero.
  // Handles _averageInt for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  int _averageInt(
    List<CaloriesDailyIntake> days,
    int Function(CaloriesDailyIntake day) valueForDay,
  ) {
    if (days.isEmpty) return 0;
    final total = days.fold<int>(0, (sum, day) => sum + valueForDay(day));
    return (total / days.length).round();
  }

  _NutrientPrediction _predictionForSelectedMetric(
    CaloriesIntakeStatistics statistics,
    CaloriesIntakeViewModel viewModel,
  ) {
    final metric = _metricForPrediction(viewModel);
    final monthly = <DateTime, List<CaloriesDailyIntake>>{};
    for (final day in statistics.dailyIntakes) {
      final month = DateTime(day.date.year, day.date.month);
      monthly.putIfAbsent(month, () => <CaloriesDailyIntake>[]).add(day);
    }
    final values = monthly.values.map((days) {
      final total = days.fold<int>(0, (sum, day) => sum + metric.value(day));
      return days.isEmpty ? 0 : (total / days.length).round();
    }).toList();

    return _NutrientPrediction(
      title: metric.title,
      value: _predictNext(values),
      unit: metric.unit,
      confidence: statistics.totalMeal < 7
          ? 'Low confidence'
          : statistics.totalMeal < 20
          ? 'Medium confidence'
          : 'High confidence',
    );
  }

  _PredictionMetric _metricForPrediction(CaloriesIntakeViewModel viewModel) {
    switch (_selectedChart) {
      case 1:
        return _PredictionMetric(
          title: 'Carbohydrate intake',
          unit: 'g',
          value: (day) => day.totalCarbohydrateGram,
        );
      case 2:
        return _PredictionMetric(
          title: 'Protein intake',
          unit: 'g',
          value: (day) => day.totalProteinGram,
        );
      case 3:
        return _PredictionMetric(
          title: 'Fat intake',
          unit: 'g',
          value: (day) => day.totalFatGram,
        );
      default:
        return _PredictionMetric(
          title: 'Calories intake',
          unit: viewModel.unitLabel,
          value: (day) => viewModel.convertCalories(day.totalCaloriesKcal),
        );
    }
  }

  // Estimate the next value from the recent direction of the data.
  // This display forecast does not update any stored statistics.
  // Handles _predictNext for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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

// This object keeps the values needed by the prediction metric together.
// It is only used to prepare display data for this page.
// No loading or database work happens inside this object.
// Handles _PredictionMetric for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _PredictionMetric {
  final String title;
  final String unit;
  final int Function(CaloriesDailyIntake day) value;

  // Handles _PredictionMetric for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _PredictionMetric({
    required this.title,
    required this.unit,
    required this.value,
  });
}

// This object keeps the values needed by the nutrient prediction together.
// It is only used to prepare display data for this page.
// No loading or database work happens inside this object.
// Handles _NutrientPrediction for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _NutrientPrediction {
  final String title;
  final int value;
  final String unit;
  final String confidence;

  // Handles _NutrientPrediction for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _NutrientPrediction({
    required this.title,
    required this.value,
    required this.unit,
    required this.confidence,
  });
}

// This helper is responsible for the nutrient insight note part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
// Handles _NutrientInsightNote for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _NutrientInsightNote extends StatelessWidget {
  final _NutrientPrediction prediction;

  const _NutrientInsightNote({required this.prediction});

  @override
  // Build the nutrient insight note with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
          // Handles _SoftIcon for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
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
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
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

// This helper is responsible for the date range bar part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
// Handles DateRangeBar for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class DateRangeBar extends StatelessWidget {
  final String dateRange;

  const DateRangeBar({super.key, required this.dateRange});

  @override
  // Build the date range bar with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
        // Handles SizedBox for this part of the statistics page.
        // This makes the purpose clearer when reading or updating the code.
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
                // Handles Icon for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
                const Icon(Icons.calendar_month, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// This small widget draws one summary tile.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _SummaryTile for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  // Handles _SummaryTile for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  // Build the visual layout for this summary tile.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
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
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
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

// This widget turns the report values into the calories chart metric.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
// Handles _CaloriesChartMetric for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _CaloriesChartMetric {
  final String title;
  final String breakdownTitle;
  final String unit;
  final int Function(CaloriesDailyIntake day) valueForDay;
  final int Function(CaloriesMealItem meal) valueForMeal;
  final bool allowUnitChange;

  // Handles _CaloriesChartMetric for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _CaloriesChartMetric({
    required this.title,
    required this.breakdownTitle,
    required this.unit,
    required this.valueForDay,
    required this.valueForMeal,
    this.allowUnitChange = false,
  });
}

// This widget controls the calories metric pager used to move between report views.
// The selected index comes from the parent or ViewModel.
// User changes are sent back through the provided callback.
// Handles _CaloriesMetricPager for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _CaloriesMetricPager extends StatelessWidget {
  final CaloriesIntakeStatistics statistics;
  final CaloriesIntakeViewModel viewModel;
  final int selectedChart;
  final ValueChanged<int> onChartChanged;

  // Handles _CaloriesMetricPager for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _CaloriesMetricPager({
    required this.statistics,
    required this.viewModel,
    required this.selectedChart,
    required this.onChartChanged,
  });

  // Handles _metrics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  List<_CaloriesChartMetric> get _metrics => [
    _CaloriesChartMetric(
      title: 'Calories Intake Vs Day',
      breakdownTitle: 'Calories Breakdown',
      unit: viewModel.unitLabel,
      valueForDay: (day) => viewModel.convertCalories(day.totalCaloriesKcal),
      valueForMeal: (meal) => viewModel.convertCalories(meal.caloriesKcal),
      allowUnitChange: true,
    ),
    // Handles _CaloriesChartMetric for this part of the statistics page.
    // This makes the purpose clearer when reading or updating the code.
    const _CaloriesChartMetric(
      title: 'Carbohydrate Intake Vs Day',
      breakdownTitle: 'Carbohydrate Breakdown',
      unit: 'g',
      valueForDay: _carbohydrateForDay,
      valueForMeal: _carbohydrateForMeal,
    ),
    // Handles _CaloriesChartMetric for this part of the statistics page.
    // This makes the purpose clearer when reading or updating the code.
    const _CaloriesChartMetric(
      title: 'Protein Intake Vs Day',
      breakdownTitle: 'Protein Breakdown',
      unit: 'g',
      valueForDay: _proteinForDay,
      valueForMeal: _proteinForMeal,
    ),
    // Handles _CaloriesChartMetric for this part of the statistics page.
    // This makes the purpose clearer when reading or updating the code.
    const _CaloriesChartMetric(
      title: 'Fat Intake Vs Day',
      breakdownTitle: 'Fat Breakdown',
      unit: 'g',
      valueForDay: _fatForDay,
      valueForMeal: _fatForMeal,
    ),
  ];

  // Handles _carbohydrateForDay for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  static int _carbohydrateForDay(CaloriesDailyIntake day) {
    return day.totalCarbohydrateGram;
  }

  // Handles _proteinForDay for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  static int _proteinForDay(CaloriesDailyIntake day) {
    return day.totalProteinGram;
  }

  // Handles _fatForDay for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  static int _fatForDay(CaloriesDailyIntake day) {
    return day.totalFatGram;
  }

  // Handles _carbohydrateForMeal for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  static int _carbohydrateForMeal(CaloriesMealItem meal) {
    return meal.carbohydrateGram;
  }

  // Handles _proteinForMeal for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  static int _proteinForMeal(CaloriesMealItem meal) {
    return meal.proteinGram;
  }

  // Handles _fatForMeal for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  static int _fatForMeal(CaloriesMealItem meal) {
    return meal.fatGram;
  }

  @override
  // Build the calories metric pager with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    final metrics = _metrics;
    final metric = metrics[selectedChart];

    return Column(
      children: [
        _MetricTabs(selectedIndex: selectedChart, onSelected: onChartChanged),
        // Handles SizedBox for this part of the statistics page.
        // This makes the purpose clearer when reading or updating the code.
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) => _handleSwipe(details, metrics),
          child: Column(
            children: [
              _CaloriesChartCard(statistics: statistics, metric: metric),
              // Handles SizedBox for this part of the statistics page.
              // This makes the purpose clearer when reading or updating the code.
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
        // Handles SizedBox for this part of the statistics page.
        // This makes the purpose clearer when reading or updating the code.
        const SizedBox(height: AppSpacing.sm),
        _MetricDots(count: metrics.length, selectedIndex: selectedChart),
      ],
    );
  }

  // Convert the swipe or tap into a valid page index.
  // Store the index so tabs, content, and page dots stay matched.
  // Handles _handleSwipe for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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

// This widget controls the metric tabs used to move between report views.
// The selected index comes from the parent or ViewModel.
// User changes are sent back through the provided callback.
// Handles _MetricTabs for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _MetricTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  // Handles _MetricTabs for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _MetricTabs({required this.selectedIndex, required this.onSelected});

  @override
  // Build the metric tabs with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    const labels = ['Calories', 'Carbohydrate', 'Protein', 'Fat'];
    return AppPillSegmentedControl(
      labels: labels,
      selectedIndex: selectedIndex,
      onChanged: onSelected,
    );
  }
}

// This widget controls the metric dots used to move between report views.
// The selected index comes from the parent or ViewModel.
// User changes are sent back through the provided callback.
// Handles _MetricDots for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _MetricDots extends StatelessWidget {
  final int count;
  final int selectedIndex;

  // Handles _MetricDots for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _MetricDots({required this.count, required this.selectedIndex});

  @override
  // Build the metric dots with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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

// This widget turns the report values into the calories chart card.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
// Handles _CaloriesChartCard for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _CaloriesChartCard extends StatelessWidget {
  final CaloriesIntakeStatistics statistics;
  final _CaloriesChartMetric metric;

  // Handles _CaloriesChartCard for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _CaloriesChartCard({required this.statistics, required this.metric});

  @override
  // Build the calories chart card from the values supplied by the parent.
  // Labels, scale, and spacing are prepared before the chart is displayed.
  // This method only handles presentation and does not change report data.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
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
                  // NUTRIENT-INTAKE LINE-CHART UI CALL STARTS HERE.
                  // The selected nutrient's daily values become chart points.
                  // Draws a line chart of daily calories, carbs, protein, or fat.
                  // Link: CaloriesIntakePage -> StatisticsLineChart.
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
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
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

// This widget displays the detailed calories breakdown.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
// Handles _CaloriesBreakdown for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _CaloriesBreakdown extends StatelessWidget {
  final List<CaloriesDailyIntake> dailyIntakes;
  final int? expandedIndex;
  final _CaloriesChartMetric metric;
  final ValueChanged<CaloriesDisplayUnit> onUnitChanged;
  final ValueChanged<int> onToggle;

  // Handles _CaloriesBreakdown for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _CaloriesBreakdown({
    required this.dailyIntakes,
    required this.expandedIndex,
    required this.metric,
    required this.onUnitChanged,
    required this.onToggle,
  });

  @override
  // Build the visible rows for the calories breakdown.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
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

// This helper draws the reusable unit button.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
// Handles _UnitButton for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _UnitButton extends StatelessWidget {
  final CaloriesDisplayUnit displayUnit;
  final ValueChanged<CaloriesDisplayUnit> onUnitChanged;

  // Handles _UnitButton for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _UnitButton({required this.displayUnit, required this.onUnitChanged});

  @override
  // Build the visual layout for this unit button.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
          const SizedBox(width: 3),
          const Icon(Icons.tune, size: 17),
        ],
      ),
    );
  }
}

// This widget represents one daily calories section in the report.
// It owns the header and the content that belongs to this group.
// The expanded state decides whether the detailed rows are visible.
// Handles _DailyCaloriesSection for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _DailyCaloriesSection extends StatelessWidget {
  final CaloriesDailyIntake day;
  final bool isExpanded;
  final bool showDivider;
  final String unitLabel;
  final VoidCallback onTap;
  final int Function(CaloriesMealItem meal) valueForMeal;

  // Handles _DailyCaloriesSection for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _DailyCaloriesSection({
    required this.day,
    required this.isExpanded,
    required this.showDivider,
    required this.unitLabel,
    required this.onTap,
    required this.valueForMeal,
  });

  @override
  // Build the visible rows for the daily calories section.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
                // Handles _SoftIcon for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
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
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
                const SizedBox(width: AppSpacing.sm),
                Text(
                  day.totalPlannedMeal.toString(),
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
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

// This small widget draws one calories meal row.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _CaloriesMealRow for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _CaloriesMealRow extends StatelessWidget {
  final CaloriesMealItem meal;
  final String unitLabel;
  final int Function(CaloriesMealItem meal) valueForMeal;

  // Handles _CaloriesMealRow for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _CaloriesMealRow({
    required this.meal,
    required this.unitLabel,
    required this.valueForMeal,
  });

  @override
  // Build the visual layout for this calories meal row.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
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
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
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

// This helper draws the reusable food icon.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
// Handles _FoodIcon for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _FoodIcon extends StatelessWidget {
  final IconData icon;
  final String? imageUrl;

  // Handles _FoodIcon for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _FoodIcon({required this.icon, this.imageUrl});

  @override
  // Build the visual layout for this food icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return StatisticsRecipeMediaThumbnail(
      mediaPath: imageUrl,
      fallbackIcon: icon,
      size: 32,
      backgroundColor: const Color(0xFFECE7CF),
      iconColor: const Color(0xFF6D642C),
      borderColor: const Color(0xFFD7C98D),
    );
  }
}

// This helper draws the reusable soft icon.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
// Handles _SoftIcon for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _SoftIcon extends StatelessWidget {
  final IconData icon;

  const _SoftIcon({required this.icon});

  @override
  // Build the visual layout for this soft icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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

// This widget shows the calories error when report data is unavailable.
// It explains the problem and gives the user a retry action.
// The retry callback asks the ViewModel to load the report again.
// Handles _CaloriesError for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _CaloriesError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  // Handles _CaloriesError for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _CaloriesError({required this.message, required this.onRetry});

  @override
  // Build the calories error with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', height: 140),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
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

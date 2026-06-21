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
import '../../domain/entities/calories_posted_statistics.dart';
import '../../domain/usecases/get_calories_posted_statistics_usecase.dart';
import '../viewmodel/calories_posted_viewmodel.dart';
import '../widgets/statistics_page_helpers.dart';
import '../widgets/statistics_recipe_media_thumbnail.dart';
import '../widgets/statistics_line_chart.dart';

/// Shows nutrients from posted recipes and optional prediction insights.
// Handles CaloriesPostedPage for this part of the statistics page.
class CaloriesPostedPage extends StatelessWidget {
  final bool showInsight;

  const CaloriesPostedPage({super.key, this.showInsight = false});

  @override
  // Build the calories posted page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    // The same ViewModel supports the report and its insight version.
    return ChangeNotifierProvider(
      create: (_) => CaloriesPostedViewModel(
        getStatisticsUseCase: sl<GetCaloriesPostedStatisticsUseCase>(),
      ),
      child: _CaloriesPostedView(showInsight: showInsight),
    );
  }
}

// This widget builds the main content for the calories posted view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
// Handles _CaloriesPostedView for this part of the statistics page.
class _CaloriesPostedView extends StatefulWidget {
  final bool showInsight;

  const _CaloriesPostedView({required this.showInsight});

  // Handles createState for this part of the statistics page.
  @override
  State<_CaloriesPostedView> createState() => _CaloriesPostedViewState();
}

// This state object manages the changing parts of the calories posted view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
// Handles _CaloriesPostedViewState for this part of the statistics page.
class _CaloriesPostedViewState extends State<_CaloriesPostedView> {
  int _selectedChart = 0;

  @override
  // Build the calories posted view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final viewModel = context.watch<CaloriesPostedViewModel>();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Nutrient Posted Meal',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  // Handles _buildBody for this part of the statistics page.
  Widget _buildBody(BuildContext context, CaloriesPostedViewModel viewModel) {
    // Show the report only when posted nutrient data is ready.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(inline: true, message: 'Loading nutrients...');
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load nutrients',
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
          children: [
            // A new range reloads totals calculated from posted recipes.
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
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.article_outlined,
                    title: 'Total Post',
                    value: statistics.totalPost.toString(),
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
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
            const SizedBox(height: AppSpacing.lg),
            // Insight mode adds future estimates above the normal report.
            if (widget.showInsight) ...[
              _PostedInsightNote(
                prediction: _predictionForSelectedMetric(statistics, viewModel),
              ),
              // Handles SizedBox for this part of the statistics page.
              const SizedBox(height: AppSpacing.lg),
            ],
            _PostedMetricPager(
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
  String _averageValue(
    CaloriesPostedStatistics statistics,
    CaloriesPostedViewModel viewModel,
  ) {
    switch (_selectedChart) {
      case 1:
        return '${statistics.averageCarbohydrateGram} g';
      case 2:
        return '${statistics.averageProteinGram} g';
      case 3:
        return '${statistics.averageFatGram} g';
      default:
        return '${viewModel.convertCalories(statistics.averageCaloriesKcal)} ${viewModel.unitLabel}';
    }
  }

  _PostedPrediction _predictionForSelectedMetric(
    CaloriesPostedStatistics statistics,
    CaloriesPostedViewModel viewModel,
  ) {
    final metric = _metricForPrediction(viewModel);
    final monthly = <DateTime, List<CaloriesPostedDay>>{};
    for (final day in statistics.dailyPosts) {
      final month = DateTime(day.date.year, day.date.month);
      monthly.putIfAbsent(month, () => <CaloriesPostedDay>[]).add(day);
    }
    final values = monthly.values.map((days) {
      final total = days.fold<int>(0, (sum, day) => sum + metric.value(day));
      return days.isEmpty ? 0 : (total / days.length).round();
    }).toList();

    return _PostedPrediction(
      title: metric.title,
      value: _predictNext(values),
      unit: metric.unit,
      confidence: statistics.totalPost < 7
          ? 'Low confidence'
          : statistics.totalPost < 20
          ? 'Medium confidence'
          : 'High confidence',
    );
  }

  _PostedPredictionMetric _metricForPrediction(
    CaloriesPostedViewModel viewModel,
  ) {
    switch (_selectedChart) {
      case 1:
        return _PostedPredictionMetric(
          title: 'Posted carbohydrate',
          unit: 'g',
          value: (day) => day.totalCarbohydrateGram,
        );
      case 2:
        return _PostedPredictionMetric(
          title: 'Posted protein',
          unit: 'g',
          value: (day) => day.totalProteinGram,
        );
      case 3:
        return _PostedPredictionMetric(
          title: 'Posted fat',
          unit: 'g',
          value: (day) => day.totalFatGram,
        );
      default:
        return _PostedPredictionMetric(
          title: 'Posted calories',
          unit: viewModel.unitLabel,
          value: (day) => viewModel.convertCalories(day.totalCaloriesKcal),
        );
    }
  }

  // Estimate the next value from the recent direction of the data.
  // This display forecast does not update any stored statistics.
  // Handles _predictNext for this part of the statistics page.
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

// This object keeps the values needed by the posted prediction metric together.
// It is only used to prepare display data for this page.
// No loading or database work happens inside this object.
// Handles _PostedPredictionMetric for this part of the statistics page.
class _PostedPredictionMetric {
  final String title;
  final String unit;
  final int Function(CaloriesPostedDay day) value;

  // Handles _PostedPredictionMetric for this part of the statistics page.
  const _PostedPredictionMetric({
    required this.title,
    required this.unit,
    required this.value,
  });
}

// This object keeps the values needed by the posted prediction together.
// It is only used to prepare display data for this page.
// No loading or database work happens inside this object.
// Handles _PostedPrediction for this part of the statistics page.
class _PostedPrediction {
  final String title;
  final int value;
  final String unit;
  final String confidence;

  // Handles _PostedPrediction for this part of the statistics page.
  const _PostedPrediction({
    required this.title,
    required this.value,
    required this.unit,
    required this.confidence,
  });
}

// This helper is responsible for the posted insight note part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
// Handles _PostedInsightNote for this part of the statistics page.
class _PostedInsightNote extends StatelessWidget {
  final _PostedPrediction prediction;

  const _PostedInsightNote({required this.prediction});

  @override
  // Build the posted insight note with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
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

// This widget turns the report values into the posted chart metric.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
// Handles _PostedChartMetric for this part of the statistics page.
class _PostedChartMetric {
  final String title;
  final String breakdownTitle;
  final String unit;
  final int Function(CaloriesPostedDay day) valueForDay;
  final int Function(CaloriesPostedItem post) valueForPost;
  final bool allowUnitChange;

  // Handles _PostedChartMetric for this part of the statistics page.
  const _PostedChartMetric({
    required this.title,
    required this.breakdownTitle,
    required this.unit,
    required this.valueForDay,
    required this.valueForPost,
    this.allowUnitChange = false,
  });
}

// This widget controls the posted metric pager used to move between report views.
// The selected index comes from the parent or ViewModel.
// User changes are sent back through the provided callback.
// Handles _PostedMetricPager for this part of the statistics page.
class _PostedMetricPager extends StatelessWidget {
  final CaloriesPostedStatistics statistics;
  final CaloriesPostedViewModel viewModel;
  final int selectedChart;
  final ValueChanged<int> onChartChanged;

  // Handles _PostedMetricPager for this part of the statistics page.
  const _PostedMetricPager({
    required this.statistics,
    required this.viewModel,
    required this.selectedChart,
    required this.onChartChanged,
  });

  // Handles _metrics for this part of the statistics page.
  List<_PostedChartMetric> get _metrics => [
    _PostedChartMetric(
      title: 'Calories Posted Vs Day',
      breakdownTitle: 'Calories Breakdown',
      unit: viewModel.unitLabel,
      valueForDay: (day) => viewModel.convertCalories(day.totalCaloriesKcal),
      valueForPost: (post) => viewModel.convertCalories(post.caloriesKcal),
      allowUnitChange: true,
    ),
    // Handles _PostedChartMetric for this part of the statistics page.
    const _PostedChartMetric(
      title: 'Carbohydrate Posted Vs Day',
      breakdownTitle: 'Carbohydrate Breakdown',
      unit: 'g',
      valueForDay: _carbohydrateForDay,
      valueForPost: _carbohydrateForPost,
    ),
    // Handles _PostedChartMetric for this part of the statistics page.
    const _PostedChartMetric(
      title: 'Protein Posted Vs Day',
      breakdownTitle: 'Protein Breakdown',
      unit: 'g',
      valueForDay: _proteinForDay,
      valueForPost: _proteinForPost,
    ),
    // Handles _PostedChartMetric for this part of the statistics page.
    const _PostedChartMetric(
      title: 'Fat Posted Vs Day',
      breakdownTitle: 'Fat Breakdown',
      unit: 'g',
      valueForDay: _fatForDay,
      valueForPost: _fatForPost,
    ),
  ];

  // Handles _carbohydrateForDay for this part of the statistics page.
  static int _carbohydrateForDay(CaloriesPostedDay day) {
    return day.totalCarbohydrateGram;
  }

  // Handles _proteinForDay for this part of the statistics page.
  static int _proteinForDay(CaloriesPostedDay day) {
    return day.totalProteinGram;
  }

  // Handles _fatForDay for this part of the statistics page.
  static int _fatForDay(CaloriesPostedDay day) {
    return day.totalFatGram;
  }

  // Handles _carbohydrateForPost for this part of the statistics page.
  static int _carbohydrateForPost(CaloriesPostedItem post) {
    return post.carbohydrateGram;
  }

  // Handles _proteinForPost for this part of the statistics page.
  static int _proteinForPost(CaloriesPostedItem post) {
    return post.proteinGram;
  }

  // Handles _fatForPost for this part of the statistics page.
  static int _fatForPost(CaloriesPostedItem post) {
    return post.fatGram;
  }

  @override
  // Build the posted metric pager with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final metrics = _metrics;
    final metric = metrics[selectedChart];

    return Column(
      children: [
        _MetricTabs(selectedIndex: selectedChart, onSelected: onChartChanged),
        // Handles SizedBox for this part of the statistics page.
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) => _handleSwipe(details, metrics),
          child: Column(
            children: [
              _CaloriesChartCard(statistics: statistics, metric: metric),
              // Handles SizedBox for this part of the statistics page.
              const SizedBox(height: AppSpacing.lg),
              _CaloriesPostedBreakdown(
                days: statistics.dailyPosts,
                expandedIndex: viewModel.expandedIndex,
                metric: metric,
                onUnitChanged: viewModel.setDisplayUnit,
                onToggle: viewModel.toggleDay,
              ),
            ],
          ),
        ),
        // Handles SizedBox for this part of the statistics page.
        const SizedBox(height: AppSpacing.sm),
        _MetricDots(count: metrics.length, selectedIndex: selectedChart),
      ],
    );
  }

  // Convert the swipe or tap into a valid page index.
  // Store the index so tabs, content, and page dots stay matched.
  // Handles _handleSwipe for this part of the statistics page.
  void _handleSwipe(DragEndDetails details, List<_PostedChartMetric> metrics) {
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
class _MetricTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  // Handles _MetricTabs for this part of the statistics page.
  const _MetricTabs({required this.selectedIndex, required this.onSelected});

  @override
  // Build the metric tabs with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
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
class _MetricDots extends StatelessWidget {
  final int count;
  final int selectedIndex;

  // Handles _MetricDots for this part of the statistics page.
  const _MetricDots({required this.count, required this.selectedIndex});

  @override
  // Build the metric dots with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
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
class _CaloriesChartCard extends StatelessWidget {
  final CaloriesPostedStatistics statistics;
  final _PostedChartMetric metric;

  // Handles _CaloriesChartCard for this part of the statistics page.
  const _CaloriesChartCard({required this.statistics, required this.metric});

  @override
  // Build the calories chart card from the values supplied by the parent.
  // Labels, scale, and spacing are prepared before the chart is displayed.
  // This method only handles presentation and does not change report data.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d');

    return _SectionCard(
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
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = (statistics.dailyPosts.length * 52.0).clamp(
                constraints.maxWidth,
                double.infinity,
              );

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  // POSTED-NUTRIENT LINE-CHART UI CALL STARTS HERE.
                  // The selected nutrient's daily values become chart points.
                  // Draws a line chart of nutrients from recipes posted each day.
                  // Link: CaloriesPostedPage -> StatisticsLineChart.
                  // Widget file: ../widgets/statistics_line_chart.dart.
                  child: StatisticsLineChart(
                    height: 220,
                    points: statistics.dailyPosts
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

// This widget displays the detailed calories posted breakdown.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
// Handles _CaloriesPostedBreakdown for this part of the statistics page.
class _CaloriesPostedBreakdown extends StatelessWidget {
  final List<CaloriesPostedDay> days;
  final int? expandedIndex;
  final _PostedChartMetric metric;
  final ValueChanged<CaloriesDisplayUnit> onUnitChanged;
  final ValueChanged<int> onToggle;

  // Handles _CaloriesPostedBreakdown for this part of the statistics page.
  const _CaloriesPostedBreakdown({
    required this.days,
    required this.expandedIndex,
    required this.metric,
    required this.onUnitChanged,
    required this.onToggle,
  });

  @override
  // Build the visible rows for the calories posted breakdown.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.breakdownTitle,
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
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: List.generate(days.length, (index) {
                final day = days[index];
                final isExpanded = expandedIndex == index;
                return _DaySection(
                  day: day,
                  isExpanded: isExpanded,
                  showDivider: index != days.length - 1,
                  unitLabel: metric.unit,
                  onTap: () => onToggle(index),
                  valueForPost: metric.valueForPost,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// This widget represents one day section in the report.
// It owns the header and the content that belongs to this group.
// The expanded state decides whether the detailed rows are visible.
// Handles _DaySection for this part of the statistics page.
class _DaySection extends StatelessWidget {
  final CaloriesPostedDay day;
  final bool isExpanded;
  final bool showDivider;
  final String unitLabel;
  final VoidCallback onTap;
  final int Function(CaloriesPostedItem post) valueForPost;

  // Handles _DaySection for this part of the statistics page.
  const _DaySection({
    required this.day,
    required this.isExpanded,
    required this.showDivider,
    required this.unitLabel,
    required this.onTap,
    required this.valueForPost,
  });

  @override
  // Build the visible rows for the day section.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final dateText = DateFormat('MMM d, yyyy').format(day.date);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                // Handles _SoftIcon for this part of the statistics page.
                const _SoftIcon(icon: Icons.event_available),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateText,
                        style: context.text.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Total Posted',
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  day.totalPost.toString(),
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
                const SizedBox(width: AppSpacing.md),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...day.posts.map(
            (post) => _PostMealRow(
              post: post,
              unitLabel: unitLabel,
              valueForPost: valueForPost,
            ),
          ),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

// This small widget draws one post meal row.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _PostMealRow for this part of the statistics page.
class _PostMealRow extends StatelessWidget {
  final CaloriesPostedItem post;
  final String unitLabel;
  final int Function(CaloriesPostedItem post) valueForPost;

  // Handles _PostMealRow for this part of the statistics page.
  const _PostMealRow({
    required this.post,
    required this.unitLabel,
    required this.valueForPost,
  });

  @override
  // Build the visual layout for this post meal row.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 7,
      ),
      child: Row(
        children: [
          _FoodIcon(icon: post.icon, imageUrl: post.imageUrl),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              post.recipeName,
              style: context.text.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '${valueForPost(post)} $unitLabel',
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

// This helper draws the reusable unit button.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
// Handles _UnitButton for this part of the statistics page.
class _UnitButton extends StatelessWidget {
  final CaloriesDisplayUnit displayUnit;
  final ValueChanged<CaloriesDisplayUnit> onUnitChanged;

  // Handles _UnitButton for this part of the statistics page.
  const _UnitButton({required this.displayUnit, required this.onUnitChanged});

  @override
  // Build the visual layout for this unit button.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return PopupMenuButton<CaloriesDisplayUnit>(
      initialValue: displayUnit,
      onSelected: onUnitChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: CaloriesDisplayUnit.kcal, child: Text('kcal')),
        PopupMenuItem(value: CaloriesDisplayUnit.cal, child: Text('cal')),
      ],
      child: Row(
        children: [
          Text(
            displayUnit == CaloriesDisplayUnit.kcal ? 'kcal' : 'cal',
            style: context.text.bodySmall?.copyWith(
              color: Colors.black,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          // Handles Icon for this part of the statistics page.
          const Icon(Icons.tune, size: 17),
        ],
      ),
    );
  }
}

// This helper is responsible for the date range bar part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
// Handles DateRangeBar for this part of the statistics page.
class DateRangeBar extends StatelessWidget {
  final String dateRange;

  const DateRangeBar({super.key, required this.dateRange});

  @override
  // Build the date range bar with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
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
                  child: Text(dateRange, overflow: TextOverflow.ellipsis),
                ),
                // Handles Icon for this part of the statistics page.
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
class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  // Handles _SummaryTile for this part of the statistics page.
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
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, overflow: TextOverflow.ellipsis),
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

// This widget represents one section card in the report.
// It owns the header and the content that belongs to this group.
// The expanded state decides whether the detailed rows are visible.
// Handles _SectionCard for this part of the statistics page.
class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  // Build the visible rows for the section card.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}

// This helper draws the reusable food icon.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
// Handles _FoodIcon for this part of the statistics page.
class _FoodIcon extends StatelessWidget {
  final IconData icon;
  final String? imageUrl;

  // Handles _FoodIcon for this part of the statistics page.
  const _FoodIcon({required this.icon, this.imageUrl});

  @override
  // Build the visual layout for this food icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
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
class _SoftIcon extends StatelessWidget {
  final IconData icon;

  const _SoftIcon({required this.icon});

  @override
  // Build the visual layout for this soft icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
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

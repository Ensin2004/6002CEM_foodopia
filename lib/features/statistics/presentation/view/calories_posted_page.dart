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
import '../../domain/entities/calories_posted_statistics.dart';
import '../../domain/usecases/get_calories_posted_statistics_usecase.dart';
import '../viewmodel/calories_posted_viewmodel.dart';
import '../widgets/statistics_page_helpers.dart';
import '../widgets/statistics_line_chart.dart';

class CaloriesPostedPage extends StatelessWidget {
  const CaloriesPostedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CaloriesPostedViewModel(
        getStatisticsUseCase: sl<GetCaloriesPostedStatisticsUseCase>(),
      ),
      child: const _CaloriesPostedView(),
    );
  }
}

class _CaloriesPostedView extends StatefulWidget {
  const _CaloriesPostedView();

  @override
  State<_CaloriesPostedView> createState() => _CaloriesPostedViewState();
}

class _CaloriesPostedViewState extends State<_CaloriesPostedView> {
  int _selectedChart = 0;

  @override
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

  Widget _buildBody(BuildContext context, CaloriesPostedViewModel viewModel) {
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
                    icon: Icons.article_outlined,
                    title: 'Total Post',
                    value: statistics.totalPost.toString(),
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

  String get _averageTitle {
    switch (_selectedChart) {
      case 1:
        return 'Average Carbohydrate';
      case 2:
        return 'Average Protein';
      case 3:
        return 'Average Fat';
      default:
        return 'Average Nutrient';
    }
  }

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
}

class _PostedChartMetric {
  final String title;
  final String breakdownTitle;
  final String unit;
  final int Function(CaloriesPostedDay day) valueForDay;
  final int Function(CaloriesPostedItem post) valueForPost;
  final bool allowUnitChange;

  const _PostedChartMetric({
    required this.title,
    required this.breakdownTitle,
    required this.unit,
    required this.valueForDay,
    required this.valueForPost,
    this.allowUnitChange = false,
  });
}

class _PostedMetricPager extends StatelessWidget {
  final CaloriesPostedStatistics statistics;
  final CaloriesPostedViewModel viewModel;
  final int selectedChart;
  final ValueChanged<int> onChartChanged;

  const _PostedMetricPager({
    required this.statistics,
    required this.viewModel,
    required this.selectedChart,
    required this.onChartChanged,
  });

  List<_PostedChartMetric> get _metrics => [
    _PostedChartMetric(
      title: 'Nutrient Posted Vs Day',
      breakdownTitle: 'Nutrient Breakdown',
      unit: viewModel.unitLabel,
      valueForDay: (day) => viewModel.convertCalories(day.totalCaloriesKcal),
      valueForPost: (post) => viewModel.convertCalories(post.caloriesKcal),
      allowUnitChange: true,
    ),
    const _PostedChartMetric(
      title: 'Carbohydrate Posted Vs Day',
      breakdownTitle: 'Carbohydrate Breakdown',
      unit: 'g',
      valueForDay: _carbohydrateForDay,
      valueForPost: _carbohydrateForPost,
    ),
    const _PostedChartMetric(
      title: 'Protein Posted Vs Day',
      breakdownTitle: 'Protein Breakdown',
      unit: 'g',
      valueForDay: _proteinForDay,
      valueForPost: _proteinForPost,
    ),
    const _PostedChartMetric(
      title: 'Fat Posted Vs Day',
      breakdownTitle: 'Fat Breakdown',
      unit: 'g',
      valueForDay: _fatForDay,
      valueForPost: _fatForPost,
    ),
  ];

  static int _carbohydrateForDay(CaloriesPostedDay day) {
    return day.totalCarbohydrateGram;
  }

  static int _proteinForDay(CaloriesPostedDay day) {
    return day.totalProteinGram;
  }

  static int _fatForDay(CaloriesPostedDay day) {
    return day.totalFatGram;
  }

  static int _carbohydrateForPost(CaloriesPostedItem post) {
    return post.carbohydrateGram;
  }

  static int _proteinForPost(CaloriesPostedItem post) {
    return post.proteinGram;
  }

  static int _fatForPost(CaloriesPostedItem post) {
    return post.fatGram;
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
        const SizedBox(height: AppSpacing.sm),
        _MetricDots(count: metrics.length, selectedIndex: selectedChart),
      ],
    );
  }

  void _handleSwipe(DragEndDetails details, List<_PostedChartMetric> metrics) {
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
    const labels = ['Nutrient', 'Carbohydrate', 'Protein', 'Fat'];
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
  final CaloriesPostedStatistics statistics;
  final _PostedChartMetric metric;

  const _CaloriesChartCard({required this.statistics, required this.metric});

  @override
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

class _CaloriesPostedBreakdown extends StatelessWidget {
  final List<CaloriesPostedDay> days;
  final int? expandedIndex;
  final _PostedChartMetric metric;
  final ValueChanged<CaloriesDisplayUnit> onUnitChanged;
  final ValueChanged<int> onToggle;

  const _CaloriesPostedBreakdown({
    required this.days,
    required this.expandedIndex,
    required this.metric,
    required this.onUnitChanged,
    required this.onToggle,
  });

  @override
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

class _DaySection extends StatelessWidget {
  final CaloriesPostedDay day;
  final bool isExpanded;
  final bool showDivider;
  final String unitLabel;
  final VoidCallback onTap;
  final int Function(CaloriesPostedItem post) valueForPost;

  const _DaySection({
    required this.day,
    required this.isExpanded,
    required this.showDivider,
    required this.unitLabel,
    required this.onTap,
    required this.valueForPost,
  });

  @override
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

class _PostMealRow extends StatelessWidget {
  final CaloriesPostedItem post;
  final String unitLabel;
  final int Function(CaloriesPostedItem post) valueForPost;

  const _PostMealRow({
    required this.post,
    required this.unitLabel,
    required this.valueForPost,
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
          _FoodIcon(icon: post.icon, imageUrl: post.imageUrl),
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

class _UnitButton extends StatelessWidget {
  final CaloriesDisplayUnit displayUnit;
  final ValueChanged<CaloriesDisplayUnit> onUnitChanged;

  const _UnitButton({required this.displayUnit, required this.onUnitChanged});

  @override
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
          const Icon(Icons.tune, size: 17),
        ],
      ),
    );
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
                  child: Text(dateRange, overflow: TextOverflow.ellipsis),
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

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
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

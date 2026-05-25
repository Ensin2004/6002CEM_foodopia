import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/entities/food_analytic_statistics.dart';
import '../../domain/usecases/get_food_analytic_statistics_usecase.dart';
import '../viewmodel/food_analytic_viewmodel.dart';
import '../widgets/statistics_bar_chart.dart';
import '../widgets/statistics_page_helpers.dart';

class FoodAnalyticPage extends StatelessWidget {
  const FoodAnalyticPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FoodAnalyticViewModel(
        getStatisticsUseCase: sl<GetFoodAnalyticStatisticsUseCase>(),
      ),
      child: const _FoodAnalyticView(),
    );
  }
}

class _FoodAnalyticView extends StatefulWidget {
  const _FoodAnalyticView();

  @override
  State<_FoodAnalyticView> createState() => _FoodAnalyticViewState();
}

class _FoodAnalyticViewState extends State<_FoodAnalyticView> {
  late final PageController _chartController;

  @override
  void initState() {
    super.initState();
    _chartController = PageController();
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FoodAnalyticViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Frequently Eat Meals',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, FoodAnalyticViewModel viewModel) {
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading food analytic...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return _FoodAnalyticError(
        message: viewModel.errorMessage ?? 'Unable to load food analytic',
        onRetry: viewModel.loadStatistics,
      );
    }
    final selectedChart = viewModel.selectedChart ?? statistics.charts.first;
    final pageWidth = MediaQuery.sizeOf(context).width;
    final chartPageHeight = pageWidth < 360 ? 640.0 : 620.0;

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
                    icon: Icons.fastfood,
                    title: selectedChart.summaryTitle,
                    value: selectedChart.summaryValue.toString(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.room_service_outlined,
                    title: selectedChart.highlightTitle,
                    value: selectedChart.highlightValue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: chartPageHeight,
              child: PageView.builder(
                controller: _chartController,
                itemCount: statistics.charts.length,
                onPageChanged: viewModel.selectChart,
                itemBuilder: (context, index) {
                  final chart = statistics.charts[index].sorted(
                    viewModel.sortOrder,
                  );
                  return SingleChildScrollView(
                    child: _FoodAnalyticChartCard(
                      chart: chart,
                      sortOrder: viewModel.sortOrder,
                      onSortChanged: viewModel.setSortOrder,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _PageDots(
              count: statistics.charts.length,
              selectedIndex: viewModel.selectedChartIndex,
            ),
          ],
        ),
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

class _FoodAnalyticChartCard extends StatelessWidget {
  final FoodAnalyticChart chart;
  final StatisticsSortOrder sortOrder;
  final ValueChanged<StatisticsSortOrder> onSortChanged;

  const _FoodAnalyticChartCard({
    required this.chart,
    required this.sortOrder,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.sizeOf(context).width - 52;
    final chartWidth = availableWidth.clamp(288.0, 340.0);
    final chartHeight = chartWidth * 0.74;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
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
          _ChartHeader(title: chart.title),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: SizedBox(
              width: chartWidth,
              child: StatisticsBarChart(
                height: chartHeight,
                items: chart.items
                    .map(
                      (item) => StatisticsBarChartItem(
                        label: item.label,
                        value: item.value,
                        icon: item.icon,
                        color: item.color,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _TopList(
            chart: chart,
            sortOrder: sortOrder,
            onSortChanged: onSortChanged,
          ),
        ],
      ),
    );
  }
}

class _ChartHeader extends StatelessWidget {
  final String title;

  const _ChartHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: context.text.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    );
  }
}

class _TopList extends StatelessWidget {
  final FoodAnalyticChart chart;
  final StatisticsSortOrder sortOrder;
  final ValueChanged<StatisticsSortOrder> onSortChanged;

  const _TopList({
    required this.chart,
    required this.sortOrder,
    required this.onSortChanged,
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
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _listTitle(chart.type, sortOrder),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              _SortButton(
                type: chart.type,
                sortOrder: sortOrder,
                onSortChanged: onSortChanged,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...chart.items.map((item) => _TopListRow(item: item)),
        ],
      ),
    );
  }

  String _listTitle(FoodAnalyticChartType type, StatisticsSortOrder sortOrder) {
    final prefix = sortOrder == StatisticsSortOrder.most ? 'Top' : 'Least';
    switch (type) {
      case FoodAnalyticChartType.mealPlanned:
        return '$prefix Favourite Dish';
      case FoodAnalyticChartType.preparedIngredient:
        return '$prefix Prepared Ingredient';
      case FoodAnalyticChartType.categoryMealPrepared:
        return '$prefix Meal Category';
    }
  }
}

class _SortButton extends StatelessWidget {
  final FoodAnalyticChartType type;
  final StatisticsSortOrder sortOrder;
  final ValueChanged<StatisticsSortOrder> onSortChanged;

  const _SortButton({
    required this.type,
    required this.sortOrder,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<StatisticsSortOrder>(
      tooltip: 'Sort',
      initialValue: sortOrder,
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: StatisticsSortOrder.most,
          child: Text(_mostSortLabel(type)),
        ),
        PopupMenuItem(
          value: StatisticsSortOrder.least,
          child: Text(_leastSortLabel(type)),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sort',
            style: context.text.bodySmall?.copyWith(
              color: Colors.black,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.tune, size: 17),
        ],
      ),
    );
  }

  String _mostSortLabel(FoodAnalyticChartType type) {
    switch (type) {
      case FoodAnalyticChartType.mealPlanned:
        return 'Most dish';
      case FoodAnalyticChartType.preparedIngredient:
        return 'Most prepared ingredient';
      case FoodAnalyticChartType.categoryMealPrepared:
        return 'Most category prepared';
    }
  }

  String _leastSortLabel(FoodAnalyticChartType type) {
    switch (type) {
      case FoodAnalyticChartType.mealPlanned:
        return 'Least dish';
      case FoodAnalyticChartType.preparedIngredient:
        return 'Least prepared ingredient';
      case FoodAnalyticChartType.categoryMealPrepared:
        return 'Least category prepared';
    }
  }
}

class _TopListRow extends StatelessWidget {
  final FoodAnalyticBarItem item;

  const _TopListRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
            child: Icon(item.icon, color: const Color(0xFF6D642C), size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      item.value.toString(),
                      style: context.text.bodySmall?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: item.percent.clamp(0.0, 1.0),
                    color: item.color,
                    backgroundColor: const Color(0xFFE9EEF1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${(item.percent * 100).round()}%',
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int selectedIndex;

  const _PageDots({required this.count, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isSelected = selectedIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isSelected ? 7 : 5,
          height: isSelected ? 7 : 5,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.border,
            shape: BoxShape.circle,
          ),
        );
      }),
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

class _FoodAnalyticError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _FoodAnalyticError({required this.message, required this.onRetry});

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

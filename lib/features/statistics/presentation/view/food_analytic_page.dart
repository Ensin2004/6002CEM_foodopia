import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../app/routers/app_router.dart';
import '../../../../app/routers/router_args.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/tabs/app_pill_segmented_control.dart';
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
            _PageTabs(
              charts: statistics.charts,
              selectedIndex: viewModel.selectedChartIndex,
              onSelected: viewModel.selectChart,
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (details) =>
                  _handleSwipe(details, viewModel, statistics.charts.length),
              child: _FoodAnalyticChartCard(
                chart: selectedChart,
                sortOrder: viewModel.sortOrder,
                expandedIndex: viewModel.expandedItemIndex,
                onSortChanged: viewModel.setSortOrder,
                onToggle: viewModel.toggleItem,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PageDots(
              count: statistics.charts.length,
              selectedIndex: viewModel.selectedChartIndex,
            ),
          ],
        ),
      ),
    );
  }

  void _handleSwipe(
    DragEndDetails details,
    FoodAnalyticViewModel viewModel,
    int count,
  ) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 220) return;
    final nextIndex = velocity < 0
        ? viewModel.selectedChartIndex + 1
        : viewModel.selectedChartIndex - 1;
    if (nextIndex < 0 || nextIndex >= count) return;
    viewModel.selectChart(nextIndex);
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
  final int? expandedIndex;
  final ValueChanged<StatisticsSortOrder> onSortChanged;
  final ValueChanged<int> onToggle;

  const _FoodAnalyticChartCard({
    required this.chart,
    required this.sortOrder,
    required this.expandedIndex,
    required this.onSortChanged,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.sizeOf(context).width - 52;
    final chartWidth = availableWidth.clamp(288.0, 340.0);
    final chartHeight = chartWidth * 0.74;
    final chartItems = chart.type == FoodAnalyticChartType.preparedIngredient
        ? chart.items.take(5).toList()
        : chart.items;

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
                items: chartItems
                    .map(
                      (item) => StatisticsBarChartItem(
                        label: item.label,
                        value: item.value,
                        icon: item.icon,
                        color: item.color,
                        imageUrl: item.imageUrl,
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
            expandedIndex: expandedIndex,
            onSortChanged: onSortChanged,
            onToggle: onToggle,
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
  final int? expandedIndex;
  final ValueChanged<StatisticsSortOrder> onSortChanged;
  final ValueChanged<int> onToggle;

  const _TopList({
    required this.chart,
    required this.sortOrder,
    required this.expandedIndex,
    required this.onSortChanged,
    required this.onToggle,
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
          ...List.generate(chart.items.length, (index) {
            return _TopListRow(
              chartType: chart.type,
              item: chart.items[index],
              isExpanded: expandedIndex == index,
              onTap: () => onToggle(index),
            );
          }),
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
  final FoodAnalyticChartType chartType;
  final FoodAnalyticBarItem item;
  final bool isExpanded;
  final VoidCallback onTap;

  const _TopListRow({
    required this.chartType,
    required this.item,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canViewRecipe =
        chartType == FoodAnalyticChartType.mealPlanned &&
        (item.recipeId ?? '').isNotEmpty;
    return Column(
      children: [
        InkWell(
          onTap: chartType == FoodAnalyticChartType.mealPlanned ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                _FoodIcon(item: item),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${item.value} ${item.value == 1 ? "time" : "times"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  item.value.toString(),
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (canViewRecipe) ...[
                  const SizedBox(width: AppSpacing.md),
                  _RecipeViewButton(recipeId: item.recipeId!),
                ],
                if (chartType != FoodAnalyticChartType.mealPlanned) ...[
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (chartType != FoodAnalyticChartType.mealPlanned && isExpanded)
          ...item.details.map((detail) => _FoodDetailRow(detail: detail)),
      ],
    );
  }
}

class _FoodDetailRow extends StatelessWidget {
  final FoodAnalyticDetailItem detail;

  const _FoodDetailRow({required this.detail});

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
          _FoodIcon(
            item: FoodAnalyticBarItem(
              label: detail.name,
              value: detail.quantity,
              percent: 0,
              icon: detail.icon,
              color: AppColors.primary,
              imageUrl: detail.imageUrl,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              detail.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            detail.quantity.toString(),
            style: context.text.bodySmall?.copyWith(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeViewButton extends StatelessWidget {
  final String recipeId;

  const _RecipeViewButton({required this.recipeId});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => context.push(
        AppRouter.exploreRecipeDetail,
        extra: ExploreRecipeDetailArgs(recipeId: recipeId),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View',
              style: context.text.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

class _PageTabs extends StatelessWidget {
  final List<FoodAnalyticChart> charts;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PageTabs({
    required this.charts,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AppPillSegmentedControl(
      labels: charts.map((chart) => _tabLabel(chart.type)).toList(),
      selectedIndex: selectedIndex,
      onChanged: onSelected,
    );
  }

  String _tabLabel(FoodAnalyticChartType type) {
    switch (type) {
      case FoodAnalyticChartType.mealPlanned:
        return 'Dish';
      case FoodAnalyticChartType.preparedIngredient:
        return 'Ingredient';
      case FoodAnalyticChartType.categoryMealPrepared:
        return 'Category';
    }
  }
}

class _FoodIcon extends StatelessWidget {
  final FoodAnalyticBarItem item;

  const _FoodIcon({required this.item});

  @override
  Widget build(BuildContext context) {
    final url = item.imageUrl?.trim() ?? '';
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
              errorBuilder: (_, __, ___) => _fallback(context),
            )
          : _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    if (item.icon == Icons.abc && item.label.isNotEmpty) {
      return Text(
        item.label.characters.first.toUpperCase(),
        style: context.text.bodySmall?.copyWith(
          color: const Color(0xFF6D642C),
          fontWeight: FontWeight.w900,
        ),
      );
    }
    return Icon(item.icon, color: const Color(0xFF6D642C), size: 18);
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

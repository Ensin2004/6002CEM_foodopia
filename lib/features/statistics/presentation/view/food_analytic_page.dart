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

/// Shows the user's most common meals, ingredients, and food categories.
class FoodAnalyticPage extends StatelessWidget {
  const FoodAnalyticPage({super.key});

  @override
  // Build the food analytic page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  Widget build(BuildContext context) {
    // The ViewModel controls loading, date filtering, tabs, sorting, and rows.
    return ChangeNotifierProvider(
      create: (_) => FoodAnalyticViewModel(
        getStatisticsUseCase: sl<GetFoodAnalyticStatisticsUseCase>(),
      ),
      child: const _FoodAnalyticView(),
    );
  }
}

// This widget builds the main content for the food analytic view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
class _FoodAnalyticView extends StatefulWidget {
  const _FoodAnalyticView();

  @override
  State<_FoodAnalyticView> createState() => _FoodAnalyticViewState();
}

// This state object manages the changing parts of the food analytic view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
class _FoodAnalyticViewState extends State<_FoodAnalyticView> {
  @override
  // Build the food analytic view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
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
    // Show a full loader only before the first successful result.
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
            // A new date range reloads every chart on this page.
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

  // Convert the swipe or tap into a valid page index.
  // Store the index so tabs, content, and page dots stay matched.
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

// This helper is responsible for the date range bar part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
class DateRangeBar extends StatelessWidget {
  final String dateRange;

  const DateRangeBar({super.key, required this.dateRange});

  @override
  // Build the date range bar with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
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

// This widget turns the report values into the food analytic chart card.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
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
  // Build the food analytic chart card from the values supplied by the parent.
  // Labels, scale, and spacing are prepared before the chart is displayed.
  // This method only handles presentation and does not change report data.
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
              // FOOD-ANALYTIC BAR-CHART UI CALL STARTS HERE.
              // The first five items from the selected analysis become bars.
              // Draws a bar chart of top meals, ingredients, or categories.
              // Link: FoodAnalyticPage -> StatisticsBarChart.
              // Widget file: ../widgets/statistics_bar_chart.dart.
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

// This widget turns the report values into the chart header.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
class _ChartHeader extends StatelessWidget {
  final String title;

  const _ChartHeader({required this.title});

  @override
  // Build the chart header from the values supplied by the parent.
  // Labels, scale, and spacing are prepared before the chart is displayed.
  // This method only handles presentation and does not change report data.
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

// This widget displays the detailed top list.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
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
  // Build the visible rows for the top list.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
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

  // This helper prepares a value used by the visible report.
  // Keeping it outside build makes the widget tree easier to follow.
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

// This helper draws the reusable sort button.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
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
  // Build the visual layout for this sort button.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
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

  // This helper prepares a value used by the visible report.
  // Keeping it outside build makes the widget tree easier to follow.
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

  // This helper prepares a value used by the visible report.
  // Keeping it outside build makes the widget tree easier to follow.
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

// This widget displays the detailed top list row.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
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
  // Build the visible rows for the top list row.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
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

// This small widget draws one food detail row.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
class _FoodDetailRow extends StatelessWidget {
  final FoodAnalyticDetailItem detail;

  const _FoodDetailRow({required this.detail});

  @override
  // Build the visual layout for this food detail row.
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

// This helper draws the reusable recipe view button.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
class _RecipeViewButton extends StatelessWidget {
  final String recipeId;

  const _RecipeViewButton({required this.recipeId});

  @override
  // Build the visual layout for this recipe view button.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
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

// This widget controls the page tabs used to move between report views.
// The selected index comes from the parent or ViewModel.
// User changes are sent back through the provided callback.
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
  // Build the page tabs with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  Widget build(BuildContext context) {
    return AppPillSegmentedControl(
      labels: charts.map((chart) => _tabLabel(chart.type)).toList(),
      selectedIndex: selectedIndex,
      onChanged: onSelected,
    );
  }

  // This helper prepares a value used by the visible report.
  // Keeping it outside build makes the widget tree easier to follow.
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

// This helper draws the reusable food icon.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
class _FoodIcon extends StatelessWidget {
  final FoodAnalyticBarItem item;

  const _FoodIcon({required this.item});

  @override
  // Build the visual layout for this food icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
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

// This widget controls the page dots used to move between report views.
// The selected index comes from the parent or ViewModel.
// User changes are sent back through the provided callback.
class _PageDots extends StatelessWidget {
  final int count;
  final int selectedIndex;

  const _PageDots({required this.count, required this.selectedIndex});

  @override
  // Build the page dots with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
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

// This widget shows the food analytic error when report data is unavailable.
// It explains the problem and gives the user a retry action.
// The retry callback asks the ViewModel to load the report again.
class _FoodAnalyticError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _FoodAnalyticError({required this.message, required this.onRetry});

  @override
  // Build the food analytic error with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
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

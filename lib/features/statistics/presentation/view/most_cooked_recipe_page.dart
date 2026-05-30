import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/entities/most_cooked_recipe_statistics.dart';
import '../../domain/usecases/get_most_cooked_recipe_statistics_usecase.dart';
import '../viewmodel/most_cooked_recipe_viewmodel.dart';
import '../widgets/statistics_bar_chart.dart';
import '../widgets/statistics_page_helpers.dart';

class MostCookedRecipePage extends StatelessWidget {
  const MostCookedRecipePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MostCookedRecipeViewModel(
        getStatisticsUseCase: sl<GetMostCookedRecipeStatisticsUseCase>(),
      ),
      child: const _MostCookedRecipeView(),
    );
  }
}

class _MostCookedRecipeView extends StatelessWidget {
  const _MostCookedRecipeView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MostCookedRecipeViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Most Cooked Recipe',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, MostCookedRecipeViewModel viewModel) {
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading cooked recipes...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load cooked recipes',
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
                    icon: Icons.groups_outlined,
                    title: 'Total Users Plan To Cook',
                    value: statistics.totalUsersPlanToCook.toString(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.restaurant_menu,
                    title: 'Top Plan To Cook',
                    value: statistics.topPlanToCook,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _RecipeChartCard(recipes: viewModel.chartRecipes),
            const SizedBox(height: AppSpacing.lg),
            _RecipeBreakdown(
              days: viewModel.breakdownDays,
              sortOrder: viewModel.sortOrder,
              expandedIndex: viewModel.expandedIndex,
              onSortChanged: viewModel.setSortOrder,
              onToggle: viewModel.toggleRecipe,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeChartCard extends StatelessWidget {
  final List<MostCookedRecipeItem> recipes;

  const _RecipeChartCard({required this.recipes});

  @override
  Widget build(BuildContext context) {
    final chartWidth = (MediaQuery.sizeOf(context).width - 48).clamp(
      288.0,
      340.0,
    );

    return _SectionCard(
      child: Column(
        children: [
          Text(
            'Most Cooked Recipe By Others',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: chartWidth,
            child: StatisticsBarChart(
              height: chartWidth * 0.74,
              items: recipes
                  .map(
                    (recipe) => StatisticsBarChartItem(
                      label: recipe.dishName,
                      value: recipe.quantity,
                      icon: recipe.icon,
                      color: recipe.color,
                      imageUrl: recipe.imageUrl,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeBreakdown extends StatelessWidget {
  final List<MostCookedRecipeDay> days;
  final MostCookedRecipeSortOrder sortOrder;
  final int? expandedIndex;
  final ValueChanged<MostCookedRecipeSortOrder> onSortChanged;
  final ValueChanged<int> onToggle;

  const _RecipeBreakdown({
    required this.days,
    required this.sortOrder,
    required this.expandedIndex,
    required this.onSortChanged,
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
                  sortOrder == MostCookedRecipeSortOrder.highest
                      ? 'Date Breakdown - Highest'
                      : 'Date Breakdown - Lowest',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              PopupMenuButton<MostCookedRecipeSortOrder>(
                tooltip: 'Sort',
                initialValue: sortOrder,
                onSelected: onSortChanged,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: MostCookedRecipeSortOrder.highest,
                    child: Text('Highest'),
                  ),
                  PopupMenuItem(
                    value: MostCookedRecipeSortOrder.lowest,
                    child: Text('Lowest'),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.tune, size: 17),
                  ],
                ),
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
                return _DateSection(
                  day: day,
                  sortOrder: sortOrder,
                  isExpanded: expandedIndex == index,
                  showDivider: index != days.length - 1,
                  onTap: () => onToggle(index),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSection extends StatelessWidget {
  final MostCookedRecipeDay day;
  final MostCookedRecipeSortOrder sortOrder;
  final bool isExpanded;
  final bool showDivider;
  final VoidCallback onTap;

  const _DateSection({
    required this.day,
    required this.sortOrder,
    required this.isExpanded,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final plannedDate = DateFormat('MMM d, yyyy').format(day.date);
    final recipes = [...day.recipes]
      ..sort((left, right) {
        final result = right.quantity.compareTo(left.quantity);
        return sortOrder == MostCookedRecipeSortOrder.highest
            ? result
            : -result;
      });

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
                        plannedDate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Recipe planned by others',
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
                  day.totalQuantity.toString(),
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
          ...recipes.map((recipe) => _DateRecipeRow(recipe: recipe)),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _DateRecipeRow extends StatelessWidget {
  final MostCookedRecipeDayItem recipe;

  const _DateRecipeRow({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      child: Row(
        children: [
          _FoodIcon(icon: recipe.icon, imageUrl: recipe.imageUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              recipe.dishName,
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
            recipe.quantity.toString(),
            style: context.text.bodyMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
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

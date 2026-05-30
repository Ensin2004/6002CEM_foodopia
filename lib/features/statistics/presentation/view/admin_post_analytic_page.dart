import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/usecases/get_admin_post_analytic_statistics_usecase.dart';
import '../../domain/entities/recipe_performance_statistics.dart';
import '../viewmodel/admin_post_analytic_viewmodel.dart';
import '../widgets/admin_statistics_detail_widgets.dart';
import '../widgets/statistics_bar_chart.dart';
import '../widgets/statistics_page_helpers.dart';

class AdminPostAnalyticPage extends StatelessWidget {
  const AdminPostAnalyticPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminPostAnalyticViewModel(
        getStatisticsUseCase: sl<GetAdminPostAnalyticStatisticsUseCase>(),
      ),
      child: const _AdminPostAnalyticView(),
    );
  }
}

class _AdminPostAnalyticView extends StatefulWidget {
  const _AdminPostAnalyticView();

  @override
  State<_AdminPostAnalyticView> createState() => _AdminPostAnalyticViewState();
}

class _AdminPostAnalyticViewState extends State<_AdminPostAnalyticView> {
  late final PageController _sectionController;
  final DateFormat _summaryDateFormatter = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _sectionController = PageController();
  }

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminPostAnalyticViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Post Analytic',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(viewModel),
    );
  }

  Widget _buildBody(AdminPostAnalyticViewModel viewModel) {
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading post analytic...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load post analytic',
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
            AdminStatisticDateRangeBar(
              dateRange: statistics.dateRange,
              onTap: () => _pickDateRange(viewModel),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AdminStatisticSummaryTile(
                    icon: Icons.trending_up,
                    title: 'Top Posted Day',
                    value:
                        '${_summaryDateFormatter.format(statistics.topDay.date)} (${statistics.topDay.value})',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AdminStatisticSummaryTile(
                    icon: Icons.trending_down,
                    title: 'Least Posted Day',
                    value:
                        '${_summaryDateFormatter.format(statistics.leastDay.date)} (${statistics.leastDay.value})',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AdminLineChartCard(
              title: 'Posted Vs Day',
              values: statistics.dailyPosts,
            ),
            const SizedBox(height: AppSpacing.lg),
            AdminAnalyticSectionPager(
              controller: _sectionController,
              sections: statistics.sections,
              selectedIndex: viewModel.selectedSectionIndex,
              sortOrder: viewModel.sortOrder,
              onPageChanged: viewModel.selectSection,
              onSortChanged: viewModel.setSortOrder,
              customSectionBuilder: (section) {
                if (section.title != 'Recipe Performance') return null;
                return _AdminRecipePerformanceSection(
                  statistics: statistics.recipePerformance,
                  selectedRecipe: viewModel.selectedRecipe,
                  selectedRecipeId: viewModel.selectedRecipeId,
                  onSelected: viewModel.selectRecipe,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange(AdminPostAnalyticViewModel viewModel) async {
    final now = DateTime.now();
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2026, 12, 31),
      initialDateRange: DateTimeRange(
        start: viewModel.startDate ?? now.subtract(const Duration(days: 6)),
        end: viewModel.endDate ?? now,
      ),
    );

    if (pickedRange == null || !mounted) return;
    await viewModel.selectDateRange(
      startDate: pickedRange.start,
      endDate: pickedRange.end,
    );
  }
}

class _AdminRecipePerformanceSection extends StatelessWidget {
  final RecipePerformanceStatistics? statistics;
  final RecipePerformanceItem? selectedRecipe;
  final String? selectedRecipeId;
  final ValueChanged<String> onSelected;

  const _AdminRecipePerformanceSection({
    required this.statistics,
    required this.selectedRecipe,
    required this.selectedRecipeId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final data = statistics;
    if (data == null) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryGrid(
            tiles: [
              _SummaryTileData(
                icon: Icons.comment_outlined,
                title: 'Comments',
                value: data.totalComments.toString(),
              ),
              _SummaryTileData(
                icon: Icons.visibility_outlined,
                title: 'Views',
                value: data.totalViews.toString(),
              ),
              _SummaryTileData(
                icon: Icons.favorite_border,
                title: 'Favourites',
                value: data.totalFavourites.toString(),
              ),
              _SummaryTileData(
                icon: Icons.star_border,
                title: 'Ratings',
                value: data.totalRatings.toString(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _RecipePerformanceChart(recipe: selectedRecipe),
          const SizedBox(height: AppSpacing.lg),
          _RecipePerformanceList(
            recipes: data.recipes,
            selectedRecipeId: selectedRecipeId,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class _RecipePerformanceChart extends StatelessWidget {
  final RecipePerformanceItem? recipe;

  const _RecipePerformanceChart({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final selectedRecipe = recipe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          selectedRecipe?.name ?? 'Recipe Activity',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            _Legend(color: Color(0xFF7C5CFF), label: 'Comment'),
            _Legend(color: Color(0xFF65C8F4), label: 'View'),
            _Legend(color: AppColors.favourite, label: 'Favourite'),
            _Legend(color: AppColors.primary, label: 'Rating'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (selectedRecipe == null)
          SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'Pick a posted recipe',
                textAlign: TextAlign.center,
                style: context.text.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          StatisticsBarChart(
            height: 220,
            items: [
              StatisticsBarChartItem(
                label: 'Comment',
                value: selectedRecipe.commentCount,
                icon: Icons.comment_outlined,
                color: const Color(0xFF7C5CFF),
              ),
              StatisticsBarChartItem(
                label: 'View',
                value: selectedRecipe.totalViews,
                icon: Icons.visibility_outlined,
                color: const Color(0xFF65C8F4),
              ),
              StatisticsBarChartItem(
                label: 'Favourite',
                value: selectedRecipe.favouriteCount,
                icon: Icons.favorite_border,
                color: AppColors.favourite,
              ),
              StatisticsBarChartItem(
                label: 'Rating',
                value: selectedRecipe.ratingCount,
                icon: Icons.star_border,
                color: AppColors.primary,
              ),
            ],
          ),
      ],
    );
  }
}

class _RecipePerformanceList extends StatelessWidget {
  final List<RecipePerformanceItem> recipes;
  final String? selectedRecipeId;
  final ValueChanged<String> onSelected;

  const _RecipePerformanceList({
    required this.recipes,
    required this.selectedRecipeId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Posted Recipe',
          style: context.text.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (recipes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Column(
              children: [
                Image.asset('assets/images/empty_page.png', height: 120),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No posted recipe yet',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...recipes.map(
            (recipe) => _RecipeTile(
              recipe: recipe,
              isSelected: recipe.id == selectedRecipeId,
              onTap: () => onSelected(recipe.id),
            ),
          ),
      ],
    );
  }
}

class _RecipeTile extends StatelessWidget {
  final RecipePerformanceItem recipe;
  final bool isSelected;
  final VoidCallback onTap;

  const _RecipeTile({
    required this.recipe,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFFAFAFA),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _RecipeImage(imageUrl: recipe.imageUrl),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${recipe.commentCount} comments, ${recipe.totalViews} views, ${recipe.favouriteCount} favourites, ${recipe.ratingCount} ratings',
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
            Icon(
              isSelected ? Icons.check_circle : Icons.chevron_right,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeImage extends StatelessWidget {
  final String? imageUrl;

  const _RecipeImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 52,
        height: 52,
        color: AppColors.primary.withValues(alpha: 0.08),
        child: url == null || url.isEmpty
            ? const Icon(Icons.restaurant, color: AppColors.primary)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.restaurant, color: AppColors.primary),
              ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.text.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<_SummaryTileData> tiles;

  const _SummaryGrid({required this.tiles});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: tiles
              .map(
                (tile) => SizedBox(
                  width: itemWidth,
                  child: AdminStatisticSummaryTile(
                    icon: tile.icon,
                    title: tile.title,
                    value: tile.value,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryTileData {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryTileData({
    required this.icon,
    required this.title,
    required this.value,
  });
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

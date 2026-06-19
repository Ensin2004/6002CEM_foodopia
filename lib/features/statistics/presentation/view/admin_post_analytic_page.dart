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
import '../../../../core/widgets/media/app_recipe_media.dart';
import '../../domain/usecases/get_admin_post_analytic_statistics_usecase.dart';
import '../../domain/entities/recipe_performance_statistics.dart';
import '../viewmodel/admin_post_analytic_viewmodel.dart';
import '../widgets/admin_statistics_detail_widgets.dart';
import '../widgets/statistics_bar_chart.dart';
import '../widgets/statistics_page_helpers.dart';

/// Admin report for post activity, ratings, and recipe performance.
// Handles AdminPostAnalyticPage for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class AdminPostAnalyticPage extends StatelessWidget {
  const AdminPostAnalyticPage({super.key});

  @override
  // Build the admin post analytic page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    // The ViewModel owns section paging, sorting, and recipe selection.
    return ChangeNotifierProvider(
      create: (_) => AdminPostAnalyticViewModel(
        getStatisticsUseCase: sl<GetAdminPostAnalyticStatisticsUseCase>(),
      ),
      child: const _AdminPostAnalyticView(),
    );
  }
}

// This widget builds the main content for the admin post analytic view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
// Handles _AdminPostAnalyticView for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _AdminPostAnalyticView extends StatefulWidget {
  const _AdminPostAnalyticView();

  // Handles createState for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  State<_AdminPostAnalyticView> createState() => _AdminPostAnalyticViewState();
}

// This state object manages the changing parts of the admin post analytic view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
// Handles _AdminPostAnalyticViewState for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _AdminPostAnalyticViewState extends State<_AdminPostAnalyticView> {
  late final PageController _sectionController;
  final DateFormat _summaryDateFormatter = DateFormat('MMM d, yyyy');

  // Handles initState for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  void initState() {
    super.initState();
    _sectionController = PageController();
  }

  // Handles dispose for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  @override
  // Build the admin post analytic view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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

  // Handles _buildBody for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget _buildBody(AdminPostAnalyticViewModel viewModel) {
    // Wait for post data before building the system report.
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
            // Reload the daily chart and all post sections for this period.
            AdminStatisticDateRangeBar(
              dateRange: statistics.dateRange,
              onTap: () => _pickDateRange(viewModel),
            ),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
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
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
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
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.lg),
            // ADMIN POST LINE-CHART UI CALL STARTS HERE.
            // The shared card converts dailyPosts into line-chart points.
            // Draws a line chart showing the number of posts created each day.
            // Link: AdminPostAnalyticPage -> AdminLineChartCard.
            // Next: admin_statistics_detail_widgets.dart -> StatisticsLineChart.
            AdminLineChartCard(
              title: 'Posted Vs Day',
              values: statistics.dailyPosts,
            ),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.lg),
            // Most sections use this pager; performance has a custom view.
            // ADMIN POST SECTION UI CALL STARTS HERE.
            // The pager builds the selected section and asks _SectionChart to
            // choose the correct pie or bar chart.
            // Draws the selected post-analysis pie chart or bar chart.
            // Link: AdminPostAnalyticPage -> AdminAnalyticSectionPager.
            // Next: admin_statistics_detail_widgets.dart -> _SectionChart.
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

  // Open the calendar with the current range already selected.
  // Send confirmed dates to the ViewModel so it can reload the report.
  // Handles _pickDateRange for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Future<void> _pickDateRange(AdminPostAnalyticViewModel viewModel) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final defaultStart = DateTime(2026, 5);
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: defaultStart,
      lastDate: today,
      initialDateRange: DateTimeRange(
        start: viewModel.startDate ?? defaultStart,
        end: viewModel.endDate ?? today,
      ),
    );

    if (pickedRange == null || !mounted) return;
    await viewModel.selectDateRange(
      startDate: pickedRange.start,
      endDate: pickedRange.end,
    );
  }
}

// This widget represents one admin recipe performance section in the report.
// It owns the header and the content that belongs to this group.
// The expanded state decides whether the detailed rows are visible.
// Handles _AdminRecipePerformanceSection for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _AdminRecipePerformanceSection extends StatelessWidget {
  final RecipePerformanceStatistics? statistics;
  final RecipePerformanceItem? selectedRecipe;
  final String? selectedRecipeId;
  final ValueChanged<String> onSelected;

  // Handles _AdminRecipePerformanceSection for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _AdminRecipePerformanceSection({
    required this.statistics,
    required this.selectedRecipe,
    required this.selectedRecipeId,
    required this.onSelected,
  });

  @override
  // Build the visible rows for the admin recipe performance section.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
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

// This widget turns the report values into the recipe performance chart.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
// Handles _RecipePerformanceChart for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _RecipePerformanceChart extends StatelessWidget {
  final RecipePerformanceItem? recipe;

  const _RecipePerformanceChart({required this.recipe});

  @override
  // Build the recipe performance chart from the values supplied by the parent.
  // Labels, scale, and spacing are prepared before the chart is displayed.
  // This method only handles presentation and does not change report data.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
        // Handles SizedBox for this part of the statistics page.
        // This makes the purpose clearer when reading or updating the code.
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
        // Handles SizedBox for this part of the statistics page.
        // This makes the purpose clearer when reading or updating the code.
        const SizedBox(height: AppSpacing.md),
        if (selectedRecipe == null)
          SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'Pick a posted recipe',
                style: context.text.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          // ADMIN RECIPE-PERFORMANCE BAR-CHART UI CALL STARTS HERE.
          // The selected recipe's engagement values become bars.
          // Draws a bar chart of comments, views, favourites, and ratings.
          // Link: AdminPostAnalyticPage -> StatisticsBarChart.
          // Widget file: ../widgets/statistics_bar_chart.dart.
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

// This widget displays the detailed recipe performance list.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
// Handles _RecipePerformanceList for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _RecipePerformanceList extends StatelessWidget {
  final List<RecipePerformanceItem> recipes;
  final String? selectedRecipeId;
  final ValueChanged<String> onSelected;

  // Handles _RecipePerformanceList for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _RecipePerformanceList({
    required this.recipes,
    required this.selectedRecipeId,
    required this.onSelected,
  });

  @override
  // Build the visible rows for the recipe performance list.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
        // Handles SizedBox for this part of the statistics page.
        // This makes the purpose clearer when reading or updating the code.
        const SizedBox(height: AppSpacing.md),
        if (recipes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Column(
              children: [
                Image.asset('assets/images/empty_page.png', height: 120),
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
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

// This small widget draws one recipe tile.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _RecipeTile for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _RecipeTile extends StatelessWidget {
  final RecipePerformanceItem recipe;
  final bool isSelected;
  final VoidCallback onTap;

  // Handles _RecipeTile for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _RecipeTile({
    required this.recipe,
    required this.isSelected,
    required this.onTap,
  });

  @override
  // Build the visual layout for this recipe tile.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
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
                  // Handles SizedBox for this part of the statistics page.
                  // This makes the purpose clearer when reading or updating the code.
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
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
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

// This helper draws the reusable recipe image.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
// Handles _RecipeImage for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _RecipeImage extends StatelessWidget {
  final String? imageUrl;

  const _RecipeImage({required this.imageUrl});

  @override
  // Build the visual layout for this recipe image.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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
            : AppRecipeMediaPreview(
                mediaPath: url,
                fit: BoxFit.cover,
                showPlayOverlay: false,
              ),
      ),
    );
  }
}

// This helper draws the reusable legend.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
// Handles _Legend for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  // Handles _Legend for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _Legend({required this.color, required this.label});

  @override
  // Build the visual layout for this legend.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        // Handles SizedBox for this part of the statistics page.
        // This makes the purpose clearer when reading or updating the code.
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

// This helper is responsible for the summary grid part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
// Handles _SummaryGrid for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _SummaryGrid extends StatelessWidget {
  final List<_SummaryTileData> tiles;

  const _SummaryGrid({required this.tiles});

  @override
  // Build the summary grid with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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

// This small widget draws one summary tile data.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _SummaryTileData for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _SummaryTileData {
  final IconData icon;
  final String title;
  final String value;

  // Handles _SummaryTileData for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _SummaryTileData({
    required this.icon,
    required this.title,
    required this.value,
  });
}

// This widget represents one section card in the report.
// It owns the header and the content that belongs to this group.
// The expanded state decides whether the detailed rows are visible.
// Handles _SectionCard for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  // Build the visible rows for the section card.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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

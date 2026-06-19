// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/media/app_recipe_media.dart';
import '../../domain/entities/recipe_performance_statistics.dart';
import '../../domain/usecases/get_recipe_performance_statistics_usecase.dart';
import '../viewmodel/recipe_performance_viewmodel.dart';
import '../widgets/statistics_bar_chart.dart';
import '../widgets/statistics_page_helpers.dart';

/// Shows comments, views, favourites, and ratings for each recipe.
// Handles RecipePerformancePage for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class RecipePerformancePage extends StatelessWidget {
  const RecipePerformancePage({super.key});

  @override
  // Build the recipe performance page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    // The ViewModel loads all recipes and remembers the selected recipe.
    return ChangeNotifierProvider(
      create: (_) => RecipePerformanceViewModel(
        getStatisticsUseCase: sl<GetRecipePerformanceStatisticsUseCase>(),
      ),
      child: const _RecipePerformanceView(),
    );
  }
}

// This widget builds the main content for the recipe performance view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
// Handles _RecipePerformanceView for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _RecipePerformanceView extends StatelessWidget {
  const _RecipePerformanceView();

  @override
  // Build the recipe performance view with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    final viewModel = context.watch<RecipePerformanceViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Recipe Performance',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  // Handles _buildBody for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget _buildBody(
    BuildContext context,
    RecipePerformanceViewModel viewModel,
  ) {
    // Wait for recipe data before showing totals or a selected recipe.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading performance...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load recipe performance',
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
            // This report currently has no date-filter support.
            StatisticsDateRangeBar(
              dateRange: statistics.dateRange,
              onTap: () => _showUnavailable(context),
            ),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.md),
            _SummaryGrid(
              tiles: [
                _SummaryTileData(
                  icon: Icons.comment_outlined,
                  title: 'Comments',
                  value: statistics.totalComments.toString(),
                ),
                _SummaryTileData(
                  icon: Icons.visibility_outlined,
                  title: 'Views',
                  value: statistics.totalViews.toString(),
                ),
                _SummaryTileData(
                  icon: Icons.favorite_border,
                  title: 'Favourites',
                  value: statistics.totalFavourites.toString(),
                ),
                _SummaryTileData(
                  icon: Icons.star_border,
                  title: 'Ratings',
                  value: statistics.totalRatings.toString(),
                ),
              ],
            ),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.lg),
            // The chart updates when the user selects another recipe below.
            _ChartCard(recipe: viewModel.selectedRecipe),
            const SizedBox(height: AppSpacing.lg),
            _RecipeList(
              recipes: statistics.recipes,
              selectedRecipeId: viewModel.selectedRecipeId,
              onSelected: viewModel.selectRecipe,
            ),
          ],
        ),
      ),
    );
  }

  // Explain why this control cannot change the current report.
  // A SnackBar shows the message without leaving the page.
  // Handles _showUnavailable for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Date filter is not available for this section',
          style: context.text.bodyMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

// This widget turns the report values into the chart card.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
// Handles _ChartCard for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _ChartCard extends StatelessWidget {
  final RecipePerformanceItem? recipe;

  const _ChartCard({required this.recipe});

  @override
  // Build the chart card from the values supplied by the parent.
  // Labels, scale, and spacing are prepared before the chart is displayed.
  // This method only handles presentation and does not change report data.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    final selectedRecipe = recipe;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedRecipe?.name ?? 'Recipe Activity',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              // Handles SizedBox for this part of the statistics page.
              // This makes the purpose clearer when reading or updating the code.
              const SizedBox(width: AppSpacing.md),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Handles Wrap for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
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
            // RECIPE-PERFORMANCE BAR-CHART UI CALL STARTS HERE.
            // Comments, views, favourites, and ratings become four bars.
            // Draws a bar chart comparing the selected recipe's engagement.
            // Link: RecipePerformancePage -> StatisticsBarChart.
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
      ),
    );
  }
}

// This widget displays the detailed recipe list.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
// Handles _RecipeList for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _RecipeList extends StatelessWidget {
  final List<RecipePerformanceItem> recipes;
  final String? selectedRecipeId;
  final ValueChanged<String> onSelected;

  // Handles _RecipeList for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _RecipeList({
    required this.recipes,
    required this.selectedRecipeId,
    required this.onSelected,
  });

  @override
  // Build the visible rows for the recipe list.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
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
      ),
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
                  child: _SummaryTile(
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
      height: 74,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
          const SizedBox(width: AppSpacing.sm),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
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
      width: double.infinity,
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

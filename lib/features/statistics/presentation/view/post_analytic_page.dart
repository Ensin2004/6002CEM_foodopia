// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
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
import '../../domain/entities/post_analytic_statistics.dart';
import '../../domain/usecases/get_post_analytic_statistics_usecase.dart';
import '../viewmodel/post_analytic_viewmodel.dart';
import '../widgets/statistics_bar_chart.dart';
import '../widgets/statistics_page_helpers.dart';
import '../widgets/statistics_recipe_media_thumbnail.dart';

/// Compares ratings for posts and ratings grouped by category.
// Handles PostAnalyticPage for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class PostAnalyticPage extends StatelessWidget {
  const PostAnalyticPage({super.key});

  @override
  // Build the post analytic page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    // The ViewModel controls the two report pages, sorting, and open rows.
    return ChangeNotifierProvider(
      create: (_) => PostAnalyticViewModel(
        getStatisticsUseCase: sl<GetPostAnalyticStatisticsUseCase>(),
      ),
      child: const _PostAnalyticView(),
    );
  }
}

// This widget builds the main content for the post analytic view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
// Handles _PostAnalyticView for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _PostAnalyticView extends StatefulWidget {
  const _PostAnalyticView();

  // Handles createState for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  State<_PostAnalyticView> createState() => _PostAnalyticViewState();
}

// This state object manages the changing parts of the post analytic view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
// Handles _PostAnalyticViewState for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _PostAnalyticViewState extends State<_PostAnalyticView> {
  @override
  // Build the post analytic view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    final viewModel = context.watch<PostAnalyticViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Ratings for Post',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  // Handles _buildBody for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget _buildBody(BuildContext context, PostAnalyticViewModel viewModel) {
    // Do not build rating charts until the report has loaded.
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
            // Reload post and category ratings for the selected period.
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
                    icon: Icons.article_outlined,
                    title: 'Total Post',
                    value: statistics.totalPost.toString(),
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.star,
                    title: viewModel.secondarySummaryTitle,
                    value: viewModel.secondarySummaryValue,
                  ),
                ),
              ],
            ),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.lg),
            // Switch between individual posts and category totals.
            _PageTabs(
              selectedIndex: viewModel.selectedPageIndex,
              onSelected: (index) => _goToPage(index, viewModel),
            ),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.md),
            // Horizontal swipes provide another way to change report pages.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (details) =>
                  _handleSwipe(details, viewModel),
              child: viewModel.selectedPageIndex == 0
                  ? _RatedPostPage(
                      posts: viewModel.sortedPosts,
                      sortOrder: viewModel.sortOrder,
                      onSortChanged: viewModel.setSortOrder,
                    )
                  : _CategoryRatingPage(
                      categories: viewModel.sortedCategories,
                      sortOrder: viewModel.sortOrder,
                      expandedIndex: viewModel.expandedCategoryIndex,
                      onSortChanged: viewModel.setSortOrder,
                      onToggle: viewModel.toggleCategory,
                    ),
            ),
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(height: AppSpacing.sm),
            _PageDots(count: 2, selectedIndex: viewModel.selectedPageIndex),
          ],
        ),
      ),
    );
  }

  // Convert the swipe or tap into a valid page index.
  // Store the index so tabs, content, and page dots stay matched.
  // Handles _goToPage for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  void _goToPage(int index, PostAnalyticViewModel viewModel) {
    viewModel.selectPage(index);
  }

  // Convert the swipe or tap into a valid page index.
  // Store the index so tabs, content, and page dots stay matched.
  // Handles _handleSwipe for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  void _handleSwipe(DragEndDetails details, PostAnalyticViewModel viewModel) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 220) return;

    final nextIndex = velocity < 0
        ? viewModel.selectedPageIndex + 1
        : viewModel.selectedPageIndex - 1;
    if (nextIndex < 0 || nextIndex > 1) return;
    viewModel.selectPage(nextIndex);
  }
}

// This is the entry widget for the rated post page.
// It creates the page-level state before showing the screen content.
// Keeping setup here makes the visible layout easier to read.
// Handles _RatedPostPage for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _RatedPostPage extends StatelessWidget {
  final List<PostRatingItem> posts;
  final PostAnalyticSortOrder sortOrder;
  final ValueChanged<PostAnalyticSortOrder> onSortChanged;

  // Handles _RatedPostPage for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _RatedPostPage({
    required this.posts,
    required this.sortOrder,
    required this.onSortChanged,
  });

  @override
  // Build the rated post page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return _ChartShell(
      title: 'All Rated Post',
      chartItems: posts
          .map(
            (post) => StatisticsBarChartItem(
              label: post.name,
              value: post.rating.round(),
              icon: post.icon,
              color: const Color(0xFF21AEEA),
              imageUrl: post.imageUrl,
            ),
          )
          .toList(),
      child: _PostList(
        title: 'Top Rated Post',
        posts: posts,
        sortOrder: sortOrder,
        onSortChanged: onSortChanged,
      ),
    );
  }
}

// This is the entry widget for the category rating page.
// It creates the page-level state before showing the screen content.
// Keeping setup here makes the visible layout easier to read.
// Handles _CategoryRatingPage for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _CategoryRatingPage extends StatelessWidget {
  final List<PostRatingCategory> categories;
  final PostAnalyticSortOrder sortOrder;
  final int? expandedIndex;
  final ValueChanged<PostAnalyticSortOrder> onSortChanged;
  final ValueChanged<int> onToggle;

  // Handles _CategoryRatingPage for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _CategoryRatingPage({
    required this.categories,
    required this.sortOrder,
    required this.expandedIndex,
    required this.onSortChanged,
    required this.onToggle,
  });

  @override
  // Build the category rating page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return _ChartShell(
      title: 'Most Rating For Each Category',
      chartItems: categories
          .take(5)
          .map(
            (category) => StatisticsBarChartItem(
              label: category.name,
              value: category.averageRating.round(),
              icon: category.icon,
              color: const Color(0xFF21AEEA),
              markerText: category.name,
            ),
          )
          .toList(),
      child: _CategoryList(
        categories: categories,
        sortOrder: sortOrder,
        expandedIndex: expandedIndex,
        onSortChanged: onSortChanged,
        onToggle: onToggle,
      ),
    );
  }
}

// This widget turns the report values into the chart shell.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
// Handles _ChartShell for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _ChartShell extends StatelessWidget {
  final String title;
  final List<StatisticsBarChartItem> chartItems;
  final Widget child;

  // Handles _ChartShell for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _ChartShell({
    required this.title,
    required this.chartItems,
    required this.child,
  });

  @override
  // Build the chart shell from the values supplied by the parent.
  // Labels, scale, and spacing are prepared before the chart is displayed.
  // This method only handles presentation and does not change report data.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    final chartWidth = (MediaQuery.sizeOf(context).width - 52).clamp(
      288.0,
      340.0,
    );

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
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: SizedBox(
              width: chartWidth,
              // POST-RATING BAR-CHART UI CALL STARTS HERE.
              // The selected post or category values become visible bars.
              // Draws a bar chart of post ratings or category rating totals.
              // Link: PostAnalyticPage -> StatisticsBarChart.
              // Widget file: ../widgets/statistics_bar_chart.dart.
              child: StatisticsBarChart(
                maxValue: 5,
                height: chartWidth * 0.74,
                items: chartItems,
              ),
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

// This widget displays the detailed post list.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
// Handles _PostList for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _PostList extends StatelessWidget {
  final String title;
  final List<PostRatingItem> posts;
  final PostAnalyticSortOrder sortOrder;
  final ValueChanged<PostAnalyticSortOrder> onSortChanged;

  // Handles _PostList for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _PostList({
    required this.title,
    required this.posts,
    required this.sortOrder,
    required this.onSortChanged,
  });

  @override
  // Build the visible rows for the post list.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _ListHeader(
            title: title,
            sortOrder: sortOrder,
            onSortChanged: onSortChanged,
          ),
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
          const SizedBox(height: AppSpacing.md),
          ...posts.map((post) => _PostRow(post: post, showView: true)),
        ],
      ),
    );
  }
}

// This widget displays the detailed category list.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
// Handles _CategoryList for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _CategoryList extends StatelessWidget {
  final List<PostRatingCategory> categories;
  final PostAnalyticSortOrder sortOrder;
  final int? expandedIndex;
  final ValueChanged<PostAnalyticSortOrder> onSortChanged;
  final ValueChanged<int> onToggle;

  // Handles _CategoryList for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _CategoryList({
    required this.categories,
    required this.sortOrder,
    required this.expandedIndex,
    required this.onSortChanged,
    required this.onToggle,
  });

  @override
  // Build the visible rows for the category list.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _ListHeader(
            title: 'Category Rating',
            sortOrder: sortOrder,
            onSortChanged: onSortChanged,
          ),
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
          const SizedBox(height: AppSpacing.md),
          ...List.generate(categories.length, (index) {
            final category = categories[index];
            return _CategorySection(
              category: category,
              isExpanded: expandedIndex == index,
              onTap: () => onToggle(index),
            );
          }),
        ],
      ),
    );
  }
}

// This widget represents one category section in the report.
// It owns the header and the content that belongs to this group.
// The expanded state decides whether the detailed rows are visible.
// Handles _CategorySection for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _CategorySection extends StatelessWidget {
  final PostRatingCategory category;
  final bool isExpanded;
  final VoidCallback onTap;

  // Handles _CategorySection for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _CategorySection({
    required this.category,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  // Build the visible rows for the category section.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                _FoodIcon(icon: category.icon, label: category.name),
                // Handles SizedBox for this part of the statistics page.
                // This makes the purpose clearer when reading or updating the code.
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: context.text.bodyMedium?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: [
                          _Stars(rating: category.averageRating),
                          // Handles SizedBox for this part of the statistics page.
                          // This makes the purpose clearer when reading or updating the code.
                          const SizedBox(width: AppSpacing.sm),
                          _RatingPill(rating: category.averageRating),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  category.ratedDishCount.toString(),
                  style: context.text.bodyMedium?.copyWith(
                    color: Colors.black,
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
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...category.dishes.map(
            (dish) => _PostRow(post: dish, showView: true),
          ),
      ],
    );
  }
}

// This small widget draws one post row.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _PostRow for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _PostRow extends StatelessWidget {
  final PostRatingItem post;
  final bool showView;

  // Handles _PostRow for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _PostRow({required this.post, required this.showView});

  @override
  // Build the visual layout for this post row.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          _FoodIcon(icon: post.icon, imageUrl: post.imageUrl),
          // Handles SizedBox for this part of the statistics page.
          // This makes the purpose clearer when reading or updating the code.
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    _Stars(rating: post.rating),
                    // Handles SizedBox for this part of the statistics page.
                    // This makes the purpose clearer when reading or updating the code.
                    const SizedBox(width: AppSpacing.sm),
                    _RatingPill(rating: post.rating),
                  ],
                ),
              ],
            ),
          ),
          Text(
            post.ratingCount.toString(),
            style: context.text.bodySmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          if (showView && (post.id ?? '').isNotEmpty) ...[
            // Handles SizedBox for this part of the statistics page.
            // This makes the purpose clearer when reading or updating the code.
            const SizedBox(width: AppSpacing.md),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => context.push(
                AppRouter.exploreRecipeDetail,
                extra: ExploreRecipeDetailArgs(recipeId: post.id!),
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
                    // Handles Icon for this part of the statistics page.
                    // This makes the purpose clearer when reading or updating the code.
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// This widget displays the detailed list header.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
// Handles _ListHeader for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _ListHeader extends StatelessWidget {
  final String title;
  final PostAnalyticSortOrder sortOrder;
  final ValueChanged<PostAnalyticSortOrder> onSortChanged;

  // Handles _ListHeader for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _ListHeader({
    required this.title,
    required this.sortOrder,
    required this.onSortChanged,
  });

  @override
  // Build the visible rows for the list header.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: context.text.bodySmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        PopupMenuButton<PostAnalyticSortOrder>(
          initialValue: sortOrder,
          onSelected: onSortChanged,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: PostAnalyticSortOrder.highestRating,
              child: Text('Highest rating'),
            ),
            PopupMenuItem(
              value: PostAnalyticSortOrder.lowestRating,
              child: Text('Lowest rating'),
            ),
            PopupMenuItem(
              value: PostAnalyticSortOrder.mostRating,
              child: Text('Most rating'),
            ),
            PopupMenuItem(
              value: PostAnalyticSortOrder.leastRating,
              child: Text('Least rating'),
            ),
          ],
          child: Row(
            children: [
              Text(
                'Sort',
                style: context.text.bodySmall?.copyWith(fontSize: 9),
              ),
              // Handles SizedBox for this part of the statistics page.
              // This makes the purpose clearer when reading or updating the code.
              const SizedBox(width: 2),
              const Icon(Icons.tune, size: 17),
            ],
          ),
        ),
      ],
    );
  }
}

// This helper draws the reusable stars.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
// Handles _Stars for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _Stars extends StatelessWidget {
  final double rating;

  const _Stars({required this.rating});

  @override
  // Build the visual layout for this stars.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final filled = index < rating.round();
        return Icon(
          filled ? Icons.star : Icons.star_border,
          color: filled ? AppColors.primary : AppColors.border,
          size: 13,
        );
      }),
    );
  }
}

// This helper draws the reusable rating pill.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
// Handles _RatingPill for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _RatingPill extends StatelessWidget {
  final double rating;

  const _RatingPill({required this.rating});

  @override
  // Build the visual layout for this rating pill.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        rating.toStringAsFixed(1),
        style: context.text.bodySmall?.copyWith(
          color: AppColors.primary,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
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
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(fontSize: 11),
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

// This widget controls the page dots used to move between report views.
// The selected index comes from the parent or ViewModel.
// User changes are sent back through the provided callback.
// Handles _PageDots for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _PageDots extends StatelessWidget {
  final int count;
  final int selectedIndex;

  // Handles _PageDots for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _PageDots({required this.count, required this.selectedIndex});

  @override
  // Build the page dots with the latest available state.
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
          width: selected ? 7 : 5,
          height: selected ? 7 : 5,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.border,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

// This widget controls the page tabs used to move between report views.
// The selected index comes from the parent or ViewModel.
// User changes are sent back through the provided callback.
// Handles _PageTabs for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class _PageTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  // Handles _PageTabs for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _PageTabs({required this.selectedIndex, required this.onSelected});

  @override
  // Build the page tabs with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return AppPillSegmentedControl(
      labels: const ['Rated Post', 'Category'],
      selectedIndex: selectedIndex,
      onChanged: onSelected,
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
  final String? label;

  // Handles _FoodIcon for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const _FoodIcon({required this.icon, this.imageUrl, this.label});

  @override
  // Build the visual layout for this food icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFECE7CF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD7C98D)),
      ),
      child: _buildContent(context),
    );
  }

  // Handles _buildContent for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Widget _buildContent(BuildContext context) {
    if (imageUrl?.isNotEmpty == true) {
      return StatisticsRecipeMediaThumbnail(
        mediaPath: imageUrl,
        fallbackIcon: icon,
        size: 36,
        backgroundColor: const Color(0xFFECE7CF),
        iconColor: const Color(0xFF6D642C),
        borderColor: const Color(0xFFD7C98D),
      );
    }

    final text = _circleText(label);
    if (text.isNotEmpty) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: context.text.bodySmall?.copyWith(
            color: const Color(0xFF6D642C),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Icon(icon, size: 18, color: const Color(0xFF6D642C));
  }

  // This helper prepares a value used by the visible report.
  // Keeping it outside build makes the widget tree easier to follow.
  // Handles _circleText for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  String _circleText(String? value) {
    final words = value
        ?.trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words == null || words.isEmpty) return '';
    if (words.length == 1) {
      final word = words.first;
      return word.length <= 2
          ? word.toUpperCase()
          : word.substring(0, 2).toUpperCase();
    }
    return words.take(2).map((word) => word[0].toUpperCase()).join();
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

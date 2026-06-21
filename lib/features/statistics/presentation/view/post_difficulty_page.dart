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
import '../../domain/entities/post_difficulty_statistics.dart';
import '../../domain/usecases/get_post_difficulty_statistics_usecase.dart';
import '../viewmodel/post_difficulty_viewmodel.dart';
import '../widgets/statistics_bar_chart.dart';
import '../widgets/statistics_page_helpers.dart';
import '../widgets/statistics_recipe_media_thumbnail.dart';

/// Groups posted recipes by their difficulty level.
// Handles PostDifficultyPage for this part of the statistics page.
class PostDifficultyPage extends StatelessWidget {
  const PostDifficultyPage({super.key});

  @override
  // Build the post difficulty page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    // The ViewModel reloads totals and tracks the open difficulty group.
    return ChangeNotifierProvider(
      create: (_) => PostDifficultyViewModel(
        getStatisticsUseCase: sl<GetPostDifficultyStatisticsUseCase>(),
      ),
      child: const _PostDifficultyView(),
    );
  }
}

// This widget builds the main content for the post difficulty view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
// Handles _PostDifficultyView for this part of the statistics page.
class _PostDifficultyView extends StatelessWidget {
  const _PostDifficultyView();

  @override
  // Build the post difficulty view with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final viewModel = context.watch<PostDifficultyViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Difficulty Posted',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  // Handles _buildBody for this part of the statistics page.
  Widget _buildBody(BuildContext context, PostDifficultyViewModel viewModel) {
    // Wait for grouped posts before reading difficulty totals.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading difficulty posted...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load difficulty posted',
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
            // Reload all difficulty groups for the chosen period.
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
                    icon: Icons.star_border,
                    title: 'Average Difficulty',
                    value: statistics.averageDifficulty.toStringAsFixed(1),
                  ),
                ),
              ],
            ),
            // Handles SizedBox for this part of the statistics page.
            const SizedBox(height: AppSpacing.lg),
            _DifficultyChartCard(statistics: statistics),
            const SizedBox(height: AppSpacing.lg),
            // Expand a level to see the posts counted in that bar.
            _DifficultyBreakdown(
              groups: statistics.groups,
              expandedDifficulty: viewModel.expandedDifficulty,
              onToggle: viewModel.toggleDifficulty,
            ),
          ],
        ),
      ),
    );
  }
}

// This widget turns the report values into the difficulty chart card.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
// Handles _DifficultyChartCard for this part of the statistics page.
class _DifficultyChartCard extends StatelessWidget {
  final PostDifficultyStatistics statistics;

  const _DifficultyChartCard({required this.statistics});

  @override
  // Build the difficulty chart card from the values supplied by the parent.
  // Labels, scale, and spacing are prepared before the chart is displayed.
  // This method only handles presentation and does not change report data.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final chartWidth = (MediaQuery.sizeOf(context).width - 48).clamp(
      288.0,
      340.0,
    );

    return _SectionCard(
      child: Column(
        children: [
          Text(
            'Difficulty Posted',
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: chartWidth,
            // POST-DIFFICULTY BAR-CHART UI CALL STARTS HERE.
            // Each difficulty group becomes one bar.
            // Draws a bar chart showing post counts for difficulty levels 1-5.
            // Link: PostDifficultyPage -> StatisticsBarChart.
            // Widget file: ../widgets/statistics_bar_chart.dart.
            child: StatisticsBarChart(
              height: chartWidth * 0.74,
              items: statistics.groups
                  .map(
                    (group) => StatisticsBarChartItem(
                      label: '${group.difficulty} Star',
                      value: group.postCount,
                      icon: Icons.star,
                      color: group.color,
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

// This widget displays the detailed difficulty breakdown.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
// Handles _DifficultyBreakdown for this part of the statistics page.
class _DifficultyBreakdown extends StatelessWidget {
  final List<PostDifficultyGroup> groups;
  final int? expandedDifficulty;
  final ValueChanged<int> onToggle;

  // Handles _DifficultyBreakdown for this part of the statistics page.
  const _DifficultyBreakdown({
    required this.groups,
    required this.expandedDifficulty,
    required this.onToggle,
  });

  @override
  // Build the visible rows for the difficulty breakdown.
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
                  'Difficulty Breakdown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                '1 - 5 Star',
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
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
              children: List.generate(groups.length, (index) {
                final group = groups[index];
                return _DifficultySection(
                  group: group,
                  isExpanded: expandedDifficulty == group.difficulty,
                  showDivider: index != groups.length - 1,
                  onTap: () => onToggle(group.difficulty),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// This widget represents one difficulty section in the report.
// It owns the header and the content that belongs to this group.
// The expanded state decides whether the detailed rows are visible.
// Handles _DifficultySection for this part of the statistics page.
class _DifficultySection extends StatelessWidget {
  final PostDifficultyGroup group;
  final bool isExpanded;
  final bool showDivider;
  final VoidCallback onTap;

  // Handles _DifficultySection for this part of the statistics page.
  const _DifficultySection({
    required this.group,
    required this.isExpanded,
    required this.showDivider,
    required this.onTap,
  });

  @override
  // Build the visible rows for the difficulty section.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
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
                // Handles _SoftIcon for this part of the statistics page.
                const _SoftIcon(icon: Icons.star_border),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Stars(count: group.difficulty),
                      // Handles SizedBox for this part of the statistics page.
                      const SizedBox(height: 2),
                      Text(
                        '${group.difficulty} Star Difficulty',
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
                const SizedBox(width: AppSpacing.sm),
                Text(
                  group.postCount.toString(),
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
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...group.posts.map((post) => _PostRow(post: post)),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

// This small widget draws one post row.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _PostRow for this part of the statistics page.
class _PostRow extends StatelessWidget {
  final PostDifficultyItem post;

  const _PostRow({required this.post});

  @override
  // Build the visual layout for this post row.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, yyyy').format(post.date);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.recipeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  date,
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
        ],
      ),
    );
  }
}

// This helper draws the reusable stars.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
// Handles _Stars for this part of the statistics page.
class _Stars extends StatelessWidget {
  final int count;

  const _Stars({required this.count});

  @override
  // Build the visual layout for this stars.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < count;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          color: filled ? const Color(0xFFFFB300) : AppColors.border,
          size: 15,
        );
      }),
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
                // Handles SizedBox for this part of the statistics page.
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

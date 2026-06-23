// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../app/routers/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../../../core/widgets/tabs/app_pill_segmented_control.dart';
import '../../domain/entities/statistics_dashboard.dart';
import '../viewmodel/statistics_viewmodel.dart';
import '../widgets/ai_lifestyle_insight_card.dart';

/// User dashboard with summary cards and links to detailed statistics.
// Handles UserStatisticsView for this part of the statistics page.
class UserStatisticsView extends StatefulWidget {
  final bool isAdmin;

  const UserStatisticsView({super.key, required this.isAdmin});

  // Handles createState for this part of the statistics page.
  @override
  State<UserStatisticsView> createState() => _UserStatisticsViewState();
}

// This state object manages the changing parts of the user statistics view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
// Handles _UserStatisticsViewState for this part of the statistics page.
class _UserStatisticsViewState extends State<UserStatisticsView> {
  late final PageController _heroController;

  // Handles initState for this part of the statistics page.
  @override
  void initState() {
    super.initState();
    _heroController = PageController();
  }

  // Handles dispose for this part of the statistics page.
  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  // Build the user statistics view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    // `watch` rebuilds this page whenever the ViewModel changes.
    final viewModel = context.watch<StatisticsViewModel>();

    // Only show the full loading view when there is no old data to display.
    if (viewModel.isLoading && viewModel.dashboard == null) {
      return const LoadingDialog(inline: true, message: 'Loading statistic...');
    }

    final dashboard = viewModel.dashboard;
    if (dashboard == null) {
      return _StatisticsError(
        message: viewModel.errorMessage ?? 'Unable to load statistics',
        onRetry: viewModel.loadStatistics,
      );
    }
    // The selected audience changes both the hero cards and menu options.
    final selectedMenuItems = viewModel.selectedAudienceIndex == 0
        ? dashboard.menuItems
        : dashboard.communityMenuItems;
    final selectedHeroSlides = viewModel.selectedAudienceIndex == 1
        ? (dashboard.communityHeroSlides.isNotEmpty
              ? dashboard.communityHeroSlides
              : _emptyCommunityHeroSlides)
        : dashboard.heroSlides;
    // Keep the page index valid when switching between Self and Community.
    final selectedHeroIndex = viewModel.selectedHeroIndex.clamp(
      0,
      selectedHeroSlides.length - 1,
    );

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatisticsHeroPager(
                    controller: _heroController,
                    slides: selectedHeroSlides,
                    selectedIndex: selectedHeroIndex,
                    onPageChanged: viewModel.selectHero,
                  ),
                  // Handles SizedBox for this part of the statistics page.
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: AppPillSegmentedControl(
                      labels: const ['Self', 'Community'],
                      selectedIndex: viewModel.selectedAudienceIndex,
                      onChanged: viewModel.selectAudience,
                    ),
                  ),
                  // Handles SizedBox for this part of the statistics page.
                  const SizedBox(height: AppSpacing.lg),
                  if (viewModel.selectedAudienceIndex == 0) ...[
                    AiLifestyleInsightCard(
                      onViewDetail: () =>
                          context.push(AppRouter.aiLifestyleInsight),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _StatisticsMenu(items: selectedMenuItems),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// This widget controls the statistics hero pager used to move between report views.
// The selected index comes from the parent or ViewModel.
// User changes are sent back through the provided callback.
// Handles _StatisticsHeroPager for this part of the statistics page.
class _StatisticsHeroPager extends StatelessWidget {
  final PageController controller;
  final List<StatisticsHeroSlide> slides;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;

  // Handles _StatisticsHeroPager for this part of the statistics page.
  const _StatisticsHeroPager({
    required this.controller,
    required this.slides,
    required this.selectedIndex,
    required this.onPageChanged,
  });

  @override
  // Build the statistics hero pager with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    // Adjust the card height for small screens and accessibility text.
    final width = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.25);
    final cardHeight = (width < 360 ? 178.0 : 188.0) * textScale;

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            controller: controller,
            itemCount: slides.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: _StatisticsHeroCard(slide: slides[index]),
              );
            },
          ),
        ),
        // Handles SizedBox for this part of the statistics page.
        const SizedBox(height: AppSpacing.md),
        _PageDots(count: slides.length, selectedIndex: selectedIndex),
      ],
    );
  }
}

// This widget groups related information inside the statistics hero card.
// The card gives the section a clear visual boundary on the page.
// Its parent supplies all values, labels, and interaction callbacks.
// Handles _StatisticsHeroCard for this part of the statistics page.
class _StatisticsHeroCard extends StatelessWidget {
  final StatisticsHeroSlide slide;

  const _StatisticsHeroCard({required this.slide});

  @override
  // Build the statistics hero card with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            slide.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(height: 8),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  // Handles _buildContent for this part of the statistics page.
  Widget _buildContent(BuildContext context) {
    // Each slide type has a different layout but uses the same slide data.
    switch (slide.type) {
      case StatisticsHeroSlideType.overview:
        return _OverviewSlide(slide: slide);
      case StatisticsHeroSlideType.appUsage:
        return _AppUsageSlide(slide: slide);
      case StatisticsHeroSlideType.achievement:
        return _AchievementSlide(slide: slide);
    }
  }
}

// This helper is responsible for the overview slide part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
// Handles _OverviewSlide for this part of the statistics page.
class _OverviewSlide extends StatelessWidget {
  final StatisticsHeroSlide slide;

  const _OverviewSlide({required this.slide});

  @override
  // Build the overview slide with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final isCommunitySlide = slide.title.startsWith('Community');
    if (isCommunitySlide) {
      return _CommunityOverviewSlide(slide: slide);
    }

    final topMetrics = slide.metrics.take(2).toList();
    final streakMetrics = slide.metrics.skip(2).take(2).toList();

    return Column(
      children: [
        Expanded(
          child: Row(
            children: topMetrics
                .map(
                  (metric) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: _MetricTile(metric: metric, largeValue: true),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        // Handles SizedBox for this part of the statistics page.
        const SizedBox(height: 5),
        Expanded(
          child: Row(
            children: streakMetrics
                .map(
                  (metric) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: _MetricTile(metric: metric),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

// This helper is responsible for the community overview slide part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
// Handles _CommunityOverviewSlide for this part of the statistics page.
class _CommunityOverviewSlide extends StatelessWidget {
  final StatisticsHeroSlide slide;

  const _CommunityOverviewSlide({required this.slide});

  @override
  // Build the community overview slide with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final metrics = slide.metrics.take(4).toList();

    return Column(
      children: [
        Expanded(child: _CommunityMetricRow(metrics: metrics.take(2).toList())),
        // Handles SizedBox for this part of the statistics page.
        const SizedBox(height: AppSpacing.sm),
        Expanded(child: _CommunityMetricRow(metrics: metrics.skip(2).toList())),
      ],
    );
  }
}

// This small widget draws one community metric row.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _CommunityMetricRow for this part of the statistics page.
class _CommunityMetricRow extends StatelessWidget {
  final List<StatisticsMetric> metrics;

  const _CommunityMetricRow({required this.metrics});

  @override
  // Build the visual layout for this community metric row.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Row(
      children: metrics
          .map(
            (metric) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: _MetricTile(
                  metric: metric,
                  valueColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  valueFontSize: 18,
                  labelFontSize: 11,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

final _emptyCommunityHeroSlides = [
  // Handles StatisticsHeroSlide for this part of the statistics page.
  const StatisticsHeroSlide(
    title: 'Community Posts',
    type: StatisticsHeroSlideType.overview,
    metrics: [
      StatisticsMetric(
        label: 'Total Post',
        value: '0',
        tone: StatisticsMetricTone.positive,
      ),
      StatisticsMetric(
        label: 'Total Rating',
        value: '0',
        tone: StatisticsMetricTone.positive,
      ),
      StatisticsMetric(
        label: 'Average Rating',
        value: '0.0',
        tone: StatisticsMetricTone.positive,
      ),
      StatisticsMetric(
        label: 'Comments',
        value: '0',
        tone: StatisticsMetricTone.positive,
      ),
    ],
  ),
  // Handles StatisticsHeroSlide for this part of the statistics page.
  const StatisticsHeroSlide(
    title: 'Community Engagement',
    type: StatisticsHeroSlideType.overview,
    metrics: [
      StatisticsMetric(
        label: 'Total Views',
        value: '0',
        tone: StatisticsMetricTone.positive,
      ),
      StatisticsMetric(
        label: 'Shared Recipe',
        value: '0',
        tone: StatisticsMetricTone.positive,
      ),
      StatisticsMetric(
        label: 'Top Rated',
        value: '-',
        tone: StatisticsMetricTone.positive,
      ),
      StatisticsMetric(
        label: 'Most Rated',
        value: '-',
        tone: StatisticsMetricTone.positive,
      ),
    ],
  ),
];

// This helper is responsible for the app usage slide part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
// Handles _AppUsageSlide for this part of the statistics page.
class _AppUsageSlide extends StatelessWidget {
  final StatisticsHeroSlide slide;

  const _AppUsageSlide({required this.slide});

  @override
  // Build the app usage slide with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final days = slide.metrics.first;
    final planned = slide.metrics[1];
    final unplanned = slide.metrics[2];
    final progress = slide.progress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${days.value} Days',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        // Handles SizedBox for this part of the statistics page.
        const SizedBox(height: 10),
        _UsageRow(metric: planned),
        const SizedBox(height: 6),
        _UsageRow(metric: unplanned),
        // Handles Spacer for this part of the statistics page.
        const Spacer(),
        if (progress != null) _ProgressSplit(progress: progress),
      ],
    );
  }
}

// This helper is responsible for the achievement slide part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
// Handles _AchievementSlide for this part of the statistics page.
class _AchievementSlide extends StatelessWidget {
  final StatisticsHeroSlide slide;

  const _AchievementSlide({required this.slide});

  @override
  // Build the achievement slide with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final metrics = slide.metrics;

    return Column(
      children: [
        Expanded(
          child: Row(
            children: metrics
                .take(2)
                .map((metric) => _AchievementMetricTile(metric: metric))
                .toList(),
          ),
        ),
        // Handles SizedBox for this part of the statistics page.
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Row(
            children: metrics
                .skip(2)
                .take(2)
                .map((metric) => _AchievementMetricTile(metric: metric))
                .toList(),
          ),
        ),
      ],
    );
  }
}

// This small widget draws one achievement metric tile.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _AchievementMetricTile for this part of the statistics page.
class _AchievementMetricTile extends StatelessWidget {
  final StatisticsMetric metric;

  const _AchievementMetricTile({required this.metric});

  @override
  // Build the visual layout for this achievement metric tile.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: _MetricTile(
          metric: metric,
          valueColor: AppColors.textSecondary,
          labelColor: AppColors.primary,
          valueFontSize: 16,
          labelFontSize: 10,
          suffixFontSize: 10,
        ),
      ),
    );
  }
}

// This small widget draws one metric tile.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _MetricTile for this part of the statistics page.
class _MetricTile extends StatelessWidget {
  final StatisticsMetric metric;
  final bool largeValue;
  final Color? valueColor;
  final Color? labelColor;
  final double? valueFontSize;
  final double? labelFontSize;
  final double? suffixFontSize;

  // Handles _MetricTile for this part of the statistics page.
  const _MetricTile({
    required this.metric,
    this.largeValue = false,
    this.valueColor,
    this.labelColor,
    this.valueFontSize,
    this.labelFontSize,
    this.suffixFontSize,
  });

  @override
  // Build the visual layout for this metric tile.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final toneColor = _toneColor(metric.tone);
    final resolvedValueColor =
        valueColor ?? (largeValue ? toneColor : AppColors.textSecondary);
    final resolvedLabelColor = labelColor ?? toneColor;
    final resolvedValueFontSize = valueFontSize ?? (largeValue ? 24 : 14);

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MetricValue(
            metric: metric,
            color: resolvedValueColor,
            fontSize: resolvedValueFontSize,
            suffixFontSize: suffixFontSize,
          ),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(height: 5),
          _MetricLabel(
            metric: metric,
            color: resolvedLabelColor,
            fontSize: labelFontSize,
          ),
        ],
      ),
    );
  }
}

// This object keeps the values needed by the metric value together.
// It is only used to prepare display data for this page.
// No loading or database work happens inside this object.
// Handles _MetricValue for this part of the statistics page.
class _MetricValue extends StatelessWidget {
  final StatisticsMetric metric;
  final Color color;
  final double fontSize;
  final double? suffixFontSize;

  // Handles _MetricValue for this part of the statistics page.
  const _MetricValue({
    required this.metric,
    required this.color,
    this.fontSize = 14,
    this.suffixFontSize,
  });

  @override
  // Build the metric value with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: metric.value,
        children: [
          if (metric.suffix != null)
            TextSpan(
              text: ' ${metric.suffix}',
              style: TextStyle(fontSize: suffixFontSize ?? 10),
            ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: context.text.titleMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        height: 1,
      ),
    );
  }
}

// This object keeps the values needed by the metric label together.
// It is only used to prepare display data for this page.
// No loading or database work happens inside this object.
// Handles _MetricLabel for this part of the statistics page.
class _MetricLabel extends StatelessWidget {
  final StatisticsMetric metric;
  final Color color;
  final double? fontSize;

  // Handles _MetricLabel for this part of the statistics page.
  const _MetricLabel({
    required this.metric,
    required this.color,
    this.fontSize,
  });

  @override
  // Build the metric label with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Text(
      metric.label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: context.text.bodySmall?.copyWith(
        color: color,
        fontSize: fontSize ?? 10,
        fontWeight: FontWeight.w500,
        height: 1.12,
      ),
    );
  }
}

// This small widget draws one usage row.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _UsageRow for this part of the statistics page.
class _UsageRow extends StatelessWidget {
  final StatisticsMetric metric;

  const _UsageRow({required this.metric});

  @override
  // Build the visual layout for this usage row.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final color = _toneColor(metric.tone);

    return Row(
      children: [
        Expanded(
          child: Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Handles SizedBox for this part of the statistics page.
        const SizedBox(width: AppSpacing.sm),
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// This helper is responsible for the progress split part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
// Handles _ProgressSplit for this part of the statistics page.
class _ProgressSplit extends StatelessWidget {
  final StatisticsProgress progress;

  const _ProgressSplit({required this.progress});

  @override
  // Build the progress split with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${(progress.positivePercent * 100).round()}%',
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${(progress.negativePercent * 100).round()}%',
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.error,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        // Handles SizedBox for this part of the statistics page.
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Row(
            children: [
              Expanded(
                flex: (progress.positivePercent * 100).round(),
                child: Container(height: 5, color: AppColors.primary),
              ),
              Expanded(
                flex: (progress.negativePercent * 100).round(),
                child: Container(height: 5, color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// This widget controls the page dots used to move between report views.
// The selected index comes from the parent or ViewModel.
// User changes are sent back through the provided callback.
// Handles _PageDots for this part of the statistics page.
class _PageDots extends StatelessWidget {
  final int count;
  final int selectedIndex;

  // Handles _PageDots for this part of the statistics page.
  const _PageDots({required this.count, required this.selectedIndex});

  @override
  // Build the page dots with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
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

// This helper is responsible for the statistics menu part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
// Handles _StatisticsMenu for this part of the statistics page.
class _StatisticsMenu extends StatelessWidget {
  final List<StatisticsMenuItem> items;

  const _StatisticsMenu({required this.items});

  @override
  // Build the statistics menu with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => InkWell(
              onTap: () => _handleTap(context, item),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Handles SizedBox for this part of the statistics page.
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.chevron_right,
                      size: 23,
                      color: AppColors.textPrimary.withValues(alpha: 0.82),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  // Match the selected menu item with its destination page.
  // Navigation stays here so the menu layout remains simple.
  // Handles _handleTap for this part of the statistics page.
  void _handleTap(BuildContext context, StatisticsMenuItem item) {
    // Menu titles come from the dashboard data. Map each title to its page.
    if (item.title == 'AI Lifestyle Insight') {
      context.push(AppRouter.aiLifestyleInsight);
      return;
    }

    if (item.title == 'Food Analytic') {
      context.push(AppRouter.foodAnalytic);
      return;
    }

    if (item.title == 'Time Taken For Cooking') {
      context.push(AppRouter.cookingTime);
      return;
    }

    if (item.title == 'Grocery List') {
      context.push(AppRouter.groceryListStatistics);
      return;
    }

    if (item.title == 'Meal Planned Time') {
      context.push(AppRouter.mealPlannedTime);
      return;
    }

    if (item.title == 'Nutrient Insight') {
      context.push(AppRouter.nutrientIntakeInsight);
      return;
    }

    if (item.title == 'Nutrient Intake' || item.title == 'Calories Intake') {
      context.push(AppRouter.caloriesIntake);
      return;
    }

    if (item.title == 'Difficulty') {
      context.push(AppRouter.difficultyMeals);
      return;
    }

    if (item.title == 'Method For Creating Plan') {
      context.push(AppRouter.mealPlanMethods);
      return;
    }

    if (item.title == 'Post Analytic') {
      context.push(AppRouter.postAnalytic);
      return;
    }

    if (item.title == 'Posted Nutrient Insight') {
      context.push(AppRouter.postedNutrientInsight);
      return;
    }

    if (item.title == 'Most Nutrient Posted Meal' ||
        item.title == 'Most Calories Posted Meal') {
      context.push(AppRouter.caloriesPosted);
      return;
    }

    if (item.title == 'Recipe Performance') {
      context.push(AppRouter.recipePerformance);
      return;
    }

    if (item.title == 'Most Cooked Recipe By Others') {
      context.push(AppRouter.mostCookedRecipes);
      return;
    }

    if (item.title == 'Difficulty Posted') {
      context.push(AppRouter.postDifficulty);
    }
  }
}

// This widget shows the statistics error when report data is unavailable.
// It explains the problem and gives the user a retry action.
// The retry callback asks the ViewModel to load the report again.
// Handles _StatisticsError for this part of the statistics page.
class _StatisticsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  // Handles _StatisticsError for this part of the statistics page.
  const _StatisticsError({required this.message, required this.onRetry});

  @override
  // Build the statistics error with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', height: 140),
            // Handles SizedBox for this part of the statistics page.
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            // Handles SizedBox for this part of the statistics page.
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

// Handles _toneColor for this part of the statistics page.
Color _toneColor(StatisticsMetricTone tone) {
  switch (tone) {
    case StatisticsMetricTone.positive:
      return AppColors.primary;
    case StatisticsMetricTone.negative:
      return AppColors.error;
    case StatisticsMetricTone.neutral:
      return AppColors.textSecondary;
  }
}

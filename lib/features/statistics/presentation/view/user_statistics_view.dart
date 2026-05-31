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

class UserStatisticsView extends StatefulWidget {
  final bool isAdmin;

  const UserStatisticsView({super.key, required this.isAdmin});

  @override
  State<UserStatisticsView> createState() => _UserStatisticsViewState();
}

class _UserStatisticsViewState extends State<UserStatisticsView> {
  late final PageController _heroController;

  @override
  void initState() {
    super.initState();
    _heroController = PageController();
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StatisticsViewModel>();

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
    final selectedMenuItems = viewModel.selectedAudienceIndex == 0
        ? dashboard.menuItems
        : dashboard.communityMenuItems;
    final selectedHeroSlides = viewModel.selectedAudienceIndex == 1
        ? (dashboard.communityHeroSlides.isNotEmpty
              ? dashboard.communityHeroSlides
              : _emptyCommunityHeroSlides)
        : dashboard.heroSlides;
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
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: AppPillSegmentedControl(
                      labels: const ['Self', 'Community'],
                      selectedIndex: viewModel.selectedAudienceIndex,
                      onChanged: viewModel.selectAudience,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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

class _StatisticsHeroPager extends StatelessWidget {
  final PageController controller;
  final List<StatisticsHeroSlide> slides;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;

  const _StatisticsHeroPager({
    required this.controller,
    required this.slides,
    required this.selectedIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: AppSpacing.md),
        _PageDots(count: slides.length, selectedIndex: selectedIndex),
      ],
    );
  }
}

class _StatisticsHeroCard extends StatelessWidget {
  final StatisticsHeroSlide slide;

  const _StatisticsHeroCard({required this.slide});

  @override
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
          const SizedBox(height: 8),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
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

class _OverviewSlide extends StatelessWidget {
  final StatisticsHeroSlide slide;

  const _OverviewSlide({required this.slide});

  @override
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

class _CommunityOverviewSlide extends StatelessWidget {
  final StatisticsHeroSlide slide;

  const _CommunityOverviewSlide({required this.slide});

  @override
  Widget build(BuildContext context) {
    final metrics = slide.metrics.take(4).toList();

    return Column(
      children: [
        Expanded(child: _CommunityMetricRow(metrics: metrics.take(2).toList())),
        const SizedBox(height: AppSpacing.sm),
        Expanded(child: _CommunityMetricRow(metrics: metrics.skip(2).toList())),
      ],
    );
  }
}

class _CommunityMetricRow extends StatelessWidget {
  final List<StatisticsMetric> metrics;

  const _CommunityMetricRow({required this.metrics});

  @override
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

class _AppUsageSlide extends StatelessWidget {
  final StatisticsHeroSlide slide;

  const _AppUsageSlide({required this.slide});

  @override
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
        const SizedBox(height: 10),
        _UsageRow(metric: planned),
        const SizedBox(height: 6),
        _UsageRow(metric: unplanned),
        const Spacer(),
        if (progress != null) _ProgressSplit(progress: progress),
      ],
    );
  }
}

class _AchievementSlide extends StatelessWidget {
  final StatisticsHeroSlide slide;

  const _AchievementSlide({required this.slide});

  @override
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

class _AchievementMetricTile extends StatelessWidget {
  final StatisticsMetric metric;

  const _AchievementMetricTile({required this.metric});

  @override
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

class _MetricTile extends StatelessWidget {
  final StatisticsMetric metric;
  final bool largeValue;
  final Color? valueColor;
  final Color? labelColor;
  final double? valueFontSize;
  final double? labelFontSize;
  final double? suffixFontSize;

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

class _MetricValue extends StatelessWidget {
  final StatisticsMetric metric;
  final Color color;
  final double fontSize;
  final double? suffixFontSize;

  const _MetricValue({
    required this.metric,
    required this.color,
    this.fontSize = 14,
    this.suffixFontSize,
  });

  @override
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

class _MetricLabel extends StatelessWidget {
  final StatisticsMetric metric;
  final Color color;
  final double? fontSize;

  const _MetricLabel({
    required this.metric,
    required this.color,
    this.fontSize,
  });

  @override
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

class _UsageRow extends StatelessWidget {
  final StatisticsMetric metric;

  const _UsageRow({required this.metric});

  @override
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

class _ProgressSplit extends StatelessWidget {
  final StatisticsProgress progress;

  const _ProgressSplit({required this.progress});

  @override
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

class _StatisticsMenu extends StatelessWidget {
  final List<StatisticsMenuItem> items;

  const _StatisticsMenu({required this.items});

  @override
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

  void _handleTap(BuildContext context, StatisticsMenuItem item) {
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

class _StatisticsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _StatisticsError({required this.message, required this.onRetry});

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

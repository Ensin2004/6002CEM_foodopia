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
import '../widgets/statistics_page_helpers.dart';

class AdminStatisticsView extends StatefulWidget {
  const AdminStatisticsView({super.key});

  @override
  State<AdminStatisticsView> createState() => _AdminStatisticsViewState();
}

class _AdminStatisticsViewState extends State<AdminStatisticsView> {
  late final PageController _summaryController;

  @override
  void initState() {
    super.initState();
    _summaryController = PageController();
  }

  @override
  void dispose() {
    _summaryController.dispose();
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
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load statistics',
        onRetry: viewModel.loadStatistics,
      );
    }

    final selectedMenuItems = viewModel.selectedAudienceIndex == 0
        ? dashboard.menuItems
        : dashboard.communityMenuItems;

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
                  _AdminSummaryPager(
                    controller: _summaryController,
                    slides: dashboard.heroSlides,
                    selectedIndex: viewModel.selectedHeroIndex,
                    onPageChanged: viewModel.selectHero,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: AppPillSegmentedControl(
                      labels: const ['System', 'Setting'],
                      selectedIndex: viewModel.selectedAudienceIndex,
                      onChanged: viewModel.selectAudience,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _AdminStatisticActions(items: selectedMenuItems),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminSummaryPager extends StatelessWidget {
  final PageController controller;
  final List<StatisticsHeroSlide> slides;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;

  const _AdminSummaryPager({
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
    final cardHeight = (width < 360 ? 236.0 : 246.0) * textScale;

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
                child: _AdminSummaryCard(slide: slides[index]),
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

class _AdminSummaryCard extends StatelessWidget {
  final StatisticsHeroSlide slide;

  const _AdminSummaryCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
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
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: slide.metrics.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.72,
              ),
              itemBuilder: (context, index) {
                return _AdminMetricTile(metric: slide.metrics[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMetricTile extends StatelessWidget {
  final StatisticsMetric metric;

  const _AdminMetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    final toneColor = _toneColor(metric.tone);

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                text: metric.value,
                children: [
                  if (metric.suffix != null)
                    TextSpan(
                      text: ' ${metric.suffix}',
                      style: const TextStyle(fontSize: 10),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleMedium?.copyWith(
                color: toneColor,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 118,
              child: Text(
                metric.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStatisticActions extends StatelessWidget {
  final List<StatisticsMenuItem> items;

  const _AdminStatisticActions({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => InkWell(
              onTap: () => _handleTap(context, item),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 11,
                ),
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
    if (item.title == 'Planned Meal Analytic') {
      context.push(AppRouter.adminMealAnalytic);
      return;
    }

    if (item.title == 'Post Analytic') {
      context.push(AppRouter.adminPostAnalytic);
      return;
    }

    if (item.title == 'Dietary Preference') {
      context.push(AppRouter.adminDietaryPreference);
    }
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

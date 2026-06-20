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
import '../widgets/statistics_page_helpers.dart';

/// Admin dashboard with system summaries and links to admin reports.
// Handles AdminStatisticsView for this part of the statistics page.
class AdminStatisticsView extends StatefulWidget {
  const AdminStatisticsView({super.key});

  // Handles createState for this part of the statistics page.
  @override
  State<AdminStatisticsView> createState() => _AdminStatisticsViewState();
}

// This state object manages the changing parts of the admin statistics view state.
// It listens to user actions and rebuilds the affected widgets.
// Controllers and other temporary UI values also belong here.
// Handles _AdminStatisticsViewState for this part of the statistics page.
class _AdminStatisticsViewState extends State<AdminStatisticsView> {
  late final PageController _summaryController;

  // Handles initState for this part of the statistics page.
  @override
  void initState() {
    super.initState();
    _summaryController = PageController();
  }

  // Handles dispose for this part of the statistics page.
  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  @override
  // Build the admin statistics view state with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    // Listen for loaded data and dashboard selection changes.
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

    // System and Setting use different action lists.
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
                  // Handles SizedBox for this part of the statistics page.
                  const SizedBox(height: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: AppPillSegmentedControl(
                      labels: const ['System', 'Setting'],
                      selectedIndex: viewModel.selectedAudienceIndex,
                      onChanged: viewModel.selectAudience,
                    ),
                  ),
                  // Handles SizedBox for this part of the statistics page.
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

// This widget controls the admin summary pager used to move between report views.
// The selected index comes from the parent or ViewModel.
// User changes are sent back through the provided callback.
// Handles _AdminSummaryPager for this part of the statistics page.
class _AdminSummaryPager extends StatelessWidget {
  final PageController controller;
  final List<StatisticsHeroSlide> slides;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;

  // Handles _AdminSummaryPager for this part of the statistics page.
  const _AdminSummaryPager({
    required this.controller,
    required this.slides,
    required this.selectedIndex,
    required this.onPageChanged,
  });

  @override
  // Build the admin summary pager with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    // Give admin cards more height because every slide contains four metrics.
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
        // Handles SizedBox for this part of the statistics page.
        const SizedBox(height: AppSpacing.md),
        _PageDots(count: slides.length, selectedIndex: selectedIndex),
      ],
    );
  }
}

// This widget groups related information inside the admin summary card.
// The card gives the section a clear visual boundary on the page.
// Its parent supplies all values, labels, and interaction callbacks.
// Handles _AdminSummaryCard for this part of the statistics page.
class _AdminSummaryCard extends StatelessWidget {
  final StatisticsHeroSlide slide;

  const _AdminSummaryCard({required this.slide});

  @override
  // Build the admin summary card with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
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
          // Handles SizedBox for this part of the statistics page.
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

// This small widget draws one admin metric tile.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _AdminMetricTile for this part of the statistics page.
class _AdminMetricTile extends StatelessWidget {
  final StatisticsMetric metric;

  const _AdminMetricTile({required this.metric});

  @override
  // Build the visual layout for this admin metric tile.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.text.titleMedium?.copyWith(
              color: toneColor,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              height: 1,
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(height: 6),
          Text(
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
        ],
      ),
    );
  }
}

// This helper is responsible for the admin statistic actions part of the screen.
// It keeps one focused piece of presentation logic outside the main layout.
// The parent widget passes in the data that this helper needs.
// Handles _AdminStatisticActions for this part of the statistics page.
class _AdminStatisticActions extends StatelessWidget {
  final List<StatisticsMenuItem> items;

  const _AdminStatisticActions({required this.items});

  @override
  // Build the admin statistic actions with the latest available state.
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
    // Convert the selected dashboard action into its detail-page route.
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
      return;
    }

    if (item.title == 'Gender') {
      context.push(AppRouter.adminGender);
      return;
    }

    if (item.title == 'User Usage') {
      context.push(AppRouter.adminUserUsage);
      return;
    }

    if (item.title == 'Usage Forecast') {
      context.push(AppRouter.adminUsageForecast);
      return;
    }

    if (item.title == 'Nutrient Insight') {
      context.push(AppRouter.adminNutrientInsight);
      return;
    }

    if (item.title == 'Hub Rating') {
      context.push(AppRouter.adminHubRating);
    }
  }
}

// This widget controls the page dots used to move between report views.
// The selected index comes from the parent or ViewModel.
// User changes are sent back through the provided callback.
// Handles _PageDots for this part of the statistics page.
class _PageDots extends StatelessWidget {
  // One dot is created for every summary card in the PageView.
  // The larger green dot tells the admin which card is currently visible.
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

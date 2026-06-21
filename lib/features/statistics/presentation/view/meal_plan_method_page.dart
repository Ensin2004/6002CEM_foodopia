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
import '../../domain/entities/meal_plan_method_statistics.dart';
import '../../domain/usecases/get_meal_plan_method_statistics_usecase.dart';
import '../viewmodel/meal_plan_method_viewmodel.dart';
import '../widgets/statistics_page_helpers.dart';
import '../widgets/statistics_recipe_media_thumbnail.dart';
import '../widgets/statistics_pie_chart.dart';

/// Shows which methods the user used to create meal plans.
// Handles MealPlanMethodPage for this part of the statistics page.
class MealPlanMethodPage extends StatelessWidget {
  const MealPlanMethodPage({super.key});

  @override
  // Build the meal plan method page with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    // The ViewModel loads totals and remembers the expanded method.
    return ChangeNotifierProvider(
      create: (_) => MealPlanMethodViewModel(
        getStatisticsUseCase: sl<GetMealPlanMethodStatisticsUseCase>(),
      ),
      child: const _MealPlanMethodView(),
    );
  }
}

// This widget builds the main content for the meal plan method view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
// Handles _MealPlanMethodView for this part of the statistics page.
class _MealPlanMethodView extends StatelessWidget {
  const _MealPlanMethodView();

  @override
  // Build the meal plan method view with the latest available state.
  // This method arranges the section widgets in the order seen on screen.
  // User interaction is forwarded through callbacks instead of stored here.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final viewModel = context.watch<MealPlanMethodViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Method To Create Plan',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  // Handles _buildBody for this part of the statistics page.
  Widget _buildBody(BuildContext context, MealPlanMethodViewModel viewModel) {
    // Wait for data before drawing method totals.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading meal plan methods...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return _MethodError(
        message: viewModel.errorMessage ?? 'Unable to load meal plan methods',
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
            // Reload the method report for the chosen dates.
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
                    icon: Icons.event_available,
                    title: 'Total Method Used',
                    value: statistics.totalMethodUsed.toString(),
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.room_service_outlined,
                    title: 'Top Method',
                    value: statistics.topMethod,
                  ),
                ),
              ],
            ),
            // Handles SizedBox for this part of the statistics page.
            const SizedBox(height: AppSpacing.lg),
            _MethodChartCard(statistics: statistics),
            const SizedBox(height: AppSpacing.lg),
            // Expand a method to show the plans created with it.
            _MethodBreakdown(
              groups: statistics.groups,
              expandedIndex: viewModel.expandedIndex,
              onToggle: viewModel.toggleMethod,
            ),
          ],
        ),
      ),
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
                  child: Text(
                    dateRange,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                    ),
                  ),
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

// This widget turns the report values into the method chart card.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
// Handles _MethodChartCard for this part of the statistics page.
class _MethodChartCard extends StatelessWidget {
  final MealPlanMethodStatistics statistics;

  const _MethodChartCard({required this.statistics});

  @override
  // Build the method chart card from the values supplied by the parent.
  // Labels, scale, and spacing are prepared before the chart is displayed.
  // This method only handles presentation and does not change report data.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final chartSize = MediaQuery.sizeOf(context).width < 360 ? 238.0 : 260.0;

    return Container(
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
            'Method Used',
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(height: AppSpacing.md),
          // MEAL-PLAN-METHOD PIE-CHART UI CALL STARTS HERE.
          // Each plan creation method becomes one pie segment.
          // Draws a pie chart showing how each meal plan was created.
          // Link: MealPlanMethodPage -> StatisticsPieChart.
          // Widget file: ../widgets/statistics_pie_chart.dart.
          StatisticsPieChart(
            size: chartSize,
            centerTitle: 'Total\nMeals',
            centerValue: statistics.totalMethodUsed.toString(),
            segments: statistics.groups
                .map(
                  (group) => StatisticsPieChartSegment(
                    label: group.title,
                    value: group.totalUsed,
                    color: group.color,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// This widget displays the detailed method breakdown.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
// Handles _MethodBreakdown for this part of the statistics page.
class _MethodBreakdown extends StatelessWidget {
  final List<MealPlanMethodGroup> groups;
  final int? expandedIndex;
  final ValueChanged<int> onToggle;

  // Handles _MethodBreakdown for this part of the statistics page.
  const _MethodBreakdown({
    required this.groups,
    required this.expandedIndex,
    required this.onToggle,
  });

  @override
  // Build the visible rows for the method breakdown.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Meal Breakdown',
            style: context.text.titleMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
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
                final isExpanded = expandedIndex == index;
                return _MethodSection(
                  group: group,
                  isExpanded: isExpanded,
                  showDivider: index != groups.length - 1,
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

// This widget represents one method section in the report.
// It owns the header and the content that belongs to this group.
// The expanded state decides whether the detailed rows are visible.
// Handles _MethodSection for this part of the statistics page.
class _MethodSection extends StatelessWidget {
  final MealPlanMethodGroup group;
  final bool isExpanded;
  final bool showDivider;
  final VoidCallback onTap;

  // Handles _MethodSection for this part of the statistics page.
  const _MethodSection({
    required this.group,
    required this.isExpanded,
    required this.showDivider,
    required this.onTap,
  });

  @override
  // Build the visible rows for the method section.
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
                _SoftIcon(icon: group.icon),
                // Handles SizedBox for this part of the statistics page.
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Total Used',
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
                  group.totalUsed.toString(),
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
        if (isExpanded)
          ...group.meals.map((meal) => _MethodMealRow(meal: meal)),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

// This small widget draws one method meal row.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
// Handles _MethodMealRow for this part of the statistics page.
class _MethodMealRow extends StatelessWidget {
  final MealPlanMethodItem meal;

  const _MethodMealRow({required this.meal});

  @override
  // Build the visual layout for this method meal row.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  // Handles build for this part of the statistics page.
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, yyyy').format(meal.date);

    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 7,
      ),
      child: Row(
        children: [
          _FoodIcon(icon: meal.icon, imageUrl: meal.imageUrl),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.recipeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$date - ${meal.mealTime}',
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
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(width: AppSpacing.sm),
          Text(
            meal.quantity.toString(),
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

// This widget shows the method error when report data is unavailable.
// It explains the problem and gives the user a retry action.
// The retry callback asks the ViewModel to load the report again.
// Handles _MethodError for this part of the statistics page.
class _MethodError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  // Handles _MethodError for this part of the statistics page.
  const _MethodError({required this.message, required this.onRetry});

  @override
  // Build the method error with the latest available state.
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

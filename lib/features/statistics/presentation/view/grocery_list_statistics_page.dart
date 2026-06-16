import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../app/dependency_injection/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../../domain/entities/grocery_list_statistics.dart';
import '../../domain/usecases/get_grocery_list_statistics_usecase.dart';
import '../viewmodel/grocery_list_statistics_viewmodel.dart';
import '../widgets/statistics_line_chart.dart';
import '../widgets/statistics_page_helpers.dart';

/// Compares grocery-list activity across months.
class GroceryListStatisticsPage extends StatelessWidget {
  const GroceryListStatisticsPage({super.key});

  @override
  // Build the visible rows for the grocery list statistics page.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  Widget build(BuildContext context) {
    // The ViewModel reloads the report and tracks the expanded month.
    return ChangeNotifierProvider(
      create: (_) => GroceryListStatisticsViewModel(
        getStatisticsUseCase: sl<GetGroceryListStatisticsUseCase>(),
      ),
      child: const _GroceryListStatisticsView(),
    );
  }
}

// This widget builds the main content for the grocery list statistics view.
// It reads the ViewModel and chooses loading, error, or data content.
// Smaller widgets below handle the individual visual sections.
class _GroceryListStatisticsView extends StatelessWidget {
  const _GroceryListStatisticsView();

  @override
  // Build the visible rows for the grocery list statistics view.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroceryListStatisticsViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Grocery List',
        leading: StatisticsBackButton(),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GroceryListStatisticsViewModel viewModel,
  ) {
    // Keep loading, error, and loaded content as separate page states.
    if (viewModel.isLoading && viewModel.statistics == null) {
      return const LoadingDialog(
        inline: true,
        message: 'Loading grocery list...',
      );
    }

    final statistics = viewModel.statistics;
    if (statistics == null) {
      return StatisticsErrorState(
        message: viewModel.errorMessage ?? 'Unable to load grocery list',
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
            // Reload all month totals after the user chooses a new period.
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
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.format_list_bulleted_outlined,
                    title: 'Total Grocery List',
                    value: statistics.totalGroceryLists.toString(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryTile(
                    icon: Icons.calendar_month,
                    title: 'Most Grocery List Month',
                    value: statistics.mostGroceryListMonth,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _GroceryListChart(months: statistics.months),
            const SizedBox(height: AppSpacing.lg),
            // Expand a month to see the lists created in that month.
            _GroceryListBreakdown(
              months: statistics.months,
              expandedIndex: viewModel.expandedIndex,
              onToggle: viewModel.toggleMonth,
            ),
          ],
        ),
      ),
    );
  }
}

// This widget turns the report values into the grocery list chart.
// It prepares labels and values before passing them to the shared chart.
// Keeping chart setup here avoids mixing it with the main page layout.
class _GroceryListChart extends StatelessWidget {
  final List<GroceryListMonthStatistic> months;

  const _GroceryListChart({required this.months});

  @override
  // Build the grocery list chart from the values supplied by the parent.
  // Labels, scale, and spacing are prepared before the chart is displayed.
  // This method only handles presentation and does not change report data.
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Grocery List By Month',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: (months.length * 64.0).clamp(
            MediaQuery.sizeOf(context).width - 52,
            double.infinity,
          ),
          // GROCERY-LIST LINE-CHART UI CALL STARTS HERE.
          // Monthly grocery-list totals become chart points.
          // Draws a line chart showing grocery lists created each month.
          // Link: GroceryListStatisticsPage -> StatisticsLineChart.
          // Widget file: ../widgets/statistics_line_chart.dart.
          child: StatisticsLineChart(
            color: const Color(0xFF21AEEA),
            points: months
                .map(
                  (month) => StatisticsLineChartPoint(
                    label: DateFormat('MMM yy').format(month.month),
                    value: month.totalLists,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

// This widget displays the detailed grocery list breakdown.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
class _GroceryListBreakdown extends StatelessWidget {
  final List<GroceryListMonthStatistic> months;
  final int? expandedIndex;
  final ValueChanged<int> onToggle;

  const _GroceryListBreakdown({
    required this.months,
    required this.expandedIndex,
    required this.onToggle,
  });

  @override
  // Build the visible rows for the grocery list breakdown.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Grocery List Breakdown',
      alignTitleLeft: true,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: List.generate(months.length, (index) {
            final month = months[index];
            return _GroceryListMonthSection(
              month: month,
              isExpanded: expandedIndex == index,
              showDivider: index != months.length - 1,
              onTap: () => onToggle(index),
            );
          }),
        ),
      ),
    );
  }
}

// This widget displays the detailed grocery list month section.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
class _GroceryListMonthSection extends StatelessWidget {
  final GroceryListMonthStatistic month;
  final bool isExpanded;
  final bool showDivider;
  final VoidCallback onTap;

  const _GroceryListMonthSection({
    required this.month,
    required this.isExpanded,
    required this.showDivider,
    required this.onTap,
  });

  @override
  // Build the visible rows for the grocery list month section.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
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
                const _SoftIcon(icon: Icons.calendar_month),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    month.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  month.totalLists.toString(),
                  style: context.text.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
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
          if (month.lists.isEmpty)
            const _GroceryListItemRow.empty()
          else
            ...month.lists.map((item) => _GroceryListItemRow(item: item)),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

// This widget displays the detailed grocery list item row.
// It converts each data item into a readable row for the user.
// Expand and sort actions are connected here when the section needs them.
class _GroceryListItemRow extends StatelessWidget {
  final GroceryListStatisticItem? item;

  const _GroceryListItemRow({required this.item});

  const _GroceryListItemRow.empty() : item = null;

  @override
  // Build the visible rows for the grocery list item row.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  Widget build(BuildContext context) {
    final list = item;
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      child: Row(
        children: [
          const _TinyIcon(icon: Icons.shopping_basket_outlined),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              list?.name ?? 'No grocery list created',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            list?.duration ?? '-',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
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
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool alignTitleLeft;

  const _SectionCard({
    required this.title,
    required this.child,
    this.alignTitleLeft = false,
  });

  @override
  // Build the visible rows for the section card.
  // Each model item becomes one reusable row or expandable group.
  // Callbacks send taps back to the ViewModel or parent widget.
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: alignTitleLeft
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: alignTitleLeft ? TextAlign.start : TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

// This small widget draws one summary tile.
// It keeps repeated row styling consistent across the whole report.
// The values come from the parent section and are not loaded here.
class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  // Build the visual layout for this summary tile.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
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

// This helper draws the reusable soft icon.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
class _SoftIcon extends StatelessWidget {
  final IconData icon;

  const _SoftIcon({required this.icon});

  @override
  // Build the visual layout for this soft icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
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

// This helper draws the reusable tiny icon.
// It handles the small visual rules in one place.
// This keeps the larger report widgets easier to scan.
class _TinyIcon extends StatelessWidget {
  final IconData icon;

  const _TinyIcon({required this.icon});

  @override
  // Build the visual layout for this tiny icon.
  // The widget uses only the values passed through its constructor.
  // It stays stateless so the parent remains the source of truth.
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFECE7CF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD7C98D)),
      ),
      child: Icon(icon, color: const Color(0xFF6D642C), size: 18),
    );
  }
}

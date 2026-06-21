// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/tabs/app_pill_segmented_control.dart';
import '../../domain/entities/admin_statistics.dart';
import 'statistics_bar_chart.dart';
import 'statistics_line_chart.dart';
import 'statistics_recipe_media_thumbnail.dart';
import 'statistics_pie_chart.dart';

/// Date-range control shared by the smaller admin reports.
// Handles AdminStatisticDateRangeBar for this part of the statistics page.
class AdminStatisticDateRangeBar extends StatelessWidget {
  final String dateRange;
  final VoidCallback? onTap;

  // Handles AdminStatisticDateRangeBar for this part of the statistics page.
  const AdminStatisticDateRangeBar({
    super.key,
    required this.dateRange,
    this.onTap,
  });

  // Handles build for this part of the statistics page.
  @override
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
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
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
                      style: context.text.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ),
                  // Handles Icon for this part of the statistics page.
                  const Icon(Icons.calendar_month, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact tile for one important admin total.
// Handles AdminStatisticSummaryTile for this part of the statistics page.
class AdminStatisticSummaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  // Handles AdminStatisticSummaryTile for this part of the statistics page.
  const AdminStatisticSummaryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  // Handles build for this part of the statistics page.
  @override
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
          AdminStatisticSoftIcon(icon: icon),
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

/// Places a daily line chart inside the standard admin card style.
// Handles AdminLineChartCard for this part of the statistics page.
class AdminLineChartCard extends StatelessWidget {
  final String title;
  final List<AdminDailyStatistic> values;

  // Handles AdminLineChartCard for this part of the statistics page.
  const AdminLineChartCard({
    super.key,
    required this.title,
    required this.values,
  });

  // Handles build for this part of the statistics page.
  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              // Give every date enough horizontal space and scroll if needed.
              final chartWidth = (values.length * 52.0).clamp(
                constraints.maxWidth,
                double.infinity,
              );

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  // LINE CHART CALL STARTS HERE.
                  // This shared admin card sends the prepared daily points to
                  // StatisticsLineChart, which draws the actual line.
                  // Draws a line chart of the supplied daily admin values.
                  // Linked from: AdminMealAnalyticPage and AdminPostAnalyticPage.
                  // Links to: statistics_line_chart.dart -> StatisticsLineChart.
                  child: StatisticsLineChart(
                    height: 220,
                    points: values
                        .map(
                          (value) => StatisticsLineChartPoint(
                            label: formatter.format(value.date),
                            value: value.value,
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Lets the admin move between related report sections.
// Handles AdminAnalyticSectionPager for this part of the statistics page.
class AdminAnalyticSectionPager extends StatelessWidget {
  final PageController controller;
  final List<AdminAnalyticSection> sections;
  final int selectedIndex;
  final AdminStatisticsSortOrder sortOrder;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<AdminStatisticsSortOrder> onSortChanged;
  final Widget? Function(AdminAnalyticSection section)? customSectionBuilder;

  // Handles AdminAnalyticSectionPager for this part of the statistics page.
  const AdminAnalyticSectionPager({
    super.key,
    required this.controller,
    required this.sections,
    required this.selectedIndex,
    required this.sortOrder,
    required this.onPageChanged,
    required this.onSortChanged,
    this.customSectionBuilder,
  });

  // Handles build for this part of the statistics page.
  @override
  Widget build(BuildContext context) {
    final pageHeight = MediaQuery.sizeOf(context).width < 360 ? 820.0 : 780.0;

    return Column(
      children: [
        _AdminSectionTabs(
          sections: sections,
          selectedIndex: selectedIndex,
          onSelected: (index) {
            controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
            );
            onPageChanged(index);
          },
        ),
        // Handles SizedBox for this part of the statistics page.
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: pageHeight,
          child: PageView.builder(
            controller: controller,
            itemCount: sections.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final custom = customSectionBuilder?.call(sections[index]);
              if (custom != null) {
                return SingleChildScrollView(child: custom);
              }
              // Difficulty keeps its natural 1-to-5 order. Other lists follow
              // the sort option selected by the admin.
              final section = sections[index].title == 'Average Difficulty'
                  ? sections[index]
                  : sections[index].sorted(sortOrder);
              return SingleChildScrollView(
                child: AdminAnalyticSectionCard(
                  section: section,
                  sortOrder: sortOrder,
                  onSortChanged: onSortChanged,
                ),
              );
            },
          ),
        ),
        // Handles SizedBox for this part of the statistics page.
        const SizedBox(height: AppSpacing.md),
        AdminPageDots(count: sections.length, selectedIndex: selectedIndex),
      ],
    );
  }
}

// Handles _AdminSectionTabs for this part of the statistics page.
class _AdminSectionTabs extends StatelessWidget {
  final List<AdminAnalyticSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  // Handles _AdminSectionTabs for this part of the statistics page.
  const _AdminSectionTabs({
    required this.sections,
    required this.selectedIndex,
    required this.onSelected,
  });

  // Handles build for this part of the statistics page.
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final tabWidth = (sections.length * 116.0).clamp(width - 32, 720.0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tabWidth,
        child: AppPillSegmentedControl(
          labels: sections
              .map((section) => _shortTabLabel(section.title))
              .toList(),
          selectedIndex: selectedIndex,
          onChanged: onSelected,
        ),
      ),
    );
  }

  // Handles _shortTabLabel for this part of the statistics page.
  String _shortTabLabel(String title) {
    switch (title) {
      case 'Most Planned Meal':
        return 'Meal';
      case 'Top Category Meal':
      case 'Most Rating Category':
        return 'Category';
      case 'Meal Planned Time':
        return 'Time';
      case 'Average Difficulty':
        return 'Difficulty';
      case 'Method Of Creating Meal Plan':
        return 'Method';
      case 'Most Rating For All Posted':
        return 'Rating';
      case 'Recipe Performance':
        return 'Performance';
      case 'Recipe That Been Planned The Most':
        return 'Planned';
      default:
        return title;
    }
  }
}

/// Standard layout for a summary, chart, and ranked breakdown.
// Handles AdminAnalyticSectionCard for this part of the statistics page.
class AdminAnalyticSectionCard extends StatelessWidget {
  final AdminAnalyticSection section;
  final AdminStatisticsSortOrder sortOrder;
  final ValueChanged<AdminStatisticsSortOrder> onSortChanged;

  // Handles AdminAnalyticSectionCard for this part of the statistics page.
  const AdminAnalyticSectionCard({
    super.key,
    required this.section,
    required this.sortOrder,
    required this.onSortChanged,
  });

  // Handles build for this part of the statistics page.
  @override
  Widget build(BuildContext context) {
    // Use pie charts for parts of a whole and bars for ranked values.
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
            section.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AdminStatisticSummaryTile(
                  icon: Icons.insights,
                  title: section.summaryTitle,
                  value: section.summaryValue,
                ),
              ),
              // Handles SizedBox for this part of the statistics page.
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AdminStatisticSummaryTile(
                  icon: Icons.workspace_premium_outlined,
                  title: section.highlightTitle,
                  value: section.highlightValue,
                ),
              ),
            ],
          ),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(height: AppSpacing.lg),
          _SectionChart(section: section, chartWidth: chartWidth),
          const SizedBox(height: AppSpacing.lg),
          AdminRankedStatisticList(
            title: section.title,
            items: section.items,
            sortOrder: sortOrder,
            onSortChanged: onSortChanged,
          ),
        ],
      ),
    );
  }
}

// Handles _SectionChart for this part of the statistics page.
class _SectionChart extends StatelessWidget {
  final AdminAnalyticSection section;
  final double chartWidth;

  // Handles _SectionChart for this part of the statistics page.
  const _SectionChart({required this.section, required this.chartWidth});

  @override
  Widget build(BuildContext context) {
    final chartItems = section.items
        .where(
          (item) => section.title == 'Average Difficulty' || item.value > 0,
        )
        .take(5)
        .toList();

    if (section.title == 'Meal Planned Time' ||
        section.title == 'Method Of Creating Meal Plan') {
      final chartSize = MediaQuery.sizeOf(context).width < 360 ? 238.0 : 260.0;
      // PIE CHART CALL STARTS HERE.
      // Meal-time and creation-method sections represent parts of a total, so
      // this branch sends their values to the shared StatisticsPieChart.
      // Draws a pie chart of meal-time or plan-creation-method totals.
      // Linked from: AdminMealAnalyticPage through AdminAnalyticSectionPager.
      // Links to: statistics_pie_chart.dart -> StatisticsPieChart.
      return StatisticsPieChart(
        size: chartSize,
        centerTitle: section.title == 'Method Of Creating Meal Plan'
            ? 'Total\nMeals'
            : 'Total\nMeals',
        centerValue: section.summaryValue,
        segments: chartItems
            .map(
              (item) => StatisticsPieChartSegment(
                label: item.label,
                value: item.value,
                color: item.color,
              ),
            )
            .toList(),
      );
    }

    return Center(
      child: SizedBox(
        width: chartWidth,
        // BAR CHART CALL STARTS HERE.
        // All other ranked analytic sections send their first five items to
        // StatisticsBarChart, which builds one vertical bar for each item.
        // Draws a bar chart of the first five ranked section values.
        // Linked from: AdminMealAnalyticPage and AdminPostAnalyticPage.
        // Links to: statistics_bar_chart.dart -> StatisticsBarChart.
        child: StatisticsBarChart(
          height: chartWidth * 0.72,
          items: chartItems
              .map(
                (item) => StatisticsBarChartItem(
                  label: item.label,
                  value: item.value,
                  icon: item.icon,
                  color: item.color,
                  imageUrl: item.imageUrl,
                  markerText: item.markerText,
                  markerIconColor: section.title == 'Average Difficulty'
                      ? const Color(0xFFFFB300)
                      : null,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// Ranked values that can sort and open extra detail rows.
// Handles AdminRankedStatisticList for this part of the statistics page.
class AdminRankedStatisticList extends StatefulWidget {
  final String title;
  final List<AdminRankedStatistic> items;
  final AdminStatisticsSortOrder? sortOrder;
  final ValueChanged<AdminStatisticsSortOrder>? onSortChanged;

  // Handles AdminRankedStatisticList for this part of the statistics page.
  const AdminRankedStatisticList({
    super.key,
    required this.title,
    required this.items,
    this.sortOrder,
    this.onSortChanged,
  });

  // Handles createState for this part of the statistics page.
  @override
  State<AdminRankedStatisticList> createState() =>
      _AdminRankedStatisticListState();
}

// Handles _AdminRankedStatisticListState for this part of the statistics page.
class _AdminRankedStatisticListState extends State<AdminRankedStatisticList> {
  int? _expandedIndex;

  // Handles build for this part of the statistics page.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              if (widget.title == 'Average Difficulty')
                Text(
                  '1 - 5 Star',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else if (widget.sortOrder != null && widget.onSortChanged != null)
                PopupMenuButton<AdminStatisticsSortOrder>(
                  tooltip: 'Sort',
                  initialValue: widget.sortOrder,
                  onSelected: widget.onSortChanged,
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: AdminStatisticsSortOrder.descending,
                      child: Text('Descending'),
                    ),
                    PopupMenuItem(
                      value: AdminStatisticsSortOrder.ascending,
                      child: Text('Ascending'),
                    ),
                  ],
                  child: Row(
                    children: [
                      Text(
                        'Sort',
                        style: context.text.bodySmall?.copyWith(fontSize: 9),
                      ),
                      // Handles SizedBox for this part of the statistics page.
                      const SizedBox(width: 2),
                      const Icon(Icons.tune, size: 17),
                    ],
                  ),
                ),
            ],
          ),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(height: AppSpacing.md),
          ...List.generate(widget.items.length, (index) {
            final item = widget.items[index];
            final isExpanded = _expandedIndex == index;
            // Only one ranked item stays open at a time.
            // Handles toggleExpanded for this part of the statistics page.
            void toggleExpanded() {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            }

            if (widget.title == 'Average Difficulty') {
              return _DifficultyRankedRow(
                item: item,
                isExpanded: isExpanded,
                showDivider: index != widget.items.length - 1,
                onTap: toggleExpanded,
              );
            }
            return _RankedRow(
              item: item,
              isExpanded: isExpanded,
              onTap: toggleExpanded,
            );
          }),
        ],
      ),
    );
  }
}

// Handles AdminPreferencePieCard for this part of the statistics page.
class AdminPreferencePieCard extends StatelessWidget {
  final String title;
  final String centerTitle;
  final int totalUsers;
  final List<AdminRankedStatistic> preferences;

  // Handles AdminPreferencePieCard for this part of the statistics page.
  const AdminPreferencePieCard({
    super.key,
    this.title = 'Dietary Preference',
    this.centerTitle = 'Total\nUsers',
    required this.totalUsers,
    required this.preferences,
  });

  // Handles build for this part of the statistics page.
  @override
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
            title,
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(height: AppSpacing.md),
          // PIE CHART CALL STARTS HERE.
          // Gender and dietary-preference pages call this card. This line sends
          // their converted segments to the shared pie-chart widget.
          // Draws a pie chart of gender or dietary-preference distribution.
          // Linked from: AdminGenderPage and AdminDietaryPreferencePage.
          // Links to: statistics_pie_chart.dart -> StatisticsPieChart.
          StatisticsPieChart(
            size: chartSize,
            centerTitle: centerTitle,
            centerValue: totalUsers.toString(),
            segments: preferences
                .map(
                  (preference) => StatisticsPieChartSegment(
                    label: preference.label,
                    value: preference.value,
                    color: preference.color,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// Handles AdminPageDots for this part of the statistics page.
class AdminPageDots extends StatelessWidget {
  final int count;
  final int selectedIndex;

  // Handles AdminPageDots for this part of the statistics page.
  const AdminPageDots({
    super.key,
    required this.count,
    required this.selectedIndex,
  });

  // Handles build for this part of the statistics page.
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

// Handles AdminStatisticSoftIcon for this part of the statistics page.
class AdminStatisticSoftIcon extends StatelessWidget {
  final IconData icon;

  const AdminStatisticSoftIcon({super.key, required this.icon});

  // Handles build for this part of the statistics page.
  @override
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

// Handles _RankedRow for this part of the statistics page.
class _RankedRow extends StatelessWidget {
  final AdminRankedStatistic item;
  final bool isExpanded;
  final VoidCallback onTap;

  // Handles _RankedRow for this part of the statistics page.
  const _RankedRow({
    required this.item,
    required this.isExpanded,
    required this.onTap,
  });

  // Handles build for this part of the statistics page.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: item.details.isEmpty ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE7CF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD7C98D)),
                  ),
                  child: _RankedMarker(item: item),
                ),
                // Handles SizedBox for this part of the statistics page.
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          // Handles SizedBox for this part of the statistics page.
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            item.value.toString(),
                            style: context.text.bodySmall?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      // Handles SizedBox for this part of the statistics page.
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          value: item.percent.clamp(0.0, 1.0),
                          color: item.color,
                          backgroundColor: const Color(0xFFE9EEF1),
                        ),
                      ),
                    ],
                  ),
                ),
                // Handles SizedBox for this part of the statistics page.
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${(item.percent * 100).round()}%',
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.details.isNotEmpty) ...[
                  // Handles SizedBox for this part of the statistics page.
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...item.details.map((detail) => _RankedDetailRow(detail: detail)),
      ],
    );
  }
}

// Handles _RankedMarker for this part of the statistics page.
class _RankedMarker extends StatelessWidget {
  final AdminRankedStatistic item;

  const _RankedMarker({required this.item});

  // Handles build for this part of the statistics page.
  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl?.trim() ?? '';
    if (imageUrl.isNotEmpty) {
      return StatisticsRecipeMediaThumbnail(
        mediaPath: imageUrl,
        fallbackIcon: item.icon,
        size: 32,
        backgroundColor: const Color(0xFFECE7CF),
        iconColor: const Color(0xFF6D642C),
      );
    }

    final text = _markerText(item.markerText);
    if (text.isNotEmpty) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            text,
            maxLines: 1,
            style: context.text.bodySmall?.copyWith(
              color: const Color(0xFF6D642C),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return Icon(item.icon, color: const Color(0xFF6D642C), size: 18);
  }

  // Handles _markerText for this part of the statistics page.
  String _markerText(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '';
    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}

// Handles _DifficultyRankedRow for this part of the statistics page.
class _DifficultyRankedRow extends StatelessWidget {
  final AdminRankedStatistic item;
  final bool isExpanded;
  final bool showDivider;
  final VoidCallback onTap;

  // Handles _DifficultyRankedRow for this part of the statistics page.
  const _DifficultyRankedRow({
    required this.item,
    required this.isExpanded,
    required this.showDivider,
    required this.onTap,
  });

  // Handles build for this part of the statistics page.
  @override
  Widget build(BuildContext context) {
    final level = _difficultyLevelFromLabel(item.label);
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
                // Handles AdminStatisticSoftIcon for this part of the statistics page.
                const AdminStatisticSoftIcon(icon: Icons.star_border),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DifficultyStars(count: level),
                      // Handles SizedBox for this part of the statistics page.
                      const SizedBox(height: 2),
                      Text(
                        '$level Star Difficulty',
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
                  item.value.toString(),
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
          ...item.details.map((detail) => _RankedDetailRow(detail: detail)),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

// Handles _DifficultyStars for this part of the statistics page.
class _DifficultyStars extends StatelessWidget {
  final int count;

  const _DifficultyStars({required this.count});

  // Handles build for this part of the statistics page.
  @override
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

// Handles _difficultyLevelFromLabel for this part of the statistics page.
int _difficultyLevelFromLabel(String label) {
  final match = RegExp(r'\d+').firstMatch(label);
  final level = int.tryParse(match?.group(0) ?? '') ?? 0;
  return level.clamp(1, 5);
}

// Handles _RankedDetailRow for this part of the statistics page.
class _RankedDetailRow extends StatelessWidget {
  final AdminRankedStatisticDetail detail;

  const _RankedDetailRow({required this.detail});

  // Handles build for this part of the statistics page.
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7F7),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 7,
      ),
      child: Row(
        children: [
          _DetailMarker(detail: detail),
          // Handles SizedBox for this part of the statistics page.
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (detail.subtitle?.isNotEmpty == true)
                  Text(
                    detail.subtitle!,
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
            detail.quantity.toString(),
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

// Handles _DetailMarker for this part of the statistics page.
class _DetailMarker extends StatelessWidget {
  final AdminRankedStatisticDetail detail;

  const _DetailMarker({required this.detail});

  // Handles build for this part of the statistics page.
  @override
  Widget build(BuildContext context) {
    return StatisticsRecipeMediaThumbnail(
      mediaPath: detail.imageUrl,
      fallbackIcon: detail.icon,
      size: 32,
      backgroundColor: const Color(0xFFECE7CF),
      iconColor: const Color(0xFF6D642C),
      borderColor: const Color(0xFFD7C98D),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../domain/entities/admin_statistics.dart';
import 'statistics_bar_chart.dart';
import 'statistics_line_chart.dart';
import 'statistics_pie_chart.dart';

class AdminStatisticDateRangeBar extends StatelessWidget {
  final String dateRange;
  final VoidCallback? onTap;

  const AdminStatisticDateRangeBar({
    super.key,
    required this.dateRange,
    this.onTap,
  });

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

class AdminStatisticSummaryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const AdminStatisticSummaryTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

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

class AdminLineChartCard extends StatelessWidget {
  final String title;
  final List<AdminDailyStatistic> values;

  const AdminLineChartCard({
    super.key,
    required this.title,
    required this.values,
  });

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
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = (values.length * 52.0).clamp(
                constraints.maxWidth,
                double.infinity,
              );

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
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

class AdminAnalyticSectionPager extends StatelessWidget {
  final PageController controller;
  final List<AdminAnalyticSection> sections;
  final int selectedIndex;
  final AdminStatisticsSortOrder sortOrder;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<AdminStatisticsSortOrder> onSortChanged;

  const AdminAnalyticSectionPager({
    super.key,
    required this.controller,
    required this.sections,
    required this.selectedIndex,
    required this.sortOrder,
    required this.onPageChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pageHeight = MediaQuery.sizeOf(context).width < 360 ? 820.0 : 780.0;

    return Column(
      children: [
        SizedBox(
          height: pageHeight,
          child: PageView.builder(
            controller: controller,
            itemCount: sections.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return SingleChildScrollView(
                child: AdminAnalyticSectionCard(
                  section: sections[index].sorted(sortOrder),
                  sortOrder: sortOrder,
                  onSortChanged: onSortChanged,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AdminPageDots(count: sections.length, selectedIndex: selectedIndex),
      ],
    );
  }
}

class AdminAnalyticSectionCard extends StatelessWidget {
  final AdminAnalyticSection section;
  final AdminStatisticsSortOrder sortOrder;
  final ValueChanged<AdminStatisticsSortOrder> onSortChanged;

  const AdminAnalyticSectionCard({
    super.key,
    required this.section,
    required this.sortOrder,
    required this.onSortChanged,
  });

  @override
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
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: SizedBox(
              width: chartWidth,
              child: StatisticsBarChart(
                height: chartWidth * 0.72,
                items: section.items
                    .take(5)
                    .map(
                      (item) => StatisticsBarChartItem(
                        label: item.label,
                        value: item.value,
                        icon: item.icon,
                        color: item.color,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
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

class AdminRankedStatisticList extends StatelessWidget {
  final String title;
  final List<AdminRankedStatistic> items;
  final AdminStatisticsSortOrder? sortOrder;
  final ValueChanged<AdminStatisticsSortOrder>? onSortChanged;

  const AdminRankedStatisticList({
    super.key,
    required this.title,
    required this.items,
    this.sortOrder,
    this.onSortChanged,
  });

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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              if (sortOrder != null && onSortChanged != null)
                PopupMenuButton<AdminStatisticsSortOrder>(
                  tooltip: 'Sort',
                  initialValue: sortOrder,
                  onSelected: onSortChanged,
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
                      const SizedBox(width: 2),
                      const Icon(Icons.tune, size: 17),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...items.map((item) => _RankedRow(item: item)),
        ],
      ),
    );
  }
}

class AdminPreferencePieCard extends StatelessWidget {
  final int totalUsers;
  final List<AdminRankedStatistic> preferences;

  const AdminPreferencePieCard({
    super.key,
    required this.totalUsers,
    required this.preferences,
  });

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
            'Dietary Preference',
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StatisticsPieChart(
            size: chartSize,
            centerTitle: 'Total\nUsers',
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

class AdminPageDots extends StatelessWidget {
  final int count;
  final int selectedIndex;

  const AdminPageDots({
    super.key,
    required this.count,
    required this.selectedIndex,
  });

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

class AdminStatisticSoftIcon extends StatelessWidget {
  final IconData icon;

  const AdminStatisticSoftIcon({super.key, required this.icon});

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

class _RankedRow extends StatelessWidget {
  final AdminRankedStatistic item;

  const _RankedRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            child: Icon(item.icon, color: const Color(0xFF6D642C), size: 18),
          ),
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
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${(item.percent * 100).round()}%',
            style: context.text.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

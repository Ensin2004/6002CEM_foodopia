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
  final Widget? Function(AdminAnalyticSection section)? customSectionBuilder;

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
        const SizedBox(height: AppSpacing.md),
        AdminPageDots(count: sections.length, selectedIndex: selectedIndex),
      ],
    );
  }
}

class _AdminSectionTabs extends StatelessWidget {
  final List<AdminAnalyticSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _AdminSectionTabs({
    required this.sections,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(sections.length, (index) {
          final selected = selectedIndex == index;
          return Padding(
            padding: EdgeInsets.only(
              right: index == sections.length - 1 ? 0 : AppSpacing.sm,
            ),
            child: ChoiceChip(
              label: Text(
                _shortTabLabel(sections[index].title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              selected: selected,
              onSelected: (_) => onSelected(index),
              selectedColor: const Color(0xFFEAF8F0),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.border,
              ),
              labelStyle: context.text.bodySmall?.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }),
      ),
    );
  }

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

class _SectionChart extends StatelessWidget {
  final AdminAnalyticSection section;
  final double chartWidth;

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

class AdminRankedStatisticList extends StatefulWidget {
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
  State<AdminRankedStatisticList> createState() =>
      _AdminRankedStatisticListState();
}

class _AdminRankedStatisticListState extends State<AdminRankedStatisticList> {
  int? _expandedIndex;

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
                      const SizedBox(width: 2),
                      const Icon(Icons.tune, size: 17),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(widget.items.length, (index) {
            final item = widget.items[index];
            final isExpanded = _expandedIndex == index;
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

class AdminPreferencePieCard extends StatelessWidget {
  final String title;
  final String centerTitle;
  final int totalUsers;
  final List<AdminRankedStatistic> preferences;

  const AdminPreferencePieCard({
    super.key,
    this.title = 'Dietary Preference',
    this.centerTitle = 'Total\nUsers',
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
            title,
            style: context.text.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
  final bool isExpanded;
  final VoidCallback onTap;

  const _RankedRow({
    required this.item,
    required this.isExpanded,
    required this.onTap,
  });

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
                if (item.details.isNotEmpty) ...[
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

class _RankedMarker extends StatelessWidget {
  final AdminRankedStatistic item;

  const _RankedMarker({required this.item});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl?.trim() ?? '';
    if (imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(item.icon, color: const Color(0xFF6D642C), size: 18),
        ),
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

  String _markerText(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '';
    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}

class _DifficultyRankedRow extends StatelessWidget {
  final AdminRankedStatistic item;
  final bool isExpanded;
  final bool showDivider;
  final VoidCallback onTap;

  const _DifficultyRankedRow({
    required this.item,
    required this.isExpanded,
    required this.showDivider,
    required this.onTap,
  });

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
                const AdminStatisticSoftIcon(icon: Icons.star_border),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DifficultyStars(count: level),
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
                const SizedBox(width: AppSpacing.sm),
                Text(
                  item.value.toString(),
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
          ...item.details.map((detail) => _RankedDetailRow(detail: detail)),
        if (showDivider) const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

class _DifficultyStars extends StatelessWidget {
  final int count;

  const _DifficultyStars({required this.count});

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

int _difficultyLevelFromLabel(String label) {
  final match = RegExp(r'\d+').firstMatch(label);
  final level = int.tryParse(match?.group(0) ?? '') ?? 0;
  return level.clamp(1, 5);
}

class _RankedDetailRow extends StatelessWidget {
  final AdminRankedStatisticDetail detail;

  const _RankedDetailRow({required this.detail});

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

class _DetailMarker extends StatelessWidget {
  final AdminRankedStatisticDetail detail;

  const _DetailMarker({required this.detail});

  @override
  Widget build(BuildContext context) {
    final imageUrl = detail.imageUrl?.trim() ?? '';
    return Container(
      width: 32,
      height: 32,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFECE7CF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD7C98D)),
      ),
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(detail.icon, color: const Color(0xFF6D642C), size: 18),
            )
          : Icon(detail.icon, color: const Color(0xFF6D642C), size: 18),
    );
  }
}

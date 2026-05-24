import 'package:flutter/material.dart';

import '../../theme/theme_extension.dart';

/// Reusable segmented tab bar for simple two-tab admin screens.
class AppSegmentedTabs extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final EdgeInsetsGeometry margin;
  final bool? isScrollable;

  const AppSegmentedTabs({
    super.key,
    required this.controller,
    required this.tabs,
    this.margin = EdgeInsets.zero,
    this.isScrollable,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shouldScroll = isScrollable ?? tabs.length > 3;

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: margin,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: TabBar(
            controller: controller,
            isScrollable: shouldScroll,
            indicatorColor: colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 2,
            dividerColor: Colors.transparent,
            labelColor: colorScheme.primary,
            unselectedLabelColor: Colors.black54,
            labelStyle: context.text.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: context.text.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            tabs: tabs.map((label) => Tab(text: label)).toList(),
          ),
        ),
      ),
    );
  }
}

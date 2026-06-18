import 'package:flutter/material.dart';

import '../../theme/theme_extension.dart';

/// Reusable segmented tab bar for simple two-tab admin screens.
/// Provides a Material-style tab bar with configurable options.
class AppSegmentedTabs extends StatelessWidget {
  /// Controller for managing tab state.
  final TabController controller;

  /// List of tab labels.
  final List<String> tabs;

  /// Margin around the tab bar.
  final EdgeInsetsGeometry margin;

  /// Whether the tabs should be scrollable.
  final bool? isScrollable;

  /// Callback when a tab is tapped.
  final ValueChanged<int>? onTap;

  /// Creates a new app segmented tabs instance.
  const AppSegmentedTabs({
    super.key,
    required this.controller,
    required this.tabs,
    this.margin = EdgeInsets.zero,
    this.isScrollable,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get the color scheme.
    final colorScheme = Theme.of(context).colorScheme;

    // Determine if tabs should be scrollable.
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
            onTap: onTap,
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
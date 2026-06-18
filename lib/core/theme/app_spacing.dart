import 'package:flutter/widgets.dart';

/// Shared spacing tokens for consistent mobile layouts.
/// Provides standardized spacing values and padding constants.
class AppSpacing {
  /// Extra small spacing (4px).
  static const double xs = 4;

  /// Small spacing (8px).
  static const double sm = 8;

  /// Medium spacing (12px).
  static const double md = 12;

  /// Large spacing (16px).
  static const double lg = 16;

  /// Extra large spacing (24px).
  static const double xl = 24;

  /// Standard page padding with horizontal lg spacing.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: lg);

  /// Compact page padding with horizontal md spacing.
  static const EdgeInsets compactPagePadding = EdgeInsets.symmetric(
    horizontal: md,
  );

  /// Standard card padding with lg spacing on all sides.
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}
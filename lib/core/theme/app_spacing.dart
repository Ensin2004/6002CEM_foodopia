import 'package:flutter/widgets.dart';

/// Shared spacing tokens for consistent mobile layouts.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets compactPagePadding = EdgeInsets.symmetric(
    horizontal: md,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}

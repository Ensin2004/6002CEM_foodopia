// Defines shared theme helpers for theme extension.

import 'package:flutter/material.dart';

/// Extension on BuildContext for easy theme access.
extension ThemeExt on BuildContext {
  /// Handles the text operation.
  /// Returns the text theme from the current context.
  TextTheme get text => Theme.of(this).textTheme;

  /// Handles the colors operation.
  /// Returns the color scheme from the current context.
  ColorScheme get colors => Theme.of(this).colorScheme;
}
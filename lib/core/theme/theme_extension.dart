// Defines shared theme helpers for theme extension.

import 'package:flutter/material.dart';

extension ThemeExt on BuildContext {
  /// Handles the text operation.
  TextTheme get text => Theme.of(this).textTheme;
  /// Handles the colors operation.
  ColorScheme get colors => Theme.of(this).colorScheme;
}

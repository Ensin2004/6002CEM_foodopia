import 'package:flutter/material.dart';

/// Reusable floating action button for add/create actions.
/// Supports both circular and extended variants.
class AppFloatingActionButton extends StatelessWidget {
  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Icon to display.
  final IconData icon;

  /// Label text for extended variant.
  final String? label;

  /// Tooltip text.
  final String? tooltip;

  /// Background color of the button.
  final Color? backgroundColor;

  /// Foreground color of the button.
  final Color? foregroundColor;

  /// Creates a new app floating action button instance.
  const AppFloatingActionButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.label,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Get the color scheme.
    final colors = Theme.of(context).colorScheme;

    // Determine colors.
    final background = backgroundColor ?? colors.secondary;
    final foreground = foregroundColor ?? colors.onSecondary;

    // Extended variant with label.
    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: background,
        foregroundColor: foreground,
        tooltip: tooltip,
        icon: Icon(icon),
        label: Text(label!),
      );
    }

    // Circular variant without label.
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: background,
      foregroundColor: foreground,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}
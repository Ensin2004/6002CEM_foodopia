import 'package:flutter/material.dart';

/// Reusable floating action button for add/create actions.
class AppFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

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
    final colors = Theme.of(context).colorScheme;
    final background = backgroundColor ?? colors.secondary;
    final foreground = foregroundColor ?? colors.onSecondary;

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

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: background,
      foregroundColor: foreground,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// ============================================================================
// CUSTOM APP BAR
// ============================================================================
// Reusable app bar widget for the entire app
// Design: White background, black text/icons, centered title, with shadow
// ============================================================================

/// Reusable custom app bar widget.
/// Provides consistent styling and behavior across the app.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text displayed in the app bar.
  final String title;

  /// Whether the title should be centered.
  final bool centerTitle;

  /// Leading widget (back button by default).
  final Widget? leading;

  /// Custom title widget (overrides title text).
  final Widget? titleWidget;

  /// List of action widgets on the right side.
  final List<Widget>? actions;

  /// Whether to show a confirmation dialog when navigating back.
  final bool showConfirmationOnBack;

  /// Whether there are unsaved changes.
  final bool hasUnsavedChanges;

  /// Callback when saving changes.
  final VoidCallback? onSaveChanges;

  /// Background color of the app bar.
  final Color? backgroundColor;

  /// Foreground color of the app bar.
  final Color? foregroundColor;

  /// Elevation of the app bar.
  final double elevation;

  /// Height of the app bar.
  final double toolbarHeight;

  /// Width of the leading widget.
  final double? leadingWidth;

  /// Spacing for the title.
  final double? titleSpacing;

  /// Creates a custom app bar instance.
  const CustomAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.leading,
    this.titleWidget,
    this.actions,
    this.showConfirmationOnBack = false,
    this.hasUnsavedChanges = false,
    this.onSaveChanges,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 4,
    this.toolbarHeight = kToolbarHeight,
    this.leadingWidth,
    this.titleSpacing,
  });

  /// Handles the preferred size operation.
  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    // Default to white background, black text.
    final bgColor = backgroundColor ?? Colors.white;
    final fgColor = foregroundColor ?? Colors.black;

    /// Handles the app bar operation.
    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: elevation,
      shadowColor: Colors.grey.withValues(alpha: 0.35),
      surfaceTintColor: Colors.transparent,
      toolbarHeight: toolbarHeight,
      shape: const Border(
        bottom: BorderSide(color: AppColors.border, width: 0.5),
      ),
      centerTitle: centerTitle,
      leading: leading ?? _buildBackButton(context, fgColor),
      leadingWidth: leadingWidth,
      titleSpacing: titleSpacing,
      title:
      titleWidget ??
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 20,
              color: fgColor,
            ),
          ),
      actions: actions,
    );
  }

  /// Handles the build back button operation.
  Widget _buildBackButton(BuildContext context, Color color) {
    /// Handles the icon button operation.
    return IconButton(
      icon: Icon(Icons.arrow_back, color: color),
      onPressed: () {
        if (showConfirmationOnBack && hasUnsavedChanges) {
          _showConfirmationDialog(context);
        } else {
          Navigator.pop(context);
        }
      },
    );
  }

  /// Handles the show confirmation dialog operation.
  void _showConfirmationDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes. Do you want to save them before leaving?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          /// Creates a text button instance.
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Discard'),
          ),

          /// Creates a text button instance.
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((shouldSave) {
      // Check if context is still mounted.
      if (!context.mounted) return;

      // Handle save action.
      if (shouldSave == true && onSaveChanges != null) {
        onSaveChanges!();

        // Pop after a short delay to allow save to complete.
        Future.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) Navigator.pop(context);
        });
      } else if (shouldSave == false) {
        // Handle discard action.
        Navigator.pop(context);
      }
    });
  }
}
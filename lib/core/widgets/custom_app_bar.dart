import 'package:flutter/material.dart';

// ============================================================================
// CUSTOM APP BAR
// ============================================================================
// Reusable app bar widget for the entire app
// Design: White background, black text/icons, centered title, with shadow
// ============================================================================

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showConfirmationOnBack;
  final bool hasUnsavedChanges;
  final VoidCallback? onSaveChanges;
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Creates a custom app bar instance.
  const CustomAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.leading,
    this.actions,
    this.showConfirmationOnBack = false,
    this.hasUnsavedChanges = false,
    this.onSaveChanges,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Handles the preferred size operation.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    // Default to white background, black text
    final bgColor = backgroundColor ?? Colors.white;
    final fgColor = foregroundColor ?? Colors.black;

    /// Handles the app bar operation.
    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 4,  // Adds shadow like sample
      shadowColor: Colors.grey.withOpacity(0.4),  // Sets shadow color
      surfaceTintColor: Colors.transparent,  // Removes surface tint
      shape: const Border(
        bottom: BorderSide(
          color: Colors.grey,
          width: 0.5,
        ),
      ),
      centerTitle: centerTitle,
      leading: leading ?? _buildBackButton(context, fgColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
      if (shouldSave == true && onSaveChanges != null) {
        onSaveChanges!();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) Navigator.pop(context);
        });
      } else if (shouldSave == false) {
        Navigator.pop(context);
      }
    });
  }
}

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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // Default to white background, black text
    final bgColor = backgroundColor ?? Colors.white;
    final fgColor = foregroundColor ?? Colors.black;

    return AppBar(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 4,  // ✅ Add shadow like sample
      shadowColor: Colors.grey.withOpacity(0.4),  // ✅ Shadow color
      surfaceTintColor: Colors.transparent,  // ✅ Remove surface tint
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

  Widget _buildBackButton(BuildContext context, Color color) {
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Discard'),
          ),
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
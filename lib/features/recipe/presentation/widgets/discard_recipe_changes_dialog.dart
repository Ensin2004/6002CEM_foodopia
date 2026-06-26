import 'package:flutter/material.dart';

/// Shows a confirmation dialog before leaving an add-recipe page with unsaved changes.
Future<bool> confirmDiscardRecipeChanges(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Cancel changes?'),
        content: const Text(
          'Your unsaved changes will be lost if you leave this page.',
        ),
        actions: [
          // Continue editing
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Editing'),
          ),
          // Stop editing and leave
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel Changes'),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}

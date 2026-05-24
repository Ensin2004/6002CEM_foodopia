import 'package:flutter/material.dart';

Future<bool> showDiscardRecipeChangesDialog(BuildContext context) async {
  final shouldDiscard = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'Your unsaved edits will be canceled if you leave this screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard Changes'),
          ),
        ],
      );
    },
  );

  return shouldDiscard == true;
}

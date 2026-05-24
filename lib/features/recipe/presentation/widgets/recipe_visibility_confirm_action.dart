import 'package:flutter/material.dart';

import '../../../../core/widgets/dialogs/loading_dialog.dart';
import '../viewmodel/add_recipe_visibility_viewmodel.dart';
import 'recipe_visibility_action_button.dart';

class RecipeVisibilityConfirmAction extends StatelessWidget {
  final String recipeId;
  final AddRecipeVisibilityViewModel viewModel;

  const RecipeVisibilityConfirmAction({
    super.key,
    required this.recipeId,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return RecipeVisibilityActionButton(
      visibility: viewModel.visibility,
      isSaving: viewModel.isSaving,
      onChanged: (value) => _confirmVisibilityChange(context, value),
    );
  }

  Future<void> _confirmVisibilityChange(
    BuildContext context,
    String nextVisibility,
  ) async {
    final nextPublished = nextVisibility == 'public';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            nextPublished ? 'Publish recipe?' : 'Make recipe private?',
          ),
          content: Text(
            nextPublished
                ? 'This recipe will be visible to other users in Explore.'
                : 'This recipe will be hidden from Explore but remain in your library.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(nextPublished ? 'Publish' : 'Make Private'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LoadingDialog(
        message: nextPublished ? 'Publishing recipe...' : 'Updating recipe...',
      ),
    );

    final success = await viewModel.updateVisibility(
      recipeId: recipeId,
      value: nextVisibility,
    );

    if (!context.mounted) return;
    rootNavigator.pop();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? nextPublished
                      ? 'Recipe published.'
                      : 'Recipe is now private.'
                : viewModel.errorMessage ?? 'Unable to update visibility.',
          ),
        ),
      );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/widgets/dialogs/loading_dialog.dart';

class RecipeVisibilityActionButton extends StatelessWidget {
  final String visibility;
  final bool isSaving;
  final ValueChanged<String> onChanged;

  const RecipeVisibilityActionButton({
    super.key,
    required this.visibility,
    required this.isSaving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isPublic = visibility == "public";

    return Padding(
      padding: EdgeInsets.only(right: AppSpacing.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isSaving
            ? null
            : () => onChanged(isPublic ? "private" : "public"),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isPublic
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPublic ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                size: 14,
                color: isPublic ? AppColors.primary : AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                isPublic ? "Public" : "Private",
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPublic ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> confirmRecipeVisibilityChange({
  required BuildContext context,
  required String currentVisibility,
  required String nextVisibility,
  required Future<bool> Function(String visibility) onConfirmed,
  required String? Function() errorMessage,
}) async {
  final current = currentVisibility == 'public' ? 'public' : 'private';
  final next = nextVisibility == 'public' ? 'public' : 'private';
  if (current == next) return;

  final willPublish = next == 'public';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          willPublish ? 'Make recipe public?' : 'Make recipe private?',
        ),
        content: Text(
          willPublish
              ? 'This recipe will be visible to other users.'
              : 'This recipe will be hidden from other users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(willPublish ? 'Make Public' : 'Make Private'),
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
    builder: (_) => const LoadingDialog(message: 'Updating visibility...'),
  );

  final success = await onConfirmed(next);

  if (!context.mounted) return;
  rootNavigator.pop();

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Recipe is now ${willPublish ? 'public' : 'private'}.'
              : errorMessage() ?? 'Unable to update visibility.',
        ),
      ),
    );
}

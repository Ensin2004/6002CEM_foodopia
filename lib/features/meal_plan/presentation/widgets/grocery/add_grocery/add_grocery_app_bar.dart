import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/theme_extension.dart';
import '../../../../../../core/widgets/custom_app_bar.dart';

/// App bar for the add grocery list page.
class AddGroceryAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Callback when the back button is pressed.
  final VoidCallback onBack;

  /// Creates the add grocery app bar.
  const AddGroceryAppBar({super.key, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      title: 'Add Grocery List',
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.chevron_left),
      ),
    );
  }
}

/// Centered error state for failed grocery setup loading.
class AddGroceryErrorState extends StatelessWidget {
  /// Error message.
  final String message;

  /// Retry callback.
  final Future<void> Function() onRetry;

  /// Creates the add grocery error state.
  const AddGroceryErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    /* Empty illustration keeps the failure state consistent with meal plan
       screens while the retry button keeps recovery close to the message. */
    return Center(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/empty_page.png', height: 140),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

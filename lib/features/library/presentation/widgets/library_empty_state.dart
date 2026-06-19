import 'package:flutter/material.dart';

import '../../../../core/widgets/buttons/primary_button.dart';

// Displays an empty library message with an action that sends visitors to recipe discovery.
class LibraryEmptyState extends StatelessWidget {
  final VoidCallback onExploreNow;

  const LibraryEmptyState({super.key, required this.onExploreNow});

  @override
  Widget build(BuildContext context) {
    // Uses the active theme typography so the empty state matches the surrounding library page.
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Keeps the empty-state illustration compact on both phone and tablet layouts.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Image.asset('assets/images/empty_page.png'),
          ),
          const SizedBox(height: 18),
          // Provides a short headline that explains the selected library tab has no content.
          Text(
            'Whoops!\nIt looks empty...',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(height: 1.05),
          ),
          const SizedBox(height: 8),
          // Explains how recipes can appear in the library.
          Text(
            'Create your own recipes or save community recipes to see them here!',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 22),
          // Opens the explore flow so community recipes can be discovered or saved.
          PrimaryButton(
            onPressed: onExploreNow,
            text: 'Explore Now',
            verticalPadding: 13,
          ),
        ],
      ),
    );
  }
}

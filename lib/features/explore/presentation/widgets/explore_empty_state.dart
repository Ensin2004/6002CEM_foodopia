import 'package:flutter/material.dart';

import '../../../../core/widgets/buttons/primary_button.dart';

// Displays an empty state view with a visual cue and call-to-action button
class ExploreEmptyState extends StatelessWidget {
  // Callback triggered when the user taps the explore button
  final VoidCallback onExploreNow;

  const ExploreEmptyState({super.key, required this.onExploreNow});

  @override
  Widget build(BuildContext context) {
    // Retrieves the text theme for consistent typography across the widget
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      // Adds asymmetric padding: top space for visual breathing, side and bottom for content edges
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        // Centers children vertically within the available space
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Restricts the image width to prevent oversized display on large screens
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Image.asset('assets/images/empty_page.png'),
          ),
          // Spacer between image and title text
          const SizedBox(height: 18),
          // Primary heading with custom line height for multi-line readability
          Text(
            'Whoops!\nIt looks empty...',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(height: 1.05),
          ),
          // Spacer between title and descriptive message
          const SizedBox(height: 8),
          // Instructional subtext guiding the user to take action
          Text(
            'Explore recipes from community and follow them to see them here!',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          // Spacer between description and the action button
          const SizedBox(height: 22),
          // Primary button that invokes the exploration navigation callback
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
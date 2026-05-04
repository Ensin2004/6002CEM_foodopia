// Builds the explore screen.

import 'package:flutter/material.dart';

/// Defines behavior for explore page.
class ExplorePage extends StatelessWidget {
  /// Creates a explore page instance.
  const ExplorePage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the center operation.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// Creates a icon instance.
          const Icon(Icons.explore, size: 80, color: Colors.grey),
          /// Creates a sized box instance.
          const SizedBox(height: 16),
          /// Creates a text instance.
          Text('Explore', style: Theme.of(context).textTheme.headlineSmall),
          /// Creates a text instance.
          const Text('Discover new recipes'),
        ],
      ),
    );
  }
}

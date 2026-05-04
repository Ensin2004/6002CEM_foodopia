// Builds the library screen.

import 'package:flutter/material.dart';

/// Defines behavior for library page.
class LibraryPage extends StatelessWidget {
  /// Creates a library page instance.
  const LibraryPage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the center operation.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// Creates a icon instance.
          const Icon(Icons.library_books, size: 80, color: Colors.grey),
          /// Creates a sized box instance.
          const SizedBox(height: 16),
          /// Creates a text instance.
          Text('Library', style: Theme.of(context).textTheme.headlineSmall),
          /// Creates a text instance.
          const Text('Your saved recipes'),
        ],
      ),
    );
  }
}

// Builds the home screen.

import 'package:flutter/material.dart';

/// Defines behavior for home page.
class HomePage extends StatelessWidget {
  /// Creates a home page instance.
  const HomePage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the center operation.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// Creates a icon instance.
          const Icon(Icons.home, size: 80, color: Colors.grey),
          /// Creates a sized box instance.
          const SizedBox(height: 16),
          /// Creates a text instance.
          Text('Home', style: Theme.of(context).textTheme.headlineSmall),
          /// Creates a text instance.
          const Text('Welcome to Foodopia!'),
        ],
      ),
    );
  }
}

// Builds the add recipe screen.

import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_app_bar.dart';

/// Defines behavior for add recipe page.
class AddRecipePage extends StatelessWidget {
  /// Creates a add recipe page instance.
  const AddRecipePage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the scaffold operation.
    return Scaffold(
      appBar: const CustomAppBar(title: 'Add Recipe'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Creates a icon instance.
            const Icon(Icons.add_circle, size: 80, color: Colors.grey),

            /// Creates a sized box instance.
            const SizedBox(height: 16),

            /// Creates a text instance.
            Text(
              'Add Recipe',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            /// Creates a text instance.
            const Text('Create a new recipe'),
          ],
        ),
      ),
    );
  }
}

// Builds the meal plan screen.

import 'package:flutter/material.dart';

/// Defines behavior for meal plan page.
class MealPlanPage extends StatelessWidget {
  /// Creates a meal plan page instance.
  const MealPlanPage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the center operation.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// Creates a icon instance.
          const Icon(Icons.calendar_today, size: 80, color: Colors.grey),
          /// Creates a sized box instance.
          const SizedBox(height: 16),
          /// Creates a text instance.
          Text('Meal Plan', style: Theme.of(context).textTheme.headlineSmall),
          /// Creates a text instance.
          const Text('Plan your weekly meals'),
        ],
      ),
    );
  }
}

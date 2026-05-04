// Builds the statistics screen.

import 'package:flutter/material.dart';

/// Defines behavior for statistics page.
class StatisticsPage extends StatelessWidget {
  final bool isAdmin;

  /// Creates a statistics page instance.
  const StatisticsPage({super.key, required this.isAdmin});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the admin statistics view operation.
    return isAdmin ? const _AdminStatisticsView() : const _UserStatisticsView();
  }
}

/// Defines behavior for admin statistics view.
class _AdminStatisticsView extends StatelessWidget {
  /// Handles the admin statistics view operation.
  const _AdminStatisticsView();

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the center operation.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// Creates a icon instance.
          const Icon(Icons.analytics, size: 80, color: Colors.grey),
          /// Creates a sized box instance.
          const SizedBox(height: 16),
          /// Creates a text instance.
          Text(
            'Admin Statistics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          /// Creates a sized box instance.
          const SizedBox(height: 8),
          /// Creates a text instance.
          const Text('System analytics and usage data'),
          /// Creates a sized box instance.
          const SizedBox(height: 16),
          _buildStatCard('Total Users', '1,234'),
          _buildStatCard('Total Recipes', '5,678'),
          _buildStatCard('Active Users', '890'),
        ],
      ),
    );
  }

  /// Handles the build stat card operation.
  Widget _buildStatCard(String title, String value) {
    /// Handles the card operation.
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Defines behavior for user statistics view.
class _UserStatisticsView extends StatelessWidget {
  /// Handles the user statistics view operation.
  const _UserStatisticsView();

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the center operation.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// Creates a icon instance.
          const Icon(Icons.bar_chart, size: 80, color: Colors.grey),
          /// Creates a sized box instance.
          const SizedBox(height: 16),
          /// Creates a text instance.
          Text(
            'Your Statistics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          /// Creates a sized box instance.
          const SizedBox(height: 8),
          /// Creates a text instance.
          const Text('Personal cooking statistics'),
          /// Creates a sized box instance.
          const SizedBox(height: 16),
          _buildStatCard('Recipes Saved', '24'),
          _buildStatCard('Meals Planned', '12'),
          _buildStatCard('Favorite Cuisines', 'Italian, Asian'),
        ],
      ),
    );
  }

  /// Handles the build stat card operation.
  Widget _buildStatCard(String title, String value) {
    /// Handles the card operation.
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class StatisticsPage extends StatelessWidget {
  final bool isAdmin;

  const StatisticsPage({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return isAdmin ? const _AdminStatisticsView() : const _UserStatisticsView();
  }
}

class _AdminStatisticsView extends StatelessWidget {
  const _AdminStatisticsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Admin Statistics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('System analytics and usage data'),
          const SizedBox(height: 16),
          _buildStatCard('Total Users', '1,234'),
          _buildStatCard('Total Recipes', '5,678'),
          _buildStatCard('Active Users', '890'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
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

class _UserStatisticsView extends StatelessWidget {
  const _UserStatisticsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Your Statistics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Personal cooking statistics'),
          const SizedBox(height: 16),
          _buildStatCard('Recipes Saved', '24'),
          _buildStatCard('Meals Planned', '12'),
          _buildStatCard('Favorite Cuisines', 'Italian, Asian'),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
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
// Builds the manage screen.

import 'package:flutter/material.dart';

/// Defines behavior for manage page.
class ManagePage extends StatelessWidget {
  /// Creates a manage page instance.
  const ManagePage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the list view operation.
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        /// Creates a text instance.
        const Text(
          'Admin Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        /// Creates a sized box instance.
        const SizedBox(height: 16),
        _buildCard('User Management', Icons.people, () {}),
        _buildCard('Recipe Management', Icons.restaurant_menu, () {}),
        _buildCard('Content Moderation', Icons.flag, () {}),
        _buildCard('System Settings', Icons.settings, () {}),
      ],
    );
  }

  /// Handles the build card operation.
  Widget _buildCard(String title, IconData icon, VoidCallback onTap) {
    /// Handles the card operation.
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

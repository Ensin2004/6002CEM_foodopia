// Builds the manage screen.

import 'package:flutter/material.dart';

import '../../../../core/theme/theme_extension.dart';

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
        Text('Admin Management', style: context.text.headlineSmall),

        /// Creates a sized box instance.
        const SizedBox(height: 16),
        _buildCard(context, 'Recipe Management', Icons.restaurant_menu, () {}),
        _buildCard(context, 'System Settings', Icons.settings, () {}),
      ],
    );
  }

  /// Handles the build card operation.
  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    /// Handles the card operation.
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: context.text.titleMedium),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

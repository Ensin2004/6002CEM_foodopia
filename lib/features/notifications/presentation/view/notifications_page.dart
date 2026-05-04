// Builds the notifications screen.

import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_app_bar.dart';

/// Defines behavior for notifications page.
class NotificationsPage extends StatelessWidget {
  /// Creates a notifications page instance.
  const NotificationsPage({super.key});

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the scaffold operation.
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Notifications',
        centerTitle: false,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Creates a icon instance.
            Icon(Icons.notifications_none, size: 80, color: Colors.grey),
            /// Creates a sized box instance.
            SizedBox(height: 16),
            /// Creates a text instance.
            Text('No Notifications'),
            /// Creates a text instance.
            Text('You\'re all caught up!'),
          ],
        ),
      ),
    );
  }
}

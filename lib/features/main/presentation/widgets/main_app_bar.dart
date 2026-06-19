import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_app_bar.dart';

/// Defines behavior for main app bar.
/// Custom app bar with profile avatar, title, and action buttons.
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Whether the user is an admin.
  final bool isAdmin;

  /// URL of the user's profile image.
  final String? profileImageUrl;

  /// Callback when settings is tapped.
  final VoidCallback onSettingsTap;

  /// Callback when statistics is tapped.
  final VoidCallback? onStatisticsTap;

  /// Callback when notifications is tapped.
  final VoidCallback? onNotificationsTap;

  /// Creates a main app bar instance.
  const MainAppBar({
    super.key,
    required this.isAdmin,
    required this.profileImageUrl,
    required this.onSettingsTap,
    this.onStatisticsTap,
    this.onNotificationsTap,
  });

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    return CustomAppBar(
      title: 'Foodopia',
      titleWidget: _buildTitle(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 0,
      toolbarHeight: 56,
      leading: const SizedBox.shrink(),
      leadingWidth: 0,
      titleSpacing: 0,
      centerTitle: false,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      actions: _buildActions(context),
    );
  }

  // =========================================================================
  // TITLE
  // =========================================================================

  /// Handles the build title operation.
  Widget _buildTitle(BuildContext context) {
    /// Handles the row operation.
    return Row(
      children: [
        /// Creates a sized box instance.
        const SizedBox(width: 12),

        // Profile picture that navigates to settings.
        GestureDetector(
          onTap: onSettingsTap,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.surface,
            backgroundImage: profileImageUrl != null
                ? NetworkImage(profileImageUrl!)
                : null,
            child: profileImageUrl == null
                ? Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            )
                : null,
          ),
        ),

        /// Creates a sized box instance.
        const SizedBox(width: 12),

        /// Creates a text instance.
        Text(
          'Foodopia',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courgette',
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // ACTIONS
  // =========================================================================

  /// Handles the build actions operation.
  List<Widget> _buildActions(BuildContext context) {
    // Admin has only notifications.
    if (isAdmin) {
      return [
        _UnreadNotificationButton(
          isAdmin: true,
          color: Theme.of(context).colorScheme.onPrimary,
          onPressed: onNotificationsTap,
        ),
      ];
    }

    // User has statistics and notifications.
    return [
      /// Creates a icon button instance.
      IconButton(
        icon: const Icon(Icons.bar_chart),
        color: Theme.of(context).colorScheme.onPrimary,
        onPressed: onStatisticsTap,
        tooltip: 'Statistics',
      ),

      /// Creates a icon button instance.
      _UnreadNotificationButton(
        isAdmin: false,
        color: Theme.of(context).colorScheme.onPrimary,
        onPressed: onNotificationsTap,
      ),
    ];
  }

  /// Handles the preferred size operation.
  @override
  Size get preferredSize => const Size.fromHeight(56);
}

// =========================================================================
// UNREAD NOTIFICATION BUTTON
// =========================================================================

/// Notification button with unread indicator.
class _UnreadNotificationButton extends StatelessWidget {
  /// Whether the user is an admin.
  final bool isAdmin;

  /// Color of the icon.
  final Color color;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Creates a new unread notification button instance.
  const _UnreadNotificationButton({
    required this.isAdmin,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Get the current user ID.
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Show simple button if no user.
    if (uid.isEmpty) {
      return IconButton(
        icon: const Icon(Icons.notifications),
        color: color,
        onPressed: onPressed,
        tooltip: 'Notifications',
      );
    }

    // Stream of unread notifications.
    final unreadStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: unreadStream,
      builder: (context, snapshot) {
        // Check if there are any unread notifications.
        final hasUnread = (snapshot.data?.docs ?? const []).any((doc) {
          // Get the notification type.
          final type = doc.data()['type']?.toString();

          // Admin notification types.
          const adminTypes = {
            'newUser',
            'systemRating',
            'newHelpTicket',
            'newCategory',
          };

          // Filter based on user role.
          return isAdmin
              ? adminTypes.contains(type)
              : !adminTypes.contains(type);
        });

        // Return button with unread indicator.
        return IconButton(
          color: color,
          onPressed: onPressed,
          tooltip: 'Notifications',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications),
              if (hasUnread)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
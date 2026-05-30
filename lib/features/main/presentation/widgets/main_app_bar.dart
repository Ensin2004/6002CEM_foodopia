import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/custom_app_bar.dart';

/// Defines behavior for main app bar.
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isAdmin;
  final String? profileImageUrl;
  final VoidCallback onSettingsTap;
  final VoidCallback? onStatisticsTap;
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

  /// Handles the build title operation.
  Widget _buildTitle(BuildContext context) {
    /// Handles the row operation.
    return Row(
      children: [
        /// Creates a sized box instance.
        const SizedBox(width: 12),
        // Profile picture that navigates to settings
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

  /// Handles the build actions operation.
  List<Widget> _buildActions(BuildContext context) {
    // Admin has no actions
    if (isAdmin) return [];

    // User has statistics and notifications
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
        color: Theme.of(context).colorScheme.onPrimary,
        onPressed: onNotificationsTap,
      ),
    ];
  }

  /// Handles the preferred size operation.
  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _UnreadNotificationButton extends StatelessWidget {
  final Color color;
  final VoidCallback? onPressed;

  const _UnreadNotificationButton({required this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return IconButton(
        icon: const Icon(Icons.notifications),
        color: color,
        onPressed: onPressed,
        tooltip: 'Notifications',
      );
    }

    final unreadStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .limit(1)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: unreadStream,
      builder: (context, snapshot) {
        final hasUnread = (snapshot.data?.docs.length ?? 0) > 0;
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

import 'package:flutter/material.dart';

/// Defines behavior for main app bar.
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isAdmin;
  final String? profileImageUrl;
  final VoidCallback onSettingsTap;
  final VoidCallback? onFavoritesTap;
  final VoidCallback? onNotificationsTap;

  /// Creates a main app bar instance.
  const MainAppBar({
    super.key,
    required this.isAdmin,
    required this.profileImageUrl,
    required this.onSettingsTap,
    this.onFavoritesTap,
    this.onNotificationsTap,
  });

  /// Builds the widget tree for this component.
  @override
  Widget build(BuildContext context) {
    /// Handles the app bar operation.
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 56,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: _buildTitle(context),
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

    // User has favorites and notifications
    return [
      /// Creates a icon button instance.
      IconButton(
        icon: const Icon(Icons.favorite),
        color: Theme.of(context).colorScheme.onPrimary,
        onPressed: onFavoritesTap,
        tooltip: 'Favorites',
      ),

      /// Creates a icon button instance.
      IconButton(
        icon: const Icon(Icons.notifications),
        color: Theme.of(context).colorScheme.onPrimary,
        onPressed: onNotificationsTap,
        tooltip: 'Notifications',
      ),
    ];
  }

  /// Handles the preferred size operation.
  @override
  Size get preferredSize => const Size.fromHeight(56);
}

import 'package:flutter/material.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isAdmin;
  final String? profileImageUrl;
  final VoidCallback onSettingsTap;
  final VoidCallback? onFavoritesTap;
  final VoidCallback? onNotificationsTap;

  const MainAppBar({
    super.key,
    required this.isAdmin,
    required this.profileImageUrl,
    required this.onSettingsTap,
    this.onFavoritesTap,
    this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      toolbarHeight: 56,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: _buildTitle(context),
      actions: _buildActions(context),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),
        // Profile picture that navigates to settings
        GestureDetector(
          onTap: onSettingsTap,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.background,
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
        const SizedBox(width: 12),
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

  List<Widget> _buildActions(BuildContext context) {
    // Admin has no actions
    if (isAdmin) return [];

    // User has favorites and notifications
    return [
      IconButton(
        icon: const Icon(Icons.favorite),
        color: Theme.of(context).colorScheme.onPrimary,
        onPressed: onFavoritesTap,
        tooltip: 'Favorites',
      ),
      IconButton(
        icon: const Icon(Icons.notifications),
        color: Theme.of(context).colorScheme.onPrimary,
        onPressed: onNotificationsTap,
        tooltip: 'Notifications',
      ),
    ];
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
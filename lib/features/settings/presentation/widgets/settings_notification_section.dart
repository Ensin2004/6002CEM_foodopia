import 'package:flutter/material.dart';

import '../../../notifications/domain/entities/notification_preference.dart';
import '../viewmodel/settings_viewmodel.dart';

/// Notification preferences section for the settings page.
class SettingsNotificationSection extends StatelessWidget {
  /// Settings state source.
  final SettingsViewModel viewModel;

  /// Creates the notification settings section.
  const SettingsNotificationSection({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ..._notificationPreferenceTiles(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Divider(height: 1, color: Colors.grey[300], thickness: 2),
        ),
      ],
    );
  }

  /// Builds grouped notification rows.
  List<Widget> _notificationPreferenceTiles() {
    if (viewModel.isAdmin) {
      return viewModel.notificationPreferences
          .map(_notificationTile)
          .toList(growable: false);
    }

    /* User notifications are grouped by purpose.
       Unknown IDs stay visible under the Other group. */
    const groupedIds = <String, List<String>>{
      'Follower Notification': [
        'new_follower_notification',
        'new_recipe_notification',
      ],
      'Community Notification': [
        'new_rating_notification',
        'new_comment_notification',
        'new_like_notification',
        'new_reply_notification',
      ],
      'System Notification': ['help_center_reply_notification'],
    };

    final byId = {
      for (final item in viewModel.notificationPreferences) item.id: item,
    };
    final widgets = <Widget>[];

    for (final entry in groupedIds.entries) {
      final items = entry.value
          .map((id) => byId[id])
          .whereType<NotificationPreference>()
          .toList(growable: false);
      if (items.isEmpty) continue;

      widgets.add(_NotificationCategoryHeader(title: entry.key));
      widgets.addAll(items.map(_notificationTile));
    }

    final groupedIdSet = groupedIds.values.expand((ids) => ids).toSet();
    final remaining = viewModel.notificationPreferences
        .where((item) => !groupedIdSet.contains(item.id))
        .toList(growable: false);
    if (remaining.isNotEmpty) {
      widgets.add(const _NotificationCategoryHeader(title: 'Other'));
      widgets.addAll(remaining.map(_notificationTile));
    }

    return widgets;
  }

  /// Builds one notification switch row.
  Widget _notificationTile(NotificationPreference item) {
    return _NotificationPreferenceTile(
      icon: _iconForNotification(item),
      title: item.title,
      description: item.description,
      value: item.enabled,
      onChanged: (value) => viewModel.toggleNotification(item.id, value),
    );
  }

  /// Selects the leading icon for a notification type.
  IconData _iconForNotification(NotificationPreference preference) {
    switch (preference.id) {
      case 'new_follower_notification':
        return Icons.group_add_outlined;
      case 'new_rating_notification':
        return Icons.info_outline;
      case 'new_comment_notification':
        return Icons.comment_outlined;
      case 'new_recipe_notification':
        return Icons.restaurant_menu_outlined;
      case 'new_reply_notification':
        return Icons.reply_outlined;
      case 'new_like_notification':
        return Icons.favorite_border;
      case 'new_user_notification':
        return Icons.person_add_alt_1_outlined;
      case 'system_rating_notification':
        return Icons.star_rate_outlined;
      case 'new_help_ticket_notification':
        return Icons.support_agent_outlined;
      case 'new_category_notification':
        return Icons.category_outlined;
      case 'help_center_reply_notification':
        return Icons.mark_chat_read_outlined;
      default:
        return Icons.notifications_none;
    }
  }
}

/// Category title above related notification switches.
class _NotificationCategoryHeader extends StatelessWidget {
  /// Header text.
  final String title;

  /// Creates a category header.
  const _NotificationCategoryHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Switch row for a single notification preference.
class _NotificationPreferenceTile extends StatelessWidget {
  /// Leading icon.
  final IconData icon;

  /// Preference title.
  final String title;

  /// Preference description.
  final String description;

  /// Switch value.
  final bool value;

  /// Switch callback.
  final ValueChanged<bool> onChanged;

  /// Creates a notification preference tile.
  const _NotificationPreferenceTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: const VisualDensity(vertical: -2),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.2),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).colorScheme.primary,
      secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}

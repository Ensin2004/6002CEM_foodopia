import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_notification.dart';

/// Shows one notification row with an icon, unread marker, message preview
/// and compact time label for the notification inbox.
class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isUnread = !notification.isRead;

    return Material(
      color: isUnread ? const Color(0xFFF7F3FF) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      _iconFor(notification.type),
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    if (isUnread)
                      const Positioned(
                        left: 9,
                        bottom: -7,
                        child: _UnreadDot(),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimeAgo(notification.createdAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Selects the visual icon that best matches the notification category
  IconData _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.newFollower:
        return Icons.group_add_outlined;
      case AppNotificationType.newRating:
        return Icons.info_outline;
      case AppNotificationType.newComment:
        return Icons.chat_bubble_outline;
      case AppNotificationType.newRecipe:
        return Icons.restaurant_menu_outlined;
      case AppNotificationType.newReply:
        return Icons.reply_outlined;
      case AppNotificationType.newLike:
        return Icons.favorite_border;
      case AppNotificationType.newUser:
        return Icons.person_add_alt_1_outlined;
      case AppNotificationType.systemRating:
        return Icons.star_rate_outlined;
      case AppNotificationType.newHelpTicket:
        return Icons.support_agent_outlined;
      case AppNotificationType.newCategory:
        return Icons.category_outlined;
      case AppNotificationType.recipeReview:
        return Icons.rate_review_outlined;
      case AppNotificationType.recipeHidden:
        return Icons.visibility_off_outlined;
      case AppNotificationType.helpReply:
        return Icons.mark_chat_read_outlined;
      case AppNotificationType.planReminder:
        return Icons.schedule_outlined;
    }
  }

  /// Formats notification creation time into a short inbox-friendly label.
  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes} m';
    if (difference.inDays < 1) return '${difference.inHours} hr';
    if (difference.inDays < 7) return '${difference.inDays} d';
    return DateFormat('d MMM').format(dateTime);
  }
}

/// Small status dot displayed below the icon for unread notifications.
class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
      ),
    );
  }
}

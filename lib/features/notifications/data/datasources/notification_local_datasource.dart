import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/services/shared_prefs_manager.dart';
import '../models/app_notification_model.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preference.dart';

class NotificationLocalDataSource {
  static const String _notificationsKey = 'notifications_items';
  static const String _pendingNotificationsKey = 'pending_notifications_items';
  static const int _planReminderNativeId = 6002001;
  static const MethodChannel _channel = MethodChannel('foodopia/notifications');

  Future<List<AppNotificationModel>> getNotifications() async {
    await _moveDuePendingNotifications();

    final rawItems = SharedPrefsManager.instance.getStringList(
      _notificationsKey,
    );
    if (rawItems == null) return [];

    return rawItems
        .map((item) => AppNotificationModel.fromJson(jsonDecode(item)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<NotificationPreference>> getPreferences() async {
    return const [
          NotificationPreference(
            id: 'new_follower_notification',
            title: 'New Follower Notification',
            description: 'Get a notification for new follower',
            enabled: false,
          ),
          NotificationPreference(
            id: 'new_rating_notification',
            title: 'New Rating Notification',
            description:
                'Receive a notification when your Recipe is being rated by user',
            enabled: false,
          ),
          NotificationPreference(
            id: 'new_comment_notification',
            title: 'New Comment Notification',
            description: 'Receive a notification when your recipe has comment',
            enabled: false,
          ),
          NotificationPreference(
            id: 'new_recipe_notification',
            title: 'New Recipe Notification',
            description: 'Receive a notification when followed creator posts',
            enabled: false,
          ),
          NotificationPreference(
            id: 'new_reply_notification',
            title: 'New Reply Notification',
            description: 'Receive a notification when someone replies you',
            enabled: false,
          ),
          NotificationPreference(
            id: 'new_like_notification',
            title: 'New Like Notification',
            description:
                'Receive a notification when someone likes your comment',
            enabled: false,
          ),
        ]
        .map(
          (item) => item.copyWith(
            enabled: SharedPrefsManager.isNotificationTypeEnabled(item.id),
          ),
        )
        .toList();
  }

  Future<void> saveNotifications(List<AppNotification> notifications) async {
    final rawItems = notifications
        .map(
          (item) => jsonEncode(AppNotificationModel.fromEntity(item).toJson()),
        )
        .toList();
    await SharedPrefsManager.instance.setStringList(
      _notificationsKey,
      rawItems,
    );
  }

  Future<void> savePendingNotifications(
    List<AppNotification> notifications,
  ) async {
    final rawItems = notifications
        .map(
          (item) => jsonEncode(AppNotificationModel.fromEntity(item).toJson()),
        )
        .toList();
    await SharedPrefsManager.instance.setStringList(
      _pendingNotificationsKey,
      rawItems,
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final notifications = await getNotifications();
    AppNotificationModel? notification;
    for (final item in notifications) {
      if (item.id == notificationId) {
        notification = item;
        break;
      }
    }
    await _cancelNativeNotification(notification?.nativeNotificationId);
    await _cancelAllNativeNotifications();
    await saveNotifications(
      notifications
          .map(
            (item) =>
                item.id == notificationId ? item.copyWith(isRead: true) : item,
          )
          .toList(),
    );
  }

  Future<void> markAllAsRead() async {
    final notifications = await getNotifications();
    await _cancelAllNativeNotifications();
    await saveNotifications(
      notifications.map((item) => item.copyWith(isRead: true)).toList(),
    );
  }

  Future<void> updatePreference({
    required String preferenceId,
    required bool enabled,
  }) async {
    await SharedPrefsManager.setNotificationTypeEnabled(preferenceId, enabled);
    await SharedPrefsManager.setNotificationEnabled(
      (await getPreferences()).any((item) => item.enabled),
    );
  }

  Future<void> schedulePlanReminder(DateTime scheduledAt) async {
    const nativeNotificationId = _planReminderNativeId;

    await _channel.invokeMethod<bool>('requestPermission');
    await _channel.invokeMethod<void>('scheduleNotification', {
      'id': nativeNotificationId,
      'notificationKey': 'read_$nativeNotificationId',
      'title': 'Plan your meal Reminder',
      'message': 'You forget to plan your meal today!',
      'scheduledAt': scheduledAt.millisecondsSinceEpoch,
    });

    await savePendingNotifications([
      AppNotificationModel(
        id: 'plan_$nativeNotificationId',
        type: AppNotificationType.planReminder,
        title: 'Plan your meal Reminder',
        message: 'You forget to plan your meal today!',
        createdAt: scheduledAt,
        nativeNotificationId: nativeNotificationId,
      ),
    ]);
  }

  Future<void> _moveDuePendingNotifications() async {
    final rawPending = SharedPrefsManager.instance.getStringList(
      _pendingNotificationsKey,
    );
    if (rawPending == null || rawPending.isEmpty) return;

    final now = DateTime.now();
    final pending = rawPending
        .map((item) => AppNotificationModel.fromJson(jsonDecode(item)))
        .toList();
    final due = pending
        .where((item) => !item.createdAt.isAfter(now))
        .toList(growable: false);
    final notDue = pending
        .where((item) => item.createdAt.isAfter(now))
        .toList(growable: false);

    if (due.isEmpty) return;

    final existing = SharedPrefsManager.instance.getStringList(
      _notificationsKey,
    );
    final notifications = existing == null
        ? <AppNotificationModel>[]
        : existing
              .map((item) => AppNotificationModel.fromJson(jsonDecode(item)))
              .toList();
    final existingIds = notifications.map((item) => item.id).toSet();
    final newDue = due
        .where((item) => !existingIds.contains(item.id))
        .toList(growable: false);

    await saveNotifications([...newDue, ...notifications]);
    await savePendingNotifications(notDue);
  }

  Future<void> _cancelNativeNotification(int? nativeNotificationId) async {
    if (nativeNotificationId == null) return;
    try {
      await _channel.invokeMethod<void>('cancelNotification', {
        'id': nativeNotificationId,
        'notificationKey': 'read_$nativeNotificationId',
      });
    } on PlatformException {
      // Reading the in-app item should not fail just because Android cannot
      // cancel the OS notification, especially during hot restart/debug runs.
    } on MissingPluginException {
      // Allows the feature to keep working on non-Android platforms.
    }
  }

  Future<void> _cancelAllNativeNotifications() async {
    try {
      await _channel.invokeMethod<void>('cancelAllNotifications');
    } on PlatformException {
      // Keep local read state as the source of truth if Android cancel fails.
    } on MissingPluginException {
      // Allows the feature to keep working on non-Android platforms.
    }
  }
}

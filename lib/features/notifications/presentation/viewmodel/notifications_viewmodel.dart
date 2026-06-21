import 'package:flutter/foundation.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/usecases/get_notification_preferences_usecase.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_as_read_usecase.dart';
import '../../domain/usecases/mark_notification_as_read_usecase.dart';
import '../../domain/usecases/schedule_plan_reminder_usecase.dart';
import '../../domain/usecases/update_notification_preference_usecase.dart';

// View model for the notification page.
// It loads notifications/settings, keeps loading and error state, and asks the
// use cases to mark notifications as read or schedule reminders.
class NotificationsViewModel extends ChangeNotifier {
  final GetNotificationsUseCase _getNotificationsUseCase;
  final GetNotificationPreferencesUseCase _getPreferencesUseCase;
  final MarkNotificationAsReadUseCase _markAsReadUseCase;
  final MarkAllNotificationsAsReadUseCase _markAllAsReadUseCase;
  final UpdateNotificationPreferenceUseCase _updatePreferenceUseCase;
  final SchedulePlanReminderUseCase _schedulePlanReminderUseCase;

  NotificationsViewModel({
    required GetNotificationsUseCase getNotificationsUseCase,
    required GetNotificationPreferencesUseCase getPreferencesUseCase,
    required MarkNotificationAsReadUseCase markAsReadUseCase,
    required MarkAllNotificationsAsReadUseCase markAllAsReadUseCase,
    required UpdateNotificationPreferenceUseCase updatePreferenceUseCase,
    required SchedulePlanReminderUseCase schedulePlanReminderUseCase,
  }) : _getNotificationsUseCase = getNotificationsUseCase,
       _getPreferencesUseCase = getPreferencesUseCase,
       _markAsReadUseCase = markAsReadUseCase,
       _markAllAsReadUseCase = markAllAsReadUseCase,
       _updatePreferenceUseCase = updatePreferenceUseCase,
       _schedulePlanReminderUseCase = schedulePlanReminderUseCase {
    load();
  }

  List<AppNotification> _notifications = [];
  List<NotificationPreference> _preferences = [];
  bool _isLoading = false;
  bool _isScheduling = false;
  String? _errorMessage;
  bool _isDisposed = false;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<NotificationPreference> get preferences =>
      List.unmodifiable(_preferences);
  bool get isLoading => _isLoading;
  bool get isScheduling => _isScheduling;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    // Load both notification items and preference switches for the screen.
    // The view model does not know whether the data came from Firestore or
    // local storage; that decision stays in the repository.
    _setLoading(true);
    final notificationsResult = await _getNotificationsUseCase.execute();
    final preferencesResult = await _getPreferencesUseCase.execute();

    notificationsResult.fold(
      (failure) => _errorMessage = failure.message,
      (items) => _notifications = items,
    );
    preferencesResult.fold(
      (failure) => _errorMessage = failure.message,
      (items) => _preferences = items,
    );
    _setLoading(false);
  }

  Future<void> markAsRead(String notificationId) async {
    // Mark one notification as read, then update the local UI list to match.
    final result = await _markAsReadUseCase.execute(notificationId);
    result.fold((failure) => _errorMessage = failure.message, (_) {
      _notifications = _notifications
          .map(
            (item) =>
                item.id == notificationId ? item.copyWith(isRead: true) : item,
          )
          .toList();
    });
    _notifyIfActive();
  }

  Future<void> markAllAsRead() async {
    // Mark every notification as read and refresh the UI state.
    final result = await _markAllAsReadUseCase.execute();
    result.fold((failure) => _errorMessage = failure.message, (_) {
      _notifications = _notifications
          .map((item) => item.copyWith(isRead: true))
          .toList();
    });
    _notifyIfActive();
  }

  Future<void> updatePreference(String preferenceId, bool enabled) async {
    // Save one setting change, then update the switch state on the screen.
    final result = await _updatePreferenceUseCase.execute(
      preferenceId: preferenceId,
      enabled: enabled,
    );
    result.fold((failure) => _errorMessage = failure.message, (_) {
      _preferences = _preferences
          .map(
            (item) => item.id == preferenceId
                ? item.copyWith(enabled: enabled)
                : item,
          )
          .toList();
    });
    _notifyIfActive();
  }

  Future<void> schedulePlanReminder(DateTime scheduledAt) async {
    // Schedule a device reminder for the chosen time, then reload so the new
    // pending/visible notification state is reflected on screen.
    _isScheduling = true;
    _notifyIfActive();

    final result = await _schedulePlanReminderUseCase.execute(scheduledAt);
    result.fold(
      (failure) => _errorMessage = failure.message,
      (_) => _errorMessage = null,
    );
    _isScheduling = false;
    await load();
  }

  void clearError() {
    _errorMessage = null;
    _notifyIfActive();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notifyIfActive();
  }

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

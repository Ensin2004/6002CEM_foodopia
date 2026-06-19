import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_notification.dart';
import '../entities/notification_preference.dart';

// Notification contract used by the domain and presentation layers.
// The UI calls these methods without needing to know whether the work happens
// in Firestore, SharedPreferences, or the native notification system.
abstract class NotificationRepository {
  Future<Either<Failure, List<AppNotification>>> getNotifications();

  Future<Either<Failure, List<NotificationPreference>>> getPreferences();

  Future<Either<Failure, void>> markAsRead(String notificationId);

  Future<Either<Failure, void>> markAllAsRead();

  Future<Either<Failure, void>> updatePreference({
    required String preferenceId,
    required bool enabled,
  });

  Future<Either<Failure, void>> schedulePlanReminder(DateTime scheduledAt);
}

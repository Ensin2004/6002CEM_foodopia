import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_datasource.dart';
import '../datasources/notification_remote_datasource.dart';

// Repository layer for notifications.
// It combines Firestore notifications with local reminders, updates both
// storage places when needed, and returns friendly failures to the UI.
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource localDataSource;
  final NotificationRemoteDataSource remoteDataSource;

  const NotificationRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications() async {
    try {
      // Local reminders and remote Firestore notifications are merged, then
      // sorted so the newest item appears first.
      final local = await localDataSource.getNotifications();
      final remote = await _safeRemoteNotifications();
      return Right(
        [...remote, ...local]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    } catch (_) {
      return Left(CacheFailure(message: 'Unable to load notifications'));
    }
  }

  @override
  Future<Either<Failure, List<NotificationPreference>>> getPreferences() async {
    try {
      // Firestore is the main source for preferences. After reading it, keep a
      // local copy so the settings screen still works offline.
      final remote = await remoteDataSource.getPreferences();
      for (final item in remote) {
        await localDataSource.updatePreference(
          preferenceId: item.id,
          enabled: item.enabled,
        );
      }
      return Right(remote);
    } catch (_) {
      try {
        return Right(await localDataSource.getPreferences());
      } catch (_) {
        return Left(
          CacheFailure(message: 'Unable to load notification settings'),
        );
      }
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      // Mark the local copy first for a quick UI update, then try to mark the
      // Firestore document too.
      await localDataSource.markAsRead(notificationId);
      await _safeRemoteMarkAsRead(notificationId);
      return const Right(null);
    } catch (_) {
      return Left(CacheFailure(message: 'Unable to update notification'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await localDataSource.markAllAsRead();
      await _safeRemoteMarkAllAsRead();
      return const Right(null);
    } catch (_) {
      return Left(CacheFailure(message: 'Unable to update notifications'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePreference({
    required String preferenceId,
    required bool enabled,
  }) async {
    try {
      // Save the user's notification choice locally and in Firestore.
      await localDataSource.updatePreference(
        preferenceId: preferenceId,
        enabled: enabled,
      );
      await remoteDataSource.updatePreference(
        preferenceId: preferenceId,
        enabled: enabled,
      );
      return const Right(null);
    } catch (_) {
      return Left(
        CacheFailure(message: 'Unable to update notification setting'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> schedulePlanReminder(
    DateTime scheduledAt,
  ) async {
    try {
      // Plan reminders are device notifications, so they are scheduled through
      // local/native storage instead of being written to Firestore.
      await localDataSource.schedulePlanReminder(scheduledAt);
      return const Right(null);
    } catch (_) {
      return Left(CacheFailure(message: 'Unable to schedule notification'));
    }
  }

  Future<List<AppNotification>> _safeRemoteNotifications() async {
    try {
      return await remoteDataSource.getNotifications();
    } catch (_) {
      // If Firestore fails, the app can still show local reminders.
      return [];
    }
  }

  Future<void> _safeRemoteMarkAsRead(String notificationId) async {
    try {
      await remoteDataSource.markAsRead(notificationId);
    } catch (_) {}
  }

  Future<void> _safeRemoteMarkAllAsRead() async {
    try {
      await remoteDataSource.markAllAsRead();
    } catch (_) {}
  }
}

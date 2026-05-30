import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_datasource.dart';
import '../datasources/notification_remote_datasource.dart';

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

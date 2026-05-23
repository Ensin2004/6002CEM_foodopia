import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preference.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource localDataSource;

  const NotificationRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications() async {
    try {
      return Right(await localDataSource.getNotifications());
    } catch (_) {
      return Left(CacheFailure(message: 'Unable to load notifications'));
    }
  }

  @override
  Future<Either<Failure, List<NotificationPreference>>> getPreferences() async {
    try {
      return Right(await localDataSource.getPreferences());
    } catch (_) {
      return Left(
        CacheFailure(message: 'Unable to load notification settings'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await localDataSource.markAsRead(notificationId);
      return const Right(null);
    } catch (_) {
      return Left(CacheFailure(message: 'Unable to update notification'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await localDataSource.markAllAsRead();
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
}

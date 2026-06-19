import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

// Use case for marking one notification as read.
class MarkNotificationAsReadUseCase {
  final NotificationRepository _repository;

  const MarkNotificationAsReadUseCase(this._repository);

  Future<Either<Failure, void>> execute(String notificationId) {
    return _repository.markAsRead(notificationId);
  }
}

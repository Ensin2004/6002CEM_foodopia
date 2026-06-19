import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

// Use case for marking every notification as read at once.
class MarkAllNotificationsAsReadUseCase {
  final NotificationRepository _repository;

  const MarkAllNotificationsAsReadUseCase(this._repository);

  Future<Either<Failure, void>> execute() {
    return _repository.markAllAsRead();
  }
}

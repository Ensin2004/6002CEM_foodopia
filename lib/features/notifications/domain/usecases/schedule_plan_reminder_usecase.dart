import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

// Use case for scheduling a meal-plan reminder notification on the device.
class SchedulePlanReminderUseCase {
  final NotificationRepository _repository;

  const SchedulePlanReminderUseCase(this._repository);

  Future<Either<Failure, void>> execute(DateTime scheduledAt) {
    return _repository.schedulePlanReminder(scheduledAt);
  }
}

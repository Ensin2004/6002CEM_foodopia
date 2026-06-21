import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/notification_preference.dart';
import '../repositories/notification_repository.dart';

// Use case for loading the user's notification on/off settings.
class GetNotificationPreferencesUseCase {
  final NotificationRepository _repository;

  const GetNotificationPreferencesUseCase(this._repository);

  Future<Either<Failure, List<NotificationPreference>>> execute() {
    return _repository.getPreferences();
  }
}

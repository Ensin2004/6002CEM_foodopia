import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

// Use case for saving one notification preference switch.
class UpdateNotificationPreferenceUseCase {
  final NotificationRepository _repository;

  const UpdateNotificationPreferenceUseCase(this._repository);

  Future<Either<Failure, void>> execute({
    required String preferenceId,
    required bool enabled,
  }) {
    return _repository.updatePreference(
      preferenceId: preferenceId,
      enabled: enabled,
    );
  }
}

// Declares repository contracts for settings.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/settings_item.dart';
import '../entities/settings_section.dart';

/// Defines behavior for settings repository.
abstract class SettingsRepository {
  /// Loads data for the get user settings operation.
  Future<Either<Failure, List<SettingsSection>>> getUserSettings();
  /// Loads data for the get admin settings operation.
  Future<Either<Failure, List<SettingsSection>>> getAdminSettings();
  /// Loads data for the get notification enabled operation.
  Future<Either<Failure, bool>> getNotificationEnabled();
  /// Handles the set notification enabled operation.
  Future<Either<Failure, void>> setNotificationEnabled(bool enabled);
}

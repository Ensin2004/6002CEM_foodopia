import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/settings_item.dart';
import '../entities/settings_section.dart';

abstract class SettingsRepository {
  Future<Either<Failure, List<SettingsSection>>> getUserSettings();
  Future<Either<Failure, List<SettingsSection>>> getAdminSettings();
  Future<Either<Failure, bool>> getNotificationEnabled();
  Future<Either<Failure, void>> setNotificationEnabled(bool enabled);
}
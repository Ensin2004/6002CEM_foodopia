import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_setup_preferences.dart';
import '../repositories/user_setup_repository.dart';

class GetUserSetupPreferencesUseCase {
  final UserSetupRepository repository;

  GetUserSetupPreferencesUseCase(this.repository);

  Future<Either<Failure, UserSetupPreferences>> execute(String uid) {
    return repository.getPreferences(uid);
  }
}

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_setup_preferences.dart';
import '../repositories/user_setup_repository.dart';

class SaveUserSetupPreferencesUseCase {
  final UserSetupRepository repository;

  SaveUserSetupPreferencesUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String uid,
    required UserSetupPreferences preferences,
  }) {
    return repository.savePreferences(uid: uid, preferences: preferences);
  }
}

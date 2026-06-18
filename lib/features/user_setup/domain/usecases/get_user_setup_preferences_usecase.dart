import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_setup_preferences.dart';
import '../repositories/user_setup_repository.dart';

/// Use case for retrieving user setup preferences.
/// Encapsulates the business logic for fetching user preferences.
class GetUserSetupPreferencesUseCase {
  /// Repository instance for data operations.
  final UserSetupRepository repository;

  /// Creates a new get user setup preferences use case instance.
  GetUserSetupPreferencesUseCase(this.repository);

  /// Executes the use case with the given user ID.
  ///
  /// [uid] is the user's unique identifier.
  /// Returns either a failure or the user's preferences on success.
  Future<Either<Failure, UserSetupPreferences>> execute(String uid) {
    // Delegate to repository to fetch preferences.
    return repository.getPreferences(uid);
  }
}